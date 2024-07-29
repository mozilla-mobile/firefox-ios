// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Delegate for the text field events. Since LocationTextField owns the UITextFieldDelegate,
/// callers must use this instead.
protocol LocationTextFieldDelegate: AnyObject {
    func locationTextField(_ textField: LocationTextField, didEnterText text: String)
    func locationTextFieldShouldReturn(_ textField: LocationTextField) -> Bool
    func locationTextFieldShouldClear(_ textField: LocationTextField) -> Bool
    func locationTextFieldDidCancel(_ textField: LocationTextField)
    func locationPasteAndGo(_ textField: LocationTextField)
    func locationTextFieldDidBeginEditing(_ textField: UITextField)
    func locationTextFieldDidEndEditing(_ textField: UITextField)
}

class LocationTextField: UITextField, UITextFieldDelegate, ThemeApplicable {
    private var tintedClearImage: UIImage?
    private var clearButtonTintColor: UIColor?

    var autocompleteDelegate: LocationTextFieldDelegate?

    // This variable is a solution to get the right behaviour for refocusing
    // the LocationTextField. The initial transition into Overlay Mode
    // doesn't involve the user interacting with LocationTextField.
    // Thus, we update shouldApplyCompletion in touchesBegin() to reflect whether
    // the highlight is active and then the text field is updated accordingly
    // in touchesEnd() (eg. applyCompletion() is called or not)
    private var notifyTextChanged: (() -> Void)?

    /// The range of the current completion, or nil if there is no active completion.
    private var completionRange: NSRange?

    // The last string used as a replacement in shouldChangeCharactersInRange.
    private var lastReplacement: String?

    private let copyShortcutKey = "c"

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        super.addTarget(self, action: #selector(LocationTextField.textDidChange), for: .editingChanged)

        font = UIFont.preferredFont(forTextStyle: .body)
        adjustsFontForContentSizeCategory = true
        clearButtonMode = .whileEditing
        keyboardType = .webSearch
        autocorrectionType = .no
        autocapitalizationType = .none
        returnKeyType = .go
        delegate = self

        notifyTextChanged = debounce(0.1,
                                     action: {
            if self.isEditing {
                self.autocompleteDelegate?.locationTextField(
                    self,
                    didEnterText: self.normalizeString(self.text ?? "")
                )
            }
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var accessibilityActionsSource: AccessibilityActionsSource?

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

        guard let image = UIImage(named: StandardImageIdentifiers.Large.crossCircleFill) else { return }
        if tintedClearImage == nil {
            if let clearButtonTintColor {
                tintedClearImage = image.withTintColor(clearButtonTintColor)
            }
        }

        // Since we're unable to change the tint color of the clear image, we need to iterate through the
        // subviews, find the clear button, and tint it ourselves.
        // https://stackoverflow.com/questions/55046917/clear-button-on-text-field-not-accessible-with-voice-over-swift
        if let clearButton = value(forKey: "_clearButton") as? UIButton {
            clearButton.setImage(tintedClearImage, for: [])
        }
    }

    override func deleteBackward() {
        lastReplacement = nil

        guard completionRange == nil else {
            // If we have an active completion, delete it without deleting any user-typed characters.
            removeCompletion()
            return
        }

        super.deleteBackward()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        applyCompletion()
        super.touchesBegan(touches, with: event)
    }

    override open func caretRect(for forPosition: UITextPosition) -> CGRect {
        return (completionRange != nil) ? CGRect.zero : super.caretRect(for: forPosition)
    }

    override open func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        removeCompletion()
        super.setMarkedText(markedText, selectedRange: selectedRange)
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        let searchText = text ?? ""

        guard let suggestion = suggestion, isEditing && markedTextRange == nil else {
            return
        }

        let normalized = normalizeString(searchText)
        guard suggestion.hasPrefix(normalized) && normalized.count < suggestion.count else {
            return
        }

        let suggestionText = String(suggestion[suggestion.index(suggestion.startIndex, offsetBy: normalized.count)...])
        setMarkedText(suggestionText, selectedRange: NSRange())
        completionRange = NSRange(location: searchText.count, length: suggestionText.count)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        clearButtonTintColor = colors.iconPrimary
        textColor = colors.textPrimary
        markedTextStyle = [NSAttributedString.Key.backgroundColor: colors.layerSelectedText]
    }

    // MARK: - Private
    @objc
    private func textDidChange(_ textField: UITextField) {
        removeCompletion()

        let isKeyboardReplacingText = lastReplacement != nil
        if isKeyboardReplacingText, markedTextRange == nil {
            notifyTextChanged?()
        }
    }

    /// Commits the completion by setting the text and removing the highlight.
    private func applyCompletion() {
        // Clear the current completion, then set the text without the attributed style.
        let text = (self.text ?? "") // + (self.autocompleteTextLabel?.text ?? "")
        let didRemoveCompletion = removeCompletion()
        self.text = text

        // Move the cursor to the end of the completion.
        if didRemoveCompletion {
            selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        }
    }

    /// Removes the autocomplete-highlighted. Returns true if a completion was actually removed
    @objc
    @discardableResult
    private func removeCompletion() -> Bool {
        guard let completionRange = completionRange else { return false }

        // Prevents the hard crash when you select all and start a new query
        guard let count = text?.count,
              count > 1,
              count < completionRange.location,
              count <= completionRange.location + completionRange.length
        else { return false }

        text = (text as NSString?)?.replacingCharacters(in: completionRange, with: "")
        return true
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

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        autocompleteDelegate?.locationTextFieldDidBeginEditing(self)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        applyCompletion()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
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
            autocompleteDelegate?.locationTextField(self, didEnterText: "")
        }

        lastReplacement = string
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyCompletion()
        return autocompleteDelegate?.locationTextFieldShouldReturn(self) ?? true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        removeCompletion()
        return autocompleteDelegate?.locationTextFieldShouldClear(self) ?? true
    }

    // MARK: - Debounce

    // Encapsulate a callback in a way that we can use it with NSTimer.
    private class Callback {
        private let handler: () -> Void

        init(handler: @escaping () -> Void) {
            self.handler = handler
        }

        @objc
        func go() {
            handler()
        }
    }

    /**
      * Taken from http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call
      * Allows creating a block that will fire after a delay. Resets the timer if called again before the delay expires.
      **/
     private func debounce(_ delay: TimeInterval, action: @escaping () -> Void) -> () -> Void {
         let callback = Callback(handler: action)
         var timer: Timer?

         return {
             // If calling again, invalidate the last timer.
             if let timer = timer {
                 timer.invalidate()
             }
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
