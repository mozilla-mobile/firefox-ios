/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public protocol AutocompleteTextFieldCompletionSource: class {
    func autocompleteTextFieldCompletionSource(_ autocompleteTextField: AutocompleteTextField, forText text: String) -> String?
}

@objc public protocol AutocompleteTextFieldDelegate: class {
    @objc optional func autocompleteTextFieldShouldBeginEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool
    @objc optional func autocompleteTextFieldShouldEndEditing(_ autocompleteTextField: AutocompleteTextField) -> Bool
    @objc optional func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool
    @objc optional func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didTextChange text: String)
}

open class AutocompleteTextField: UITextField, UITextFieldDelegate {
    public var highlightColor = UIColor(red: 0, green: 0.333, blue: 0.666, alpha: 0.2)

    public weak var completionSource: AutocompleteTextFieldCompletionSource?
    public weak var autocompleteDelegate: AutocompleteTextFieldDelegate?

    /// The range of the current completion, or nil if there is no active completion.
    private var completionRange: NSRange?

    // The last string used as a replacement in shouldChangeCharactersInRange.
    private var lastReplacement: String?

    public init() {
        super.init(frame: CGRect.zero)
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        delegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var text: String? {
        didSet {
            applyCompletion()
            super.text = text
        }
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        lastReplacement = string
        return true
    }

    @objc private func textDidChange() {
        removeCompletion()

        // Try setting a completion if we're not deleting and we're typing at the end of the text field.
        let isAtEnd = selectedTextRange?.start == endOfDocument
        let textBeforeCompletion = text
        let isEmpty = lastReplacement?.isEmpty ?? true
        if !isEmpty, isAtEnd, markedTextRange == nil,
           let completion = completionSource?.autocompleteTextFieldCompletionSource(self, forText: text ?? "") {
            setCompletion(completion)
        }

        // Fire the delegate with the text the user typed (not including the completion).
        autocompleteDelegate?.autocompleteTextField?(self, didTextChange: textBeforeCompletion ?? "")
    }

    override open func deleteBackward() {
        lastReplacement = nil

        guard completionRange == nil else {
            // If we have an active completion, delete it without deleting any user-typed characters.
            removeCompletion()
            return
        }

        super.deleteBackward()
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return autocompleteDelegate?.autocompleteTextFieldShouldBeginEditing?(self) ?? true
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        applyCompletion()
        return autocompleteDelegate?.autocompleteTextFieldShouldEndEditing?(self) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return autocompleteDelegate?.autocompleteTextFieldShouldReturn?(self) ?? true
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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

    open func highlightAll() {
        let text = self.text
        self.text = nil
        setCompletion(text ?? "")
        selectedTextRange = textRange(from: beginningOfDocument, to: beginningOfDocument)
    }

    private func applyCompletion() {
        guard completionRange != nil else { return }

        completionRange = nil

        // Clear the current completion, then set the text without the attributed style.
        // The attributed string must have at least one character to clear the current style.
        let text = self.text ?? ""
        attributedText = NSAttributedString(string: " ")
        self.text = text

        // Move the cursor to the end of the completion.
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }

    private func removeCompletion() {
        guard let completionRange = completionRange else { return }

        applyCompletion()

        // Fixes: https://github.com/mozilla-mobile/focus-ios/issues/630
        // Prevents the hard crash when you select all and start a new query
        guard let count = text?.count, count > 1 else { return }

        text = (text as NSString?)?.replacingCharacters(in: completionRange, with: "")
    }

    private func setCompletion(_ completion: String) {
        let text = self.text ?? ""

        // Ignore this completion if it's empty or doesn't start with the current text.
        guard !completion.isEmpty, completion.lowercased().hasPrefix(text.lowercased()) else { return }

        // Add the completion suffix to the current text and highlight it.
        let completion = completion[text.endIndex...]
        let attributed = NSMutableAttributedString(string: text + completion)
        let range = NSMakeRange((text as NSString).length, (completion as NSString).length)
        attributed.addAttribute(NSAttributedString.Key.backgroundColor, value: highlightColor, range: range)
        attributedText = attributed
        completionRange = range
    }
}
