// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// This code is loosely based on https://github.com/Antol/APAutocompleteTextField

import UIKit
import Shared
import Common

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
    // AutocompleteTextLabel represents the actual autocomplete text.
    // The textfields "text" property only contains the entered text, while this label holds the autocomplete text
    // This makes sure that the autocomplete doesnt mess with keyboard suggestions provided by third party keyboards.
    private var autocompleteTextLabel: UILabel?
    private var hideCursor = false

    private let copyShortcutKey = "c"
    private var isPrivateMode = false
    var theme: Theme?

    var isSelectionActive: Bool {
        return autocompleteTextLabel != nil
    }

    // This variable is a solution to get the right behavior for refocusing
    // the AutocompleteTextField. The initial transition into Overlay Mode
    // doesn't involve the user interacting with AutocompleteTextField.
    // Thus, we update shouldApplyCompletion in touchesBegin() to reflect whether
    // the highlight is active and then the text field is updated accordingly
    // in touchesEnd() (eg. applyCompletion() is called or not)
    private var notifyTextChanged: (() -> Void)?
    private var lastReplacement: String?

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

    private func commonInit() {
        super.delegate = self
        super.addTarget(self, action: #selector(AutocompleteTextField.textDidChange), for: .editingChanged)
        notifyTextChanged = debounce(0.1, action: {
            if self.isEditing {
                self.autocompleteDelegate?.autocompleteTextField(self, didEnterText: self.normalizeString(self.text ?? ""))
            }
        })

        font = UIFont.preferredFont(forTextStyle: .body)
        adjustsFontForContentSizeCategory = true
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        keyboardType = .webSearch
        autocorrectionType = .no
        autocapitalizationType = .none
        returnKeyType = .go
        clearButtonMode = .whileEditing
        textAlignment = .left
    }

    override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(input: copyShortcutKey, modifierFlags: .command, action: #selector(self.handleKeyCommand(sender:)))
        ]

        let arrowKeysCommands = [
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(self.handleKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(self.handleKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(self.handleKeyCommand(sender:))),
        ]

        // In iOS 15+, certain keys events are delivered to the text input or focus systems first, unless specified otherwise
        if #available(iOS 15, *) {
            arrowKeysCommands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        }

        return arrowKeysCommands + commands
    }

    @objc
    func handleKeyCommand(sender: UIKeyCommand) {
        guard let input = sender.input else { return }
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

    private func normalizeString(_ string: String) -> String {
        return string.lowercased().stringByTrimmingLeadingCharactersInSet(CharacterSet.whitespaces)
    }

    /// Commits the completion by setting the text and removing the highlight.
    private func applyCompletion() {
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
    @objc
    @discardableResult
    private func removeCompletion() -> Bool {
        let hasActiveCompletion = isSelectionActive
        autocompleteTextLabel?.removeFromSuperview()
        autocompleteTextLabel = nil
        return hasActiveCompletion
    }

    @objc
    private func clear() {
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

        autocompleteTextLabel?.removeFromSuperview()
        autocompleteTextLabel = nil

        if let theme {
            let color = isPrivateMode ? theme.colors.layerAccentPrivateNonOpaque : theme.colors.layerAccentNonOpaque
            autocompleteText.addAttribute(NSAttributedString.Key.backgroundColor,
                                          value: color,
                                          range: NSRange(location: 0, length: suggestionText.count))
            autocompleteTextLabel = createAutocompleteLabelWith(autocompleteText)
        }

        if let label = autocompleteTextLabel {
            addSubview(label)
            // Only call forceResetCursor() if `hideCursor` changes.
            // Because forceResetCursor() auto accept iOS user's text replacement
            // (e.g. mu->μ) which makes user unable to type "mu".
            if !hideCursor {
                hideCursor = true
                forceResetCursor()
            }
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
        frame.origin.x = (enteredTextSize?.width.rounded() ?? 0) + textRect(forBounds: bounds).origin.x
        frame.size.width = self.frame.size.width - clearButtonRect(forBounds: self.frame).size.width - frame.origin.x
        frame.size.height = self.frame.size.height
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

    @objc
    func textDidChange(_ textField: UITextField) {
        hideCursor = autocompleteTextLabel != nil
        removeCompletion()

        let isKeyboardReplacingText = lastReplacement != nil
        if isKeyboardReplacingText, markedTextRange == nil {
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

    func menuHelperPasteAndGo() {
        autocompleteDelegate?.autocompletePasteAndGo(self)
    }
}

extension AutocompleteTextField: ThemeApplicable, PrivateModeUI {
    func applyUIMode(isPrivate: Bool, theme: Theme) {
        isPrivateMode = isPrivate

        if autocompleteTextLabel?.attributedText != nil {
            let autocompleteText = NSMutableAttributedString(string: self.autocompleteTextLabel?.attributedText?.string ?? "")
            let color = isPrivateMode ? theme.colors.layerAccentPrivateNonOpaque : theme.colors.layerAccentNonOpaque
            autocompleteText.addAttribute(NSAttributedString.Key.backgroundColor,
                                          value: color,
                                          range: NSRange(location: 0, length: autocompleteText.length))
            self.autocompleteTextLabel?.attributedText = autocompleteText
        }

        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        self.theme = theme
        let attributes = [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
        attributedPlaceholder = NSAttributedString(string: .TabLocationURLPlaceholder,
                                                   attributes: attributes)

        backgroundColor = theme.colors.layer3
        textColor = theme.colors.textPrimary
        tintColor = theme.colors.actionPrimary

        // Only refresh if an autocomplete label is presented to the user
        if autocompleteTextLabel?.attributedText != nil {
            autocompleteTextLabel?.backgroundColor = theme.colors.layer3
            autocompleteTextLabel?.textColor = theme.colors.textPrimary
        }
    }
}
