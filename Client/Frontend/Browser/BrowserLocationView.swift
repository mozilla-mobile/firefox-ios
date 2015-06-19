/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

protocol BrowserLocationViewDelegate {
    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidLongPressLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView)
    func browserLocationViewDidLongPressReaderMode(browserLocationView: BrowserLocationView)
}

private struct BrowserLocationViewUX {
    static let HostFontColor = UIColor.blackColor()
    static let BaseURLFontColor = UIColor.lightGrayColor()
    static let DefaultURLColor = UIColor.blackColor()
}

enum InputMode {
    case URL
    case Search
}

class BrowserLocationView : UIView, ToolbarTextFieldDelegate {
    var delegate: BrowserLocationViewDelegate?
    var inputMode: InputMode = .URL
    private var lockImageView: UIImageView!
    private var readerModeButton: ReaderModeButton!
    var editTextField: ToolbarTextField!

    var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set(newCornerRadius) {
            self.layer.cornerRadius = newCornerRadius
        }
    }

    var editingBorderColor: CGColorRef!
    var borderColor: CGColorRef! {
        didSet {
            if !editTextField.isFirstResponder(){
                self.layer.borderColor = borderColor
            }
        }
    }

    var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }

        set (newBorderWidth) {
            self.layer.borderWidth = newBorderWidth
        }
    }

    var locationContentInset: CGFloat = 0

    var text: String {
        get {
            return editTextField.text
        }
        set(newText) {
            editTextField.text = newText
            editTextField.becomeFirstResponder()
        }
    }

    var autocompleteDelegate: AutocompleteTextFieldDelegate? {
        get {
            return editTextField.autocompleteDelegate
        }
        set (delegate) {
            editTextField.autocompleteDelegate = delegate
        }
    }

    var readerModeButtonWidthConstraint: NSLayoutConstraint?

    var active = false {
        didSet{
            if !active
                && editTextField.isFirstResponder() {
                    editTextField.resignFirstResponder()
            }
        }
    }

    private var clearedText: String?

    static var PlaceholderText: NSAttributedString {
        let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
        return NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        borderColor = UIColor.clearColor().CGColor
        editingBorderColor = UIColor.clearColor().CGColor

        editTextField = ToolbarTextField()
        editTextField.keyboardType = UIKeyboardType.WebSearch
        editTextField.autocorrectionType = UITextAutocorrectionType.No
        editTextField.autocapitalizationType = UITextAutocapitalizationType.None
        editTextField.returnKeyType = UIReturnKeyType.Go
        editTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        editTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        editTextField.font = AppConstants.DefaultMediumFont
        editTextField.isAccessibilityElement = true
        editTextField.accessibilityIdentifier = "url"
        editTextField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
        editTextField.attributedPlaceholder = BrowserLocationView.PlaceholderText
        editTextField.toolbarTextFieldDelegate = self
        addSubview(editTextField)

        lockImageView = UIImageView(image: UIImage(named: "lock_verified.png"))
        lockImageView.hidden = true
        lockImageView.isAccessibilityElement = true
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
        addSubview(lockImageView)

        readerModeButton = ReaderModeButton(frame: CGRectZero)
        readerModeButton.hidden = true
        readerModeButton.addTarget(self, action: "SELtapReaderModeButton", forControlEvents: .TouchUpInside)
        readerModeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "SELlongPressReaderModeButton:"))
        addSubview(readerModeButton)
        readerModeButton.isAccessibilityElement = true
        readerModeButton.accessibilityLabel = NSLocalizedString("Reader Mode", comment: "Accessibility label for the reader mode button")

        accessibilityElements = [lockImageView, editTextField, readerModeButton]
    }

    override func updateConstraints() {
        super.updateConstraints()

        let container = self

        lockImageView.snp_remakeConstraints { make in
            make.centerY.equalTo(container)
            make.leading.equalTo(container).offset(locationContentInset)
            make.width.equalTo(self.lockImageView.intrinsicContentSize().width)
        }

        readerModeButton.snp_remakeConstraints { make in
            make.centerY.equalTo(container)
            make.trailing.equalTo(self.snp_trailing).offset(-(locationContentInset / 2))

            // We fix the width of the button (to the height of the view) to prevent content
            // compression when the locationLabel has more text contents than will fit. It
            // would be nice to do this with a content compression priority but that does
            // not seem to work.
            make.width.equalTo(container.snp_height)
        }

        editTextField.snp_remakeConstraints { make in
            make.centerY.equalTo(container)
            if lockImageView.hidden {
                make.leading.equalTo(container).offset(locationContentInset)
            } else {
                make.leading.equalTo(self.lockImageView.snp_trailing).offset(locationContentInset)
            }
            if readerModeButton.hidden {
                make.trailing.equalTo(container.snp_trailing)
            } else {
                make.trailing.equalTo(self.readerModeButton.snp_leading)
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 200, height: 28)
    }

    func SELtapReaderModeButton() {
        delegate?.browserLocationViewDidTapReaderMode(self)
    }

    func SELlongPressReaderModeButton(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            delegate?.browserLocationViewDidLongPressReaderMode(self)
        }
    }

    var url: NSURL? {
        didSet {
            lockImageView.hidden = url?.scheme != "https"
            if let url = url?.absoluteString {
            	highlightDomain()
            } else {
                editTextField.text = nil
            }
            setNeedsUpdateConstraints()
        }
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            if newReaderModeState != self.readerModeButton.readerModeState {
                self.readerModeButton.readerModeState = newReaderModeState
                readerModeButton.hidden = (newReaderModeState == ReaderModeState.Unavailable)
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    if newReaderModeState == ReaderModeState.Unavailable {
                        self.readerModeButton.alpha = 0.0
                    } else {
                        self.readerModeButton.alpha = 1.0
                    }
                    self.setNeedsUpdateConstraints()
                    self.layoutIfNeeded()
                })
            }
        }
    }

    private func highlightDomain() {
        if let httplessURL = url?.absoluteStringWithoutHTTPScheme(), let baseDomain = url?.baseDomain() {
            var attributedString = NSMutableAttributedString(string: httplessURL)
            let nsRange = NSMakeRange(0, count(httplessURL))
            attributedString.addAttribute(NSForegroundColorAttributeName, value: BrowserLocationViewUX.BaseURLFontColor, range: nsRange)
            attributedString.colorSubstring(baseDomain, withColor: BrowserLocationViewUX.HostFontColor)
            editTextField.attributedText = attributedString
        }
    }

    func cancel() {
        active = false
        if editTextField.text.isEmpty {
            editTextField.text = clearedText ?? ""
        }
    }

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        active = true
        layer.borderColor = editingBorderColor
        textField.textColor = BrowserLocationViewUX.DefaultURLColor

        setNeedsUpdateConstraints()
        delegate?.browserLocationViewDidTapLocation(self)

        if inputMode == .URL {
            textField.text = url?.absoluteString
        }

        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {
        layer.borderColor = borderColor
        highlightDomain()
        active = false
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        clearedText = textField.text
        return true
    }

    func textFieldDidLongPress(textField: ToolbarTextField) {
        delegate?.browserLocationViewDidLongPressLocation(self)
    }
}

