/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This code is loosely based on https://github.com/Antol/APAutocompleteTextField

import UIKit
import Shared

/// Delegate for the text field events. Since AutocompleteTextField owns the UITextFieldDelegate,
/// callers must use this instead.
protocol AutocompleteTextFieldDelegate: AnyObject {
    func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didEnterText text: String)
    func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool
    func autocompleteTextFieldShouldClear(_ autocompleteTextField: AutocompleteTextField) -> Bool
    func autocompleteTextFieldDidCancel(_ autocompleteTextField: AutocompleteTextField)
    func autocompletePasteAndGo(_ autocompleteTextField: AutocompleteTextField)
}

class AutocompleteTextField: UITextField, UITextFieldDelegate {
    var autocompleteDelegate: AutocompleteTextFieldDelegate?
    // AutocompleteTextLabel repersents the actual autocomplete text.
    // The textfields "text" property only contains the entered text, while this label holds the autocomplete text
    // This makes sure that the autocomplete doesnt mess with keyboard suggestions provided by third party keyboards.
    private var autocompleteTextLabel: UILabel?
    private var hideCursor: Bool = false

    private let copyShortcutKey = "c"

    var isSelectionActive: Bool {
        return autocompleteTextLabel != nil
    }

    // This variable is a solution to get the right behavior for refocusing
    // the AutocompleteTextField. The initial transition into Overlay Mode
    // doesn't involve the user interacting with AutocompleteTextField.
    // Thus, we update shouldApplyCompletion in touchesBegin() to reflect whether
    // the highlight is active and then the text field is updated accordingly
    // in touchesEnd() (eg. applyCompletion() is called or not)
    fileprivate var notifyTextChanged: (() -> Void)?
    private var lastReplacement: String?

    static var textSelectionColor = URLBarColor.TextSelectionHighlight(labelMode: UIColor(), textFieldMode: nil)

    override var text: String? {
        didSet {
            super.text = text
            self.textDidChange(self)
        }
    }

