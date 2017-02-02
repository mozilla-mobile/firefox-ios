/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This code is loosely based on https://github.com/Antol/APAutocompleteTextField

import UIKit
import Shared

/// Delegate for the text field events. Since AutocompleteTextField owns the UITextFieldDelegate,
/// callers must use this instead.
protocol AutocompleteTextFieldDelegate: class {
    func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didEnterText text: String)
    func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool
    func autocompleteTextFieldShouldClear(_ autocompleteTextField: AutocompleteTextField) -> Bool
    func autocompleteTextFieldDidBeginEditing(_ autocompleteTextField: AutocompleteTextField)
}

struct AutocompleteTextFieldUX {
    static let HighlightColor = UIColor(rgb: 0xccdded)
}

class AutocompleteTextField: UITextField, UITextFieldDelegate {
    var autocompleteDelegate: AutocompleteTextFieldDelegate?

    fileprivate var completionActive = false
    fileprivate var canAutocomplete = true

    // This variable is a solution to get the right behavior for refocusing
    // the AutocompleteTextField. The initial transition into Overlay Mode 
    // doesn't involve the user interacting with AutocompleteTextField.
    // Thus, we update shouldApplyCompletion in touchesBegin() to reflect whether
    // the highlight is active and then the text field is updated accordingly
    // in touchesEnd() (eg. applyCompletion() is called or not)
    fileprivate var shouldApplyCompletion = false
    fileprivate var enteredText = ""
    fileprivate var previousSuggestion = ""
    fileprivate var notifyTextChanged: (() -> ())? = nil

    dynamic var highlightColor = AutocompleteTextFieldUX.HighlightColor {
        didSet {
            if let text = text, let selectedTextRange = selectedTextRange {
                // If the text field is currently highlighted, make sure to update the color and ignore it if it's not highlighted
                let attributedString = NSMutableAttributedString(string: text)
                let selectedStart = offset(from: beginningOfDocument, to: selectedTextRange.start)
                let selectedLength = offset(from: selectedTextRange.start, to: selectedTextRange.end)
                attributedString.addAttribute(NSBackgroundColorAttributeName, value: highlightColor, range: NSMakeRange(selectedStart, selectedLength))
                attributedText = attributedString
            }
        }
    }

