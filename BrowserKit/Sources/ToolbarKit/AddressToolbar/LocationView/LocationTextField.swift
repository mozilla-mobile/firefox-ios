// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Delegate for the text field events. Since LocationTextField owns the UITextFieldDelegate,
/// callers must use this instead.
@MainActor
protocol LocationTextFieldDelegate: AnyObject {
    func locationTextFieldDidEnterText(_ text: String)
    func locationTextFieldShouldReturn(_ textField: LocationTextField) -> Bool
    func locationTextFieldShouldClear() -> Bool
    func locationTextFieldDidBeginEditing(_ textField: UITextField)
    func locationTextFieldDidEndEditing()
    func locationTextFieldNeedsSearchReset()
    func locationTextFieldDidDisplayEditingAccessoryButton(_ button: UIButton, contextualHintType: String)
    func locationTextFieldDidHideEditingAccessoryButton()
}

final class LocationTextField: UITextField, UITextFieldDelegate, ThemeApplicable {
    private enum UX {
        static let editingAccessoryRightViewSize = CGSize(width: 44, height: 44)
        static let editingAccessoryContentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 12,
            bottom: 12,
            trailing: 12
        )
    }

    public var notificationCenter: NotificationProtocol = NotificationCenter.default

    private var tintedClearImage: UIImage?
    private var clearButtonTintColor: UIColor?

    weak var autocompleteDelegate: LocationTextFieldDelegate?

    // The autocomplete suggestion is rendered in a separate label overlay rather than as
    // marked text. Using marked text conflicts with IME keyboards (Chinese, Japanese, …):
    // the IME treats the suggestion as an active composition, so Return confirms the
    // "composition" instead of submitting, and composition updates can clobber typed text.
    private var autocompleteTextLabel: UILabel?
    private var suggestionHighlightColor: UIColor = .clear

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

    var isSelectionActive: Bool {
        return autocompleteTextLabel != nil
    }

    var clearButton: UIButton? {
        return value(forKey: "_clearButton") as? UIButton
    }

    var editingAccessoryAction: ToolbarElement? {
        didSet {
            configureEditingAccessoryButton()
            updateRightView()
        }
    }

    private lazy var editingAccessoryRightView: ToolbarButton = {
        let button = ToolbarButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: UX.editingAccessoryRightViewSize.width),
            button.heightAnchor.constraint(equalToConstant: UX.editingAccessoryRightViewSize.height)
        ])
        return button
    }()

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
        set {
            super.accessibilityValue = newValue
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        addTarget(self, action: #selector(LocationTextField.textDidChange), for: .editingChanged)

        font = FXFontStyles.Regular.body.scaledFont()
        adjustsFontForContentSizeCategory = true
        clearButtonMode = .whileEditing
        keyboardType = .webSearch
        autocorrectionType = .no
        autocapitalizationType = .none
        smartQuotesType = .no
        smartDashesType = .no
        returnKeyType = .go
        tintAdjustmentMode = .normal
        delegate = self

        // Disable dragging urls on iPhones because it conflicts with editing the text
        if UIDevice.current.userInterfaceIdiom != .pad {
            textDragInteraction?.isEnabled = false
        }

        notifyTextChanged = debounce(0.1,
                                     action: {
            if self.isEditing {
                self.autocompleteDelegate?.locationTextFieldDidEnterText(
                    self.normalizeString(self.text ?? "")
                )
            }
        })
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

        if tintedClearImage == nil {
            tintClearButton()
        }
    }

    override func deleteBackward() {
        lastReplacement = ""
        hideCursor = false

        if isSelectionActive {
            // If we have an active completion, delete it without deleting any user-typed characters.
            removeCompletion()
            forceResetCursor()
        } else {
            super.deleteBackward()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEditing else { return }
        applyCompletion()
        super.touchesBegan(touches, with: event)
    }

    override public func caretRect(for position: UITextPosition) -> CGRect {
        return hideCursor ? CGRect.zero : super.caretRect(for: position)
    }

    override public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        // Clear the autocompletion if any provisionally inserted text has been
        // entered (e.g., a partial composition from a Japanese keyboard).
        removeCompletion()
        hideCursor = false
        super.setMarkedText(markedText, selectedRange: selectedRange)
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        let searchText = text ?? ""

        // Never show a suggestion while a real IME composition is in progress.
        guard let suggestion, isEditing, markedTextRange == nil else {
            removeCompletion()
            hideCursor = false
            return
        }

        let normalized = normalizeString(searchText)
        guard suggestion.hasPrefix(normalized), normalized.count < suggestion.count else {
            removeCompletion()
            hideCursor = false
            return
        }

        let suggestionText = String(suggestion.dropFirst(normalized.count))
        let autocompleteText = NSMutableAttributedString(string: suggestionText)
        autocompleteText.addAttribute(
            .backgroundColor,
            value: suggestionHighlightColor,
            range: NSRange(location: 0, length: (suggestionText as NSString).length)
        )

        autocompleteTextLabel?.removeFromSuperview() // should be nil. But just in case
        let label = createAutocompleteLabel(with: autocompleteText)
        autocompleteTextLabel = label
        addSubview(label)

        // Only call forceResetCursor() if `hideCursor` changes.
        // Because forceResetCursor() auto accepts iOS user's text replacement
        // (e.g. mu->μ) which makes user unable to type "mu".
        if !hideCursor {
            hideCursor = true
            forceResetCursor()
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        tintColor = colors.layerSelectedText
        clearButtonTintColor = colors.iconPrimary
        editingAccessoryRightView.applyTheme(theme: theme)
        suggestionHighlightColor = colors.layerAutofillText

        if let label = autocompleteTextLabel,
           let attributed = label.attributedText?.mutableCopy() as? NSMutableAttributedString {
            attributed.addAttribute(.backgroundColor,
                                    value: suggestionHighlightColor,
                                    range: NSRange(location: 0, length: attributed.length))
            label.attributedText = attributed
        }
        tintClearButton()
    }

    // MARK: - Private

    @objc
    private func textDidChange(_ sender: Any?) {
        hideCursor = isSelectionActive
        removeCompletion()

        let isKeyboardReplacingText = lastReplacement != nil
        if isKeyboardReplacingText, markedTextRange == nil {
            notifyTextChanged?()
        } else {
            hideCursor = false
        }
        updateRightView()
    }

    private func configureEditingAccessoryButton() {
        guard let editingAccessoryAction, editingAccessoryAction.iconName != nil else { return }

        editingAccessoryRightView.configure(element: editingAccessoryAction)
        var configuration = editingAccessoryRightView.configuration
        configuration?.contentInsets = UX.editingAccessoryContentInsets
        editingAccessoryRightView.configuration = configuration
    }

    private func updateRightView() {
        let textIsEmpty = text?.isEmpty ?? true
        let shouldShowEditingAccessory = editingAccessoryAction?.iconName != nil && isEditing && textIsEmpty
        let wasShowingEditingAccessory = rightView != nil && rightView === editingAccessoryRightView

        if shouldShowEditingAccessory {
            rightView = editingAccessoryRightView
            rightViewMode = .whileEditing
            clearButtonMode = .never

            if !wasShowingEditingAccessory,
               let contextualHintType = editingAccessoryAction?.contextualHintType {
                autocompleteDelegate?.locationTextFieldDidDisplayEditingAccessoryButton(
                    editingAccessoryRightView,
                    contextualHintType: contextualHintType
                )
            }
        } else {
            rightView = nil
            rightViewMode = .never
            clearButtonMode = .whileEditing
            if wasShowingEditingAccessory {
                autocompleteDelegate?.locationTextFieldDidHideEditingAccessoryButton()
            }
        }
    }

    /// Commits the completion by setting the text and removing the highlight.
    private func applyCompletion() {
        let text = (self.text ?? "") + (self.autocompleteTextLabel?.text ?? "")
        let didRemoveCompletion = removeCompletion()
        super.text = text
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
        updateRightView()
        autocompleteDelegate?.locationTextFieldDidEnterText("")
    }

    private func createAutocompleteLabel(with autocompleteText: NSAttributedString) -> UILabel {
        let label = UILabel()
        var frame = self.bounds
        label.attributedText = autocompleteText
        label.font = self.font
        label.accessibilityIdentifier = "autocomplete"
        label.textColor = self.textColor
        label.textAlignment = .left
        label.isUserInteractionEnabled = false

        let fontAttributes: [NSAttributedString.Key: Any] = [.font: self.font as Any]
        let enteredTextWidth = ((self.text ?? "") as NSString).size(withAttributes: fontAttributes).width
        frame.origin.x = enteredTextWidth.rounded() + textRect(forBounds: bounds).origin.x
        frame.size.width = self.frame.size.width - clearButtonRect(forBounds: self.bounds).size.width - frame.origin.x
        frame.size.height = self.frame.size.height
        label.frame = frame
        return label
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

        tintedClearImage = image.withTintColor(clearButtonTintColor)
        clearButton.setImage(tintedClearImage, for: [])
    }

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        updateRightView()
        autocompleteDelegate?.locationTextFieldDidBeginEditing(self)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        applyCompletion()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        lastReplacement = nil
        textField.selectedTextRange = nil
        updateRightView()
        autocompleteDelegate?.locationTextFieldDidEndEditing()
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
            autocompleteDelegate?.locationTextFieldNeedsSearchReset()
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
        updateRightView()
        return autocompleteDelegate?.locationTextFieldShouldClear() ?? true
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