    override var accessibilityValue: String? {
        get {
            return (self.text ?? "") + (self.autocompleteTextLabel?.text ?? "")
        }
        set(value) {
            super.accessibilityValue = value
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
        super.addTarget(self, action: #selector(AutocompleteTextField.textDidChange), for: .editingChanged)
        notifyTextChanged = debounce(0.1, action: {
            if self.isEditing {
                self.autocompleteDelegate?.autocompleteTextField(self, didEnterText: self.normalizeString(self.text ?? ""))
            }
        })
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(self.handleKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(self.handleKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(self.handleKeyCommand(sender:))),
            UIKeyCommand(input: copyShortcutKey, modifierFlags: .command, action: #selector(self.handleKeyCommand(sender:)))
        ]
    }

    @objc func handleKeyCommand(sender: UIKeyCommand) {
        guard let input = sender.input else {
            return
        }
        switch input {
        case UIKeyCommand.inputLeftArrow:
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "autocomplete-left-arrow"])
            if isSelectionActive {
                applyCompletion()

                // Set the current position to the beginning of the text.
                selectedTextRange = textRange(from: beginningOfDocument, to: beginningOfDocument)
            } else if let range = selectedTextRange {
                if range.start == beginningOfDocument {
                    break
                }

                guard let cursorPosition = position(from: range.start, offset: -1) else {
                    break
                }

                selectedTextRange = textRange(from: cursorPosition, to: cursorPosition)
            }
        case UIKeyCommand.inputRightArrow:
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "autocomplete-right-arrow"])
            if isSelectionActive {
                applyCompletion()

                // Set the current position to the end of the text.
                selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
            } else if let range = selectedTextRange {
                if range.end == endOfDocument {
                    break
                }

                guard let cursorPosition = position(from: range.end, offset: 1) else {
                    break
                }

                selectedTextRange = textRange(from: cursorPosition, to: cursorPosition)
            }
        case UIKeyCommand.inputEscape:
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "autocomplete-cancel"])
            autocompleteDelegate?.autocompleteTextFieldDidCancel(self)
        case copyShortcutKey:
            if isSelectionActive {
                UIPasteboard.general.string = self.autocompleteTextLabel?.text
            } else {
                if let selectedTextRange = self.selectedTextRange {
                    UIPasteboard.general.string = self.text(in: selectedTextRange)
                }
            }
        default:
            break
        }
    }

    fileprivate func normalizeString(_ string: String) -> String {
        return string.lowercased().stringByTrimmingLeadingCharactersInSet(CharacterSet.whitespaces)
    }

    /// Commits the completion by setting the text and removing the highlight.
    fileprivate func applyCompletion() {

        // Clear the current completion, then set the text without the attributed style.
        let text = (self.text ?? "") + (self.autocompleteTextLabel?.text ?? "")
        let didRemoveCompletion = removeCompletion()
        self.text = text
        hideCursor = false
        // Move the cursor to the end of the completion.
        if didRemoveCompletion {
            selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        }
    }

    /// Removes the autocomplete-highlighted. Returns true if a completion was actually removed
    @objc @discardableResult fileprivate func removeCompletion() -> Bool {
        let hasActiveCompletion = isSelectionActive
        autocompleteTextLabel?.removeFromSuperview()
        autocompleteTextLabel = nil
        return hasActiveCompletion
    }

    @objc fileprivate func clear() {
        text = ""
        removeCompletion()
        autocompleteDelegate?.autocompleteTextField(self, didEnterText: "")
    }

    // `shouldChangeCharactersInRange` is called before the text changes, and textDidChange is called after.
    // Since the text has changed, remove the completion here, and textDidChange will fire the callback to
    // get the new autocompletion.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // This happens when you begin typing overtop the old highlighted
        // text immediately after focusing the text field. We need to trigger
        // a `didEnterText` that looks like a `clear()` so that the SearchLoader
        // can reset itself since it will only lookup results if the new text is
        // longer than the previous text.
        if lastReplacement == nil {
            autocompleteDelegate?.autocompleteTextField(self, didEnterText: "")
        }

        lastReplacement = string
        return true
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        let text = self.text ?? ""

        guard let suggestion = suggestion, isEditing && markedTextRange == nil else {
            hideCursor = false
            return
        }

        let normalized = normalizeString(text)
        guard suggestion.hasPrefix(normalized) && normalized.count < suggestion.count else {
            hideCursor = false
            return
        }

        let suggestionText = String(suggestion[suggestion.index(suggestion.startIndex, offsetBy: normalized.count)...])
        let autocompleteText = NSMutableAttributedString(string: suggestionText)

        let color = AutocompleteTextField.textSelectionColor.labelMode
        autocompleteText.addAttribute(NSAttributedString.Key.backgroundColor, value: color, range: NSRange(location: 0, length: suggestionText.count))

        autocompleteTextLabel?.removeFromSuperview() // should be nil. But just in case
        autocompleteTextLabel = createAutocompleteLabelWith(autocompleteText)
        if let l = autocompleteTextLabel {
            addSubview(l)
            hideCursor = true
            forceResetCursor()
        }
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        return hideCursor ? CGRect.zero : super.caretRect(for: position)
    }

    private func createAutocompleteLabelWith(_ autocompleteText: NSAttributedString) -> UILabel {
        let label = UILabel()
        var frame = self.bounds
        label.attributedText = autocompleteText
        label.font = self.font
        label.accessibilityIdentifier = "autocomplete"
        label.backgroundColor = self.backgroundColor
        label.textColor = self.textColor
        label.textAlignment = .left

        let enteredTextSize = self.attributedText?.boundingRect(with: self.frame.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        frame.origin.x = (enteredTextSize?.width.rounded() ?? 0)
        frame.size.width = self.frame.size.width - frame.origin.x
        frame.size.height = self.frame.size.height - 1
        label.frame = frame
        return label
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        applyCompletion()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyCompletion()
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

    func setTextWithoutSearching(_ text: String) {
        super.text = text
        hideCursor = autocompleteTextLabel != nil
        removeCompletion()
    }

   @objc func textDidChange(_ textField: UITextField) {
        hideCursor = autocompleteTextLabel != nil
        removeCompletion()

        let isAtEnd = selectedTextRange?.start == endOfDocument
        let isKeyboardReplacingText = lastReplacement != nil
        if isKeyboardReplacingText, isAtEnd, markedTextRange == nil {
            notifyTextChanged?()
        } else {
            hideCursor = false
        }
    }

    // Reset the cursor to the end of the text field.
    // This forces `caretRect(for position: UITextPosition)` to be called which will decide if we should show the cursor
    // This exists because ` caretRect(for position: UITextPosition)` is not called after we apply an autocompletion.
    private func forceResetCursor() {
        selectedTextRange = nil
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }

    override func deleteBackward() {
        lastReplacement = ""
        hideCursor = false
        if isSelectionActive {
            removeCompletion()
            forceResetCursor()
        } else {
            super.deleteBackward()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        applyCompletion()
        super.touchesBegan(touches, with: event)
    }
}

extension AutocompleteTextField: MenuHelperInterface {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == MenuHelper.SelectorPasteAndGo {
            return UIPasteboard.general.hasStrings
        }

        return super.canPerformAction(action, withSender: sender)
    }

    @objc func menuHelperPasteAndGo() {
        autocompleteDelegate?.autocompletePasteAndGo(self)
    }
}
