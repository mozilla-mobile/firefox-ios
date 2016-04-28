/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This code is loosely based on https://github.com/Antol/APAutocompleteTextField

import UIKit
import Shared

/// Delegate for the text field events. Since AutocompleteTextField owns the UITextFieldDelegate,
/// callers must use this instead.
protocol AutocompleteTextFieldDelegate: class {
    func autocompleteTextField(autocompleteTextField: AutocompleteTextField, didEnterText text: String)
    func autocompleteTextFieldShouldReturn(autocompleteTextField: AutocompleteTextField) -> Bool
    func autocompleteTextFieldShouldClear(autocompleteTextField: AutocompleteTextField) -> Bool
    func autocompleteTextFieldDidBeginEditing(autocompleteTextField: AutocompleteTextField)
}

struct AutocompleteTextFieldUX {
    static let HighlightColor = UIColor(rgb: 0xccdded)
}

class AutocompleteTextField: UITextField, UITextFieldDelegate {
    var autocompleteDelegate: AutocompleteTextFieldDelegate?

    private var completionActive = false
    private var canAutocomplete = true

    // This variable is a solution to get the right behavior for refocusing
    // the AutocompleteTextField. The initial transition into Overlay Mode 
    // doesn't involve the user interacting with AutocompleteTextField.
    // Thus, we update shouldApplyCompletion in touchesBegin() to reflect whether
    // the highlight is active and then the text field is updated accordingly
    // in touchesEnd() (eg. applyCompletion() is called or not)
    private var shouldApplyCompletion = false
    private var enteredText = ""
    private var previousSuggestion = ""
    private var notifyTextChanged: (() -> ())? = nil

    dynamic var highlightColor = AutocompleteTextFieldUX.HighlightColor {
        didSet {
            if let text = text, selectedTextRange = selectedTextRange {
                // If the text field is currently highlighted, make sure to update the color and ignore it if it's not highlighted
                let attributedString = NSMutableAttributedString(string: text)
                let selectedStart = offsetFromPosition(beginningOfDocument, toPosition: selectedTextRange.start)
                let selectedLength = offsetFromPosition(selectedTextRange.start, toPosition: selectedTextRange.end)
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

    private func commonInit() {
        super.delegate = self
        super.addTarget(self, action: #selector(AutocompleteTextField.SELtextDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        notifyTextChanged = debounce(0.1, action: {
            if self.editing {
                self.autocompleteDelegate?.autocompleteTextField(self, didEnterText: self.enteredText.stringByTrimmingLeadingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
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

        selectedTextRange = textRangeFromPosition(beginningOfDocument, toPosition: beginningOfDocument)
    }

    private func normalizeString(string: String) -> String {
        return string.lowercaseString.stringByTrimmingLeadingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }

    /// Commits the completion by setting the text and removing the highlight.
    private func applyCompletion() {
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
    private func removeCompletion() {
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
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
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

    private func removeCompletionIfRequiredForEnteredString(string: String) {
        // If user-entered text does not start with previous suggestion then remove the completion.

        let actualEnteredString = enteredText + string
        if !previousSuggestion.startsWith(normalizeString(actualEnteredString)) {
            removeCompletion()
        }
        enteredText = actualEnteredString
    }

    func setAutocompleteSuggestion(suggestion: String?) {
        // Setting the autocomplete suggestion during multi-stage input will break the session since the text
        // is not fully entered. If `markedTextRange` is nil, that means the multi-stage input is complete, so
        // it's safe to append the suggestion.
        if let suggestion = suggestion where editing && canAutocomplete && markedTextRange == nil {
            // Check that the length of the entered text is shorter than the length of the suggestion.
            // This ensures that completionActive is true only if there are remaining characters to
            // suggest (which will suppress the caret).
            if suggestion.startsWith(normalizeString(enteredText)) && normalizeString(enteredText).characters.count < suggestion.characters.count {
                let endingString = suggestion.substringFromIndex(suggestion.startIndex.advancedBy(normalizeString(enteredText).characters.count))
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

    func textFieldDidBeginEditing(textField: UITextField) {
        autocompleteDelegate?.autocompleteTextFieldDidBeginEditing(self)
    }

    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        applyCompletion()
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return autocompleteDelegate?.autocompleteTextFieldShouldReturn(self) ?? true
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        removeCompletion()
        return autocompleteDelegate?.autocompleteTextFieldShouldClear(self) ?? true
    }

    func SELtextDidChange(textField: UITextField) {
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

    override func caretRectForPosition(position: UITextPosition) -> CGRect {
        return completionActive ? CGRectZero : super.caretRectForPosition(position)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        shouldApplyCompletion = completionActive
        if !completionActive {
            super.touchesBegan(touches, withEvent: event)
        }
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !completionActive {
            super.touchesMoved(touches, withEvent: event)
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !shouldApplyCompletion {
            super.touchesEnded(touches, withEvent: event)
        } else {
            applyCompletion()

            // Set the current position to the end of the text.
            selectedTextRange = textRangeFromPosition(endOfDocument, toPosition: endOfDocument)

            shouldApplyCompletion = !shouldApplyCompletion
        }
    }
}