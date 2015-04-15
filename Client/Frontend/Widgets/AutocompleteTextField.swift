/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Delegate for the text field events. Since AutocompleteTextField owns the UITextFieldDelegate,
/// callers must use this instead.
protocol AutocompleteTextFieldDelegate: class {
    func autocompleteTextField(autocompleteTextField: AutocompleteTextField, didTextChange text: String)
    func autocompleteTextFieldShouldReturn(autocompleteTextField: AutocompleteTextField) -> Bool
    func autocompleteTextFieldShouldClear(autocompleteTextField: AutocompleteTextField) -> Bool
    func autocompleteTextFieldDidBeginEditing(autocompleteTextField: AutocompleteTextField)
    func autocompleteTextFieldDidEndEditing(autocompleteTextField: AutocompleteTextField)
}

private struct AutocompleteTextFieldUX {
    static let HighlightColor = UIColor(rgb: 0xccdded)
}

class AutocompleteTextField: UITextField, UITextFieldDelegate {
    weak var autocompleteDelegate: AutocompleteTextFieldDelegate?

    private var autocompleting = false
    private var acceptingSuggestions = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        super.delegate = self
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        super.delegate = self
    }

    private var enteredText: NSString = "" {
        didSet {
            autocompleteDelegate?.autocompleteTextField(self, didTextChange: enteredText as String)
        }
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString

        // If we're autocompleting, stretch the range to the end of the text.
        let range = autocompleting ? NSMakeRange(range.location, text.length - range.location) : range

        // Update the entered text if we're adding characters or we're not autocompleting.
        // Otherwise, we're going to clear the autocompletion, which means the entered text shouldn't change.
        if !string.isEmpty || !autocompleting {
            enteredText = text.stringByReplacingCharactersInRange(range, withString: string)
        }

        // TODO: short-circuit if no previous match and text is longer.
        // TODO: cache last autocomplete result to prevent unnecessary iterations.
        if !string.isEmpty {
            acceptingSuggestions = true

            // Do the replacement. We'll asynchronously set the autocompletion suggestion if needed.
            return true
        }

        if autocompleting {
            // Characters are being deleted, so clear the autocompletion, but don't change the text.
            clearAutocomplete()
            return false
        }

        // Characters are being deleted, and there's no autocompletion active, so go on.
        return true
    }

    func setAutocompleteSuggestion(suggestion: String?) {
        // We're not accepting suggestions, so ignore.
        if !acceptingSuggestions {
            return
        }

        // If there's no suggestion, clear the existing autocompletion and bail.
        if suggestion == nil {
            clearAutocomplete()
            return
        }

        // Create the attributed string with the autocompletion highlight.
        let attributedString = NSMutableAttributedString(string: suggestion!)
        attributedString.addAttribute(NSBackgroundColorAttributeName, value: AutocompleteTextFieldUX.HighlightColor, range: NSMakeRange(self.enteredText.length, count(suggestion!) - self.enteredText.length))
        attributedText = attributedString

        // Set the current position to the beginning of the highlighted text.
        let position = positionFromPosition(beginningOfDocument, offset: self.enteredText.length)
        selectedTextRange = textRangeFromPosition(position, toPosition: position)

        // Enable autocompletion mode as long as there are still suggested characters remaining.
        autocompleting = enteredText != suggestion
    }

    /// Finalize any highlighted text.
    private func finishAutocomplete() {
        if autocompleting {
            enteredText = attributedText?.string ?? ""
            clearAutocomplete()
        }
    }

    /// Clear any highlighted text and turn off the autocompleting flag.
    private func clearAutocomplete() {
        if autocompleting {
            attributedText = NSMutableAttributedString(string: enteredText as String)
            acceptingSuggestions = false
            autocompleting = false

            // Set the current position to the end of the text.
            selectedTextRange = textRangeFromPosition(endOfDocument, toPosition: endOfDocument)
        }
    }

    override func caretRectForPosition(position: UITextPosition!) -> CGRect {
        return autocompleting ? CGRectZero : super.caretRectForPosition(position)
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        finishAutocomplete()
        super.touchesEnded(touches, withEvent: event)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        finishAutocomplete()
        return autocompleteDelegate?.autocompleteTextFieldShouldReturn(self) ?? true
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        autocompleteDelegate?.autocompleteTextFieldDidBeginEditing(self)
    }

    func textFieldDidEndEditing(textField: UITextField) {
        finishAutocomplete()
        autocompleteDelegate?.autocompleteTextFieldDidEndEditing(self)
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        clearAutocomplete()
        return autocompleteDelegate?.autocompleteTextFieldShouldClear(self) ?? true
    }
}