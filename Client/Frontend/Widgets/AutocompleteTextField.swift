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

private struct AutocompleteTextFieldUX {
    static let HighlightColor = UIColor(rgb: 0xccdded)
}

class AutocompleteTextField: UITextField, UITextFieldDelegate {
    var autocompleteDelegate: AutocompleteTextFieldDelegate?

    private var completionActive = false
    private var canAutocomplete = true
    private var enteredTextLength = 0
    private var notifyTextChanged: (() -> ())? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        super.delegate = self
        notifyTextChanged = debounce(0.1, {
            if self.editing {
                self.autocompleteDelegate?.autocompleteTextField(self, didEnterText: self.text)
            }
        })
    }

    func highlightAll() {
        if !text.isEmpty {
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(NSBackgroundColorAttributeName, value: AutocompleteTextFieldUX.HighlightColor, range: NSMakeRange(0, count(text)))
            attributedText = attributedString

            enteredTextLength = 0
            completionActive = true
        }

        selectedTextRange = textRangeFromPosition(beginningOfDocument, toPosition: beginningOfDocument)
    }

    /// Commits the completion by setting the text and removing the highlight.
    private func applyCompletion() {
        if completionActive {
            self.attributedText = NSAttributedString(string: text)
            completionActive = false
            // This is required to notify the SearchLoader that some text has changed and previous
            // cached query will get updated.
            notifyTextChanged?()
        }
    }

    /// Removes the autocomplete-highlighted text from the field.
    private func removeCompletion() {
        if completionActive {
            let enteredText = text.substringToIndex(advance(text.startIndex, enteredTextLength, text.endIndex))

            // Workaround for stuck highlight bug.
            if enteredTextLength == 0 {
                attributedText = NSAttributedString(string: " ")
            }

            attributedText = NSAttributedString(string: enteredText)
            completionActive = false
        }
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if completionActive && string.isEmpty {
            // Characters are being deleted, so clear the autocompletion, but don't change the text.
            removeCompletion()
            return false
        }

        return true
    }

    func setAutocompleteSuggestion(suggestion: String?) {
        if let suggestion = suggestion where editing && canAutocomplete {
            // Check that the length of the entered text is shorter than the length of the suggestion.
            // This ensures that completionActive is true only if there are remaining characters to
            // suggest (which will suppress the caret).
            if suggestion.startsWith(text) && count(text) < count(suggestion) {
                let endingString = suggestion.substringFromIndex(advance(suggestion.startIndex, count(self.text)))
                let completedAndMarkedString = NSMutableAttributedString(string: suggestion)
                completedAndMarkedString.addAttribute(NSBackgroundColorAttributeName, value: AutocompleteTextFieldUX.HighlightColor, range: NSMakeRange(enteredTextLength, count(endingString)))
                attributedText = completedAndMarkedString
                completionActive = true
            }
        }
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

    override func setMarkedText(markedText: String!, selectedRange: NSRange) {
        // Clear the autocompletion if any provisionally inserted text has been
        // entered (e.g., a partial composition from a Japanese keyboard).
        removeCompletion()
        super.setMarkedText(markedText, selectedRange: selectedRange)
    }

    override func insertText(text: String) {
        canAutocomplete = true
        removeCompletion()
        super.insertText(text)
        enteredTextLength = count(self.text)

        notifyTextChanged?()
    }

    override func deleteBackward() {
        canAutocomplete = false
        enteredTextLength = count(self.text)
        removeCompletion()
        super.deleteBackward()
        autocompleteDelegate?.autocompleteTextField(self, didEnterText: self.text)
    }

    override func caretRectForPosition(position: UITextPosition!) -> CGRect {
        return completionActive ? CGRectZero : super.caretRectForPosition(position)
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if !completionActive {
            super.touchesBegan(touches, withEvent: event)
        }
    }

    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        if !completionActive {
            super.touchesMoved(touches, withEvent: event)
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if !completionActive {
            super.touchesEnded(touches, withEvent: event)
        } else {
            applyCompletion()

            // Set the current position to the end of the text.
            selectedTextRange = textRangeFromPosition(endOfDocument, toPosition: endOfDocument)
        }
    }
}
