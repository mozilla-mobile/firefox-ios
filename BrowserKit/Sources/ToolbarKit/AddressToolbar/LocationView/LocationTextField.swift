// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Delegate for the text field events. Since LocationTextField owns the UITextFieldDelegate,
/// callers must use this instead.
@MainActor
protocol LocationTextFieldDelegate: AnyObject {
    func locationTextField(_ textField: LocationTextField, didEnterText text: String)
    func locationTextFieldShouldReturn(_ textField: LocationTextField) -> Bool
    func locationTextFieldShouldClear(_ textField: LocationTextField) -> Bool
    func locationTextFieldDidBeginEditing(_ textField: UITextField)
    func locationTextFieldDidEndEditing(_ textField: UITextField)
    func locationTextFieldNeedsSearchReset(_ textField: UITextField)
}

class LocationTextField: UITextField, UITextFieldDelegate, ThemeApplicable {
    private var tintedClearImage: UIImage?
    private var clearButtonTintColor: UIColor?

    weak var autocompleteDelegate: LocationTextFieldDelegate?

    // This variable is a solution to get the right behaviour for refocusing
    // the LocationTextField. The initial transition into Overlay Mode
    // doesn't involve the user interacting with LocationTextField.
    // Thus, we update shouldApplyCompletion in touchesBegin() to reflect whether
    // the highlight is active and then the text field is updated accordingly
    // in touchesEnd() (eg. applyCompletion() is called or not)
    private var notifyTextChanged: (() -> Void)?

    // The last string used as a replacement in shouldChangeCharactersInRange.
    private var lastReplacement: String?
    private var hideCursor = false
    private var isSettingMarkedText = false
    // Ecosia: When false, end-editing strips inline autocomplete without committing it
    // (keyboard drag-dismiss while scrolling suggestions).
    var commitsAutocompleteOnEndEditing = true
    var clearButton: UIButton? {
        return value(forKey: "_clearButton") as? UIButton
    }
    private let copyShortcutKey = "c"

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        super.addTarget(self, action: #selector(LocationTextField.textDidChange), for: .editingChanged)

        font = FXFontStyles.Regular.body.scaledFont()
        adjustsFontForContentSizeCategory = true
        clearButtonMode = .whileEditing
        keyboardType = .webSearch
        autocorrectionType = .no
        autocapitalizationType = .none
        returnKeyType = .go
        tintAdjustmentMode = .normal

        // Setting the content type to a field that is not related to AutoFill functionality
        // like email and password, should disable the Operating system to load those content,
        // hence having a faster keyboard start up the first time
        textContentType = .URL
        delegate = self

        // Disable dragging urls on iPhones because it conflicts with editing the text
        if UIDevice.current.userInterfaceIdiom != .pad {
            textDragInteraction?.isEnabled = false
        }

        notifyTextChanged = debounce(0.1,
                                     action: {
            if self.isEditing {
                self.autocompleteDelegate?.locationTextField(
                    self,
                    didEnterText: self.normalizeString(self.textWithoutSuggestion() ?? "")
                )
            }
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var accessibilityActionsSource: AccessibilityActionsSource?

    // Ecosia: User-typed text only (excludes inline autocomplete). Read by
    // `overlaySearchQuery` so Redux cannot lag behind the live field.
    var plainUserText: String {
        textWithoutSuggestion() ?? text ?? ""
    }

    // Ecosia: Write counterpart to `plainUserText`, for replacing the field's contents from
    // code — the suggestion list's "append" arrow. Drops any inline autocomplete first so the
    // appended query can't be spliced onto a stale completion, and parks the caret at the end
    // so typing continues from the appended text.
    func setPlainUserText(_ value: String) {
        removeCompletion()
        hideCursor = false
        text = value
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return accessibilityActionsSource?.accessibilityCustomActionsForView(self)
        }
        set {
            super.accessibilityCustomActions = newValue
        }
    }

    // MARK: - View setup
    override func layoutSubviews() {
        super.layoutSubviews()

        if tintedClearImage == nil {
            tintClearButton()
        }
    }

    override func deleteBackward() {
        lastReplacement = ""
        hideCursor = false

        guard markedTextRange == nil else {
            // If we have an active completion, delete it without deleting any user-typed characters.
            removeCompletion()
            forceResetCursor()
            return
        }

        super.deleteBackward()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEditing else { return }
        applyCompletion()
        super.touchesBegan(touches, with: event)
    }

    override open func caretRect(for position: UITextPosition) -> CGRect {
        return hideCursor ? CGRect.zero : super.caretRect(for: position)
    }

    override open func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        isSettingMarkedText = true
        removeCompletion()
        super.setMarkedText(markedText, selectedRange: selectedRange)
        isSettingMarkedText = false
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        let searchText = text ?? ""

        guard let suggestion = suggestion, isEditing && markedTextRange == nil else {
            hideCursor = false
            return
        }

        let normalized = normalizeString(searchText)
        guard suggestion.hasPrefix(normalized) && normalized.count < suggestion.count else {
            hideCursor = false
            return
        }

        let suggestionText = String(suggestion.dropFirst(normalized.count))
        setMarkedText(suggestionText, selectedRange: NSRange())
        hideCursor = true
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        /* Ecosia: Use Ecosia text/icon colors for location field (legacy URLBarView applyTheme)
        tintColor = colors.layerSelectedText
        clearButtonTintColor = colors.iconPrimary
        markedTextStyle = [NSAttributedString.Key.backgroundColor: colors.layerAutofillText]
        textColor = colors.textPrimary
         */
        tintColor = colors.ecosia.buttonBackgroundPrimary
        clearButtonTintColor = colors.ecosia.textPrimary
        markedTextStyle = [NSAttributedString.Key.backgroundColor: colors.ecosia.backgroundTertiary]
        textColor = colors.ecosia.textPrimary
        tintClearButton()
    }

    // MARK: - Private
    @objc
    private func textDidChange(_ textField: UITextField) {
        // When marked text (autocomplete suggestion) is set this method is called
        // in this case we don't need to
        guard !isSettingMarkedText else { return }

        hideCursor = markedTextRange != nil

        let isKeyboardReplacingText = lastReplacement != nil
        if isKeyboardReplacingText, markedTextRange == nil {
            notifyTextChanged?()
        } else {
            hideCursor = false
        }
    }

    /// Commits the completion by setting the text and removing the highlight.
    private func applyCompletion() {
        // Ecosia: Discard whitespace-only marked suffixes instead of committing them
        // as trailing spaces when the keyboard dismisses during suggestion scrolling.
        if let markedTextRange,
           let marked = markedSuggestionText(in: text ?? "", range: markedTextRange),
           marked.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _ = removeCompletion()
            hideCursor = false
            return
        }

        // Clear the current completion, then set the text without the attributed style.
        let text = (self.text ?? "")
        let didRemoveCompletion = removeCompletion()
        self.text = text
        hideCursor = false

        // Move the cursor to the end of the completion.
        if didRemoveCompletion {
            selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        }
    }