private class ReaderModeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setImage(UIImage(named: "reader.png"), forState: UIControlState.Normal)
        setImage(UIImage(named: "reader_active.png"), forState: UIControlState.Selected)
        accessibilityLabel = NSLocalizedString("Reader", comment: "Browser function that presents simplified version of the page with bigger text.")
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var _readerModeState: ReaderModeState = ReaderModeState.Unavailable
    
    var readerModeState: ReaderModeState {
        get {
            return _readerModeState;
        }
        set (newReaderModeState) {
            _readerModeState = newReaderModeState
            switch _readerModeState {
            case .Available:
                self.enabled = true
                self.selected = false
            case .Unavailable:
                self.enabled = false
                self.selected = false
            case .Active:
                self.enabled = true
                self.selected = true
            }
        }
    }
}

@objc protocol ToolbarTextFieldDelegate: UITextFieldDelegate {
    optional func textFieldDidLongPress(textField: ToolbarTextField)
}


class ToolbarTextField: AutocompleteTextField, UITextFieldDelegate, UIGestureRecognizerDelegate {

    var toolbarTextFieldDelegate: ToolbarTextFieldDelegate?

    private var longPress = false
    override init(frame: CGRect) {

        super.init(frame: frame)
        var longPressRecogniser = UILongPressGestureRecognizer(target: self, action: Selector("longPress:"))
        longPressRecogniser.delegate = self
        self.addGestureRecognizer(longPressRecogniser)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textFieldDidBeginEditing(textField: UITextField) {
        super.textFieldDidBeginEditing(textField)
        toolbarTextFieldDelegate?.textFieldDidBeginEditing?(textField)
        textField.selectedTextRange = textField.textRangeFromPosition(textField.beginningOfDocument, toPosition: textField.endOfDocument)
    }

    override func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        var shouldBeginEditing = super.textFieldShouldBeginEditing(textField)

        return (toolbarTextFieldDelegate?.textFieldShouldBeginEditing?(textField) ?? shouldBeginEditing) && !longPress
    }

    override func textFieldShouldClear(textField: UITextField) -> Bool {
        let shouldClear = super.textFieldShouldClear(textField)
        return toolbarTextFieldDelegate?.textFieldShouldClear?(textField) ?? shouldClear
    }

    override func textFieldDidEndEditing(textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        toolbarTextFieldDelegate?.textFieldDidEndEditing?(textField)
    }

    func longPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            longPress = true
        }
        else if gestureRecognizer.state == .Ended {
            toolbarTextFieldDelegate?.textFieldDidLongPress?(self)
            longPress = false
        }
        else {
            longPress = false
        }
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // only recognise our custom long press gesture recognizer when a long press is activated if we are not already
        // editing this text field
        return !active && (gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) && otherGestureRecognizer.isKindOfClass(UILongPressGestureRecognizer))
    }
}
