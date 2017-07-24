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

    // This variable is a solution to get the right behavior for refocusing
    // the AutocompleteTextField. The initial transition into Overlay Mode 
    // doesn't involve the user interacting with AutocompleteTextField.
    // Thus, we update shouldApplyCompletion in touchesBegin() to reflect whether
    // the highlight is active and then the text field is updated accordingly
    // in touchesEnd() (eg. applyCompletion() is called or not)
    fileprivate var shouldApplyCompletion = false
    fileprivate var enteredText = ""
    fileprivate var previousSuggestion = ""
    fileprivate var notifyTextChanged: (() -> Void)?
    private var lastReplacement: String?

    dynamic var highlightColor = AutocompleteTextFieldUX.HighlightColor {
        didSet {
            if let text = text, let selectedTextRange = selectedTextRange {
                // If the text field is currently highlighted, make sure to update the color and ignore it if it's not highlighted
                let attributedString = NSMutableAttributedString(string: text)
                let selectedStart = offset(from: beginningOfDocument, to: selectedTextRange.start)
                let selectedLength = offset(from: selectedTextRange.start, to: selectedTextRange.end)
                attributedString.addAttribute(NSBackgroundColorAttributeName, value: highlightColor, range: NSRange(location: selectedStart, length: selectedLength))
                attributedText = attributedString
            }
        }
    }

    override var text: String? {
        didSet {
            applyCompletion()
            super.text = text
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
        super.addTarget(self, action: #selector(AutocompleteTextField.textDidChange(_:)), for: UIControlEvents.editingChanged)
        notifyTextChanged = debounce(0.1, action: {
            if self.isEditing {
                self.autocompleteDelegate?.autocompleteTextField(self, didEnterText: self.normalizeString(self.text ?? ""))
            }
        })
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: .init(rawValue: 0), action: #selector(self.handleKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: .init(rawValue: 0), action: #selector(self.handleKeyCommand(sender:)))
        ]
    }
    
    func handleKeyCommand(sender: UIKeyCommand) {
        switch sender.input {
        case UIKeyInputLeftArrow:
            if completionActive {
                applyCompletion()
                
                // Set the current position to the beginning of the text.
                selectedTextRange = textRange(from: beginningOfDocument, to: beginningOfDocument)
            } else if let range = selectedTextRange {
                if range.start == beginningOfDocument {
                    return
                }
                
                guard let cursorPosition = position(from: range.start, offset: -1) else {
                    return
                }
                
                selectedTextRange = textRange(from: cursorPosition, to: cursorPosition)
            }
            return
        case UIKeyInputRightArrow:
            if completionActive {
                applyCompletion()
                
                // Set the current position to the end of the text.
                selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
            } else if let range = selectedTextRange {
                if range.end == endOfDocument {
                    return
                }
                
                guard let cursorPosition = position(from: range.end, offset: 1) else {
                    return
                }

                selectedTextRange = textRange(from: cursorPosition, to: cursorPosition)
            }
            return
        default:
            return
        }
    }
    
    func highlightAll() {
        let text = self.text
        self.text = nil
        setAutocompleteSuggestion(text ?? "")
        selectedTextRange = textRange(from: beginningOfDocument, to: beginningOfDocument)
    }

    fileprivate func normalizeString(_ string: String) -> String {
        return string.lowercased().stringByTrimmingLeadingCharactersInSet(CharacterSet.whitespaces)
    }

    /// Commits the completion by setting the text and removing the highlight.
    fileprivate func applyCompletion() {
        guard completionActive else { return }

        completionActive = false
        // Clear the current completion, then set the text without the attributed style.
        // The attributed string must have at least one character to clear the current style.
        let text = self.text ?? ""
        attributedText = NSAttributedString(string: " ")
        self.text = text

        // Move the cursor to the end of the completion.
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }

    /// Removes the autocomplete-highlighted text from the field.
    fileprivate func removeCompletion() {
        guard completionActive else { return }

        applyCompletion()
        text = (text as NSString?)?.replacingOccurrences(of: previousSuggestion, with: "")
        previousSuggestion = ""
    }

    // `shouldChangeCharactersInRange` is called before the text changes, and textDidChange is called after.
    // Since the text has changed, remove the completion here, and textDidChange will fire the callback to
    // get the new autocompletion.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        lastReplacement = string
        return true
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        let text = self.text ?? ""

        if let suggestion = suggestion, isEditing && markedTextRange == nil {
            // Check that the length of the entered text is shorter than the length of the suggestion.
            // This ensures that completionActive is true only if there are remaining characters to
            // suggest (which will suppress the caret).
            if suggestion.startsWith(normalizeString(enteredText)) && normalizeString(enteredText).characters.count < suggestion.characters.count {
                let endingString = suggestion.substring(from: suggestion.characters.index(suggestion.startIndex, offsetBy: normalizeString(enteredText).characters.count))
                previousSuggestion = endingString
                let completedAndMarkedString = NSMutableAttributedString(string: enteredText + endingString)
                completedAndMarkedString.addAttribute(NSBackgroundColorAttributeName, value: highlightColor, range: NSRange(location: enteredText.characters.count, length: endingString.characters.count))
                attributedText = completedAndMarkedString
                completionActive = true
            }
        }
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

    func textDidChange(_ textField: UITextField) {
        removeCompletion()

        let isAtEnd = selectedTextRange?.start == endOfDocument
        enteredText = text ?? ""
        let isEmpty = lastReplacement?.isEmpty ?? true
        if !isEmpty, isAtEnd, markedTextRange == nil {
            notifyTextChanged?()
        }
    }

    override func deleteBackward() {
        lastReplacement = nil
        guard !completionActive else {
            // If we have an active completion, delete it without deleting any user-typed characters.
            removeCompletion()
            return
        }
        super.deleteBackward()
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        return completionActive ? CGRect.zero : super.caretRect(for: position)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        applyCompletion()
        super.touchesBegan(touches, with: event)
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