    // Ecosia: Read the marked autocomplete suffix without committing it.
    private func markedSuggestionText(in text: String, range: UITextRange) -> String? {
        let location = offset(from: beginningOfDocument, to: range.start)
        let length = offset(from: range.start, to: range.end)
        let nsRange = NSRange(location: location, length: length)
        guard nsRange.location != NSNotFound else { return nil }
        return (text as NSString).substring(with: nsRange)
    }

    /// Removes the autocomplete-highlighted. Returns true if a completion was actually removed
    @objc
    @discardableResult
    private func removeCompletion() -> Bool {
        guard markedTextRange != nil else { return false }

        text = textWithoutSuggestion()
        return true
    }

    private func textWithoutSuggestion() -> String? {
        guard let markedTextRange else { return text }

        let location = offset(from: beginningOfDocument, to: markedTextRange.start)
        let length = offset(from: markedTextRange.start, to: markedTextRange.end)
        let range = NSRange(location: location, length: length)
        return (text as NSString?)?.replacingCharacters(in: range, with: "")
    }

    @objc
    private func clear() {
        text = ""
        removeCompletion()
        autocompleteDelegate?.locationTextField(self, didEnterText: "")
    }

    private func normalizeString(_ string: String) -> String {
        return string.lowercased().stringByTrimmingLeadingCharactersInSet(CharacterSet.whitespaces)
    }

    // Reset the cursor to the end of the text field.
    // This forces `caretRect(for position: UITextPosition)` to be called which will decide if we should show the cursor
    // This exists because `caretRect(for position: UITextPosition)` is not called after we apply an autocompletion.
    private func forceResetCursor() {
        selectedTextRange = nil
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }

    private func tintClearButton() {
        // Since we're unable to change the tint color of the clear image, we need to use KVO to
        // find the clear button, and tint it ourselves.
        // https://stackoverflow.com/questions/27944781/how-to-change-the-tint-color-of-the-clear-button-on-a-uitextfield
        guard let image = UIImage(named: StandardImageIdentifiers.Large.crossCircleFill),
              let clearButtonTintColor,
              let clearButton = value(forKey: "_clearButton") as? UIButton
        else { return }

        // Ecosia: Stamp the clear button so UI automation can locate it by accessibility ID.
        clearButton.accessibilityIdentifier = "AddressBar.clearButton"
        tintedClearImage = image.withTintColor(clearButtonTintColor)
        clearButton.setImage(tintedClearImage, for: [])
    }

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        autocompleteDelegate?.locationTextFieldDidBeginEditing(self)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        /* Ecosia: Firefox always commits inline autocomplete on end-editing.
        applyCompletion()
        */
        if commitsAutocompleteOnEndEditing {
            applyCompletion()
        } else if markedTextRange != nil {
            _ = removeCompletion()
            hideCursor = false
        }
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        lastReplacement = nil
        textField.selectedTextRange = nil
        autocompleteDelegate?.locationTextFieldDidEndEditing(self)
    }

    // `shouldChangeCharactersInRange` is called before the text changes, and textDidChange is called after.
    // Since the text has changed, remove the completion here, and textDidChange will fire the callback to
    // get the new autocompletion.
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // This happens when you begin typing overtop the old highlighted
        // text immediately after focusing the text field. We need to trigger
        // a `didEnterText` that looks like a `clear()` so that the SearchLoader
        // can reset itself since it will only lookup results if the new text is
        // longer than the previous text.
        if lastReplacement == nil {
            autocompleteDelegate?.locationTextFieldNeedsSearchReset(textField)
        }

        lastReplacement = string
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyCompletion()
        return autocompleteDelegate?.locationTextFieldShouldReturn(self) ?? true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        text = ""
        removeCompletion()
        return autocompleteDelegate?.locationTextFieldShouldClear(self) ?? true
    }

    // MARK: - Debounce
    /**
      * Taken from http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call
      * Allows creating a block that will fire after a delay. Resets the timer if called again before the delay expires.
      **/
     private func debounce(_ delay: TimeInterval, action: @escaping () -> Void) -> () -> Void {
         let callback = Callback(handler: action)
         var timer: Timer?

         return {
             // If calling again, invalidate the last timer.
             if let timer { timer.invalidate() }
             timer = Timer(
                 timeInterval: delay,
                 target: callback,
                 selector: #selector(Callback.go),
                 userInfo: nil,
                 repeats: false
             )
             RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
         }
     }
}