    override var text: String? {
        didSet {
            // SELtextDidChange is not called when directly setting the text property, so fire it manually.
            SELtextDidChange(self)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    fileprivate func commonInit() {
        super.delegate = self
        super.addTarget(self, action: #selector(AutocompleteTextField.SELtextDidChange(_:)), for: UIControlEvents.editingChanged)
        notifyTextChanged = debounce(0.1, action: {
            if self.isEditing {
                self.autocompleteDelegate?.autocompleteTextField(self, didEnterText: self.enteredText.stringByTrimmingLeadingCharactersInSet(NSCharacterSet.whitespaces))
            }
        })
    }

    func highlightAll() {
        if let text = text {
            if !text.isEmpty {
                let attributedString = NSMutableAttributedString(string: text)
                attributedString.addAttribute(NSBackgroundColorAttributeName, value: highlightColor, range: NSMakeRange(0, (text).characters.count))
                attributedText = attributedString

                enteredText = ""
                completionActive = true
            }
        }

        selectedTextRange = textRange(from: beginningOfDocument, to: beginningOfDocument)
    }

    fileprivate func normalizeString(_ string: String) -> String {
        return string.lowercased().stringByTrimmingLeadingCharactersInSet(CharacterSet.whitespaces)
    }

    /// Commits the completion by setting the text and removing the highlight.
    fileprivate func applyCompletion() {
        if completionActive {
            if let text = text {
                self.attributedText = NSAttributedString(string: text)
                enteredText = text
            }
            completionActive = false
            previousSuggestion = ""

            // This is required to notify the SearchLoader that some text has changed and previous
            // cached query will get updated.
            notifyTextChanged?()
        }
    }

    /// Removes the autocomplete-highlighted text from the field.
    fileprivate func removeCompletion() {
        if completionActive {
            // Workaround for stuck highlight bug.
            if enteredText.characters.count == 0 {
                attributedText = NSAttributedString(string: " ")
            }

            attributedText = NSAttributedString(string: enteredText)
            completionActive = false
        }
    }

    // `shouldChangeCharactersInRange` is called before the text changes, and SELtextDidChange is called after.
    // Since the text has changed, remove the completion here, and SELtextDidChange will fire the callback to
    // get the new autocompletion.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Accept autocompletions if we're adding characters.
        canAutocomplete = !string.isEmpty

        if completionActive {
            if string.isEmpty {
                // Characters are being deleted, so clear the autocompletion, but don't change the text.
                removeCompletion()
                return false
            }
            removeCompletionIfRequiredForEnteredString(string)
        }
        return true
    }

    fileprivate func removeCompletionIfRequiredForEnteredString(_ string: String) {
        // If user-entered text does not start with previous suggestion then remove the completion.

        let actualEnteredString = enteredText + string
        // Detecting the keyboard type, and remove hightlight in "zh-Hans" and "ja-JP"
        if !previousSuggestion.startsWith(normalizeString(actualEnteredString)) ||
            UIApplication.shared.textInputMode?.primaryLanguage == "zh-Hans" ||
            UIApplication.shared.textInputMode?.primaryLanguage == "ja-JP" {
            removeCompletion()
        }
        enteredText = actualEnteredString
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        // Setting the autocomplete suggestion during multi-stage input will break the session since the text
        // is not fully entered. If `markedTextRange` is nil, that means the multi-stage input is complete, so
        // it's safe to append the suggestion.
        if let suggestion = suggestion, isEditing && canAutocomplete && markedTextRange == nil {
            // Check that the length of the entered text is shorter than the length of the suggestion.
            // This ensures that completionActive is true only if there are remaining characters to
            // suggest (which will suppress the caret).
            if suggestion.startsWith(normalizeString(enteredText)) && normalizeString(enteredText).characters.count < suggestion.characters.count {
                let endingString = suggestion.substring(from: suggestion.characters.index(suggestion.startIndex, offsetBy: normalizeString(enteredText).characters.count))
                let completedAndMarkedString = NSMutableAttributedString(string: enteredText + endingString)
                completedAndMarkedString.addAttribute(NSBackgroundColorAttributeName, value: highlightColor, range: NSMakeRange(enteredText.characters.count, endingString.characters.count))
                attributedText = completedAndMarkedString
                completionActive = true
                previousSuggestion = suggestion
                return
            }
        }
        removeCompletion()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        autocompleteDelegate?.autocompleteTextFieldDidBeginEditing(self)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        applyCompletion()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return autocompleteDelegate?.autocompleteTextFieldShouldReturn(self) ?? true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        removeCompletion()
        return autocompleteDelegate?.autocompleteTextFieldShouldClear(self) ?? true
    }

    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        // Clear the autocompletion if any provisionally inserted text has been
        // entered (e.g., a partial composition from a Japanese keyboard).
        removeCompletion()
        super.setMarkedText(markedText, selectedRange: selectedRange)
    }

    func SELtextDidChange(_ textField: UITextField) {
        if completionActive {
            // Immediately reuse the previous suggestion if it's still valid.
            setAutocompleteSuggestion(previousSuggestion)
        } else {
            // Updates entered text while completion is not active. If it is 
            // active, enteredText will already be updated from 
            // removeCompletionIfRequiredForEnteredString.
            enteredText = text ?? ""
        }
        notifyTextChanged?()
    }

    override func deleteBackward() {
        removeCompletion()
        super.deleteBackward()
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        return completionActive ? CGRect.zero : super.caretRect(for: position)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        shouldApplyCompletion = completionActive
        if !completionActive {
            super.touchesBegan(touches, with: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !completionActive {
            super.touchesMoved(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !shouldApplyCompletion {
            super.touchesEnded(touches, with: event)
        } else {
            applyCompletion()

            // Set the current position to the end of the text.
            selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)

            shouldApplyCompletion = !shouldApplyCompletion
        }
    }
}
