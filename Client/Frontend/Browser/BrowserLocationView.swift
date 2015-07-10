/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SnapKit

protocol BrowserLocationViewDelegate {
    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidLongPressLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView)
    /// :returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    func browserLocationViewDidLongPressReaderMode(browserLocationView: BrowserLocationView) -> Bool
    func browserLocationViewLocationAccessibilityActions(browserLocationView: BrowserLocationView) -> [UIAccessibilityCustomAction]?
}

private struct BrowserLocationViewUX {
    static let HostFontColor = UIColor.blackColor()
    static let BaseURLFontColor = UIColor.lightGrayColor()
    static let DefaultURLColor = UIColor.blackColor()
    static let BaseURLPitch = 0.75
    static let HostPitch = 1.0
}

enum InputMode {
    case URL
    case Search
}

class BrowserLocationView : UIView, UIGestureRecognizerDelegate, UITextFieldDelegate {
    var delegate: BrowserLocationViewDelegate?
    var inputMode: InputMode = .URL
    private var borderLayer: UIView!
    private var lockImageView: UIImageView!
    private var readerModeButton: ReaderModeButton!
    var editTextField: ToolbarTextField!

    private var editTextFieldListenerView: UIView!

    var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set(newCornerRadius) {
            self.layer.cornerRadius = newCornerRadius
            // need to add borderWidth to the borderLayer radius so the corners nest properly, because it is offset outside this view
            borderLayer.layer.cornerRadius = newCornerRadius + self.borderWidth
        }
    }

    var editingBorderColor: CGColorRef!
    var borderColor: CGColorRef! {
        didSet {
            if !editTextField.isFirstResponder(){
                borderLayer.layer.borderColor = borderColor
            }
        }
    }

    var borderWidth: CGFloat {
        get {
            return borderLayer.layer.borderWidth
        }

        set (newBorderWidth) {
            borderLayer.layer.borderWidth = newBorderWidth
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

        borderLayer = UIView()
        addSubview(borderLayer)

        editTextField = ToolbarTextField()
        editTextField.keyboardType = UIKeyboardType.WebSearch
        editTextField.autocorrectionType = UITextAutocorrectionType.No
        editTextField.autocapitalizationType = UITextAutocapitalizationType.None
        editTextField.returnKeyType = UIReturnKeyType.Go
        editTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        editTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        editTextField.font = UIConstants.DefaultMediumFont
        editTextField.isAccessibilityElement = true
        editTextField.accessibilityActionsSource = self
        editTextField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
        editTextField.attributedPlaceholder = BrowserLocationView.PlaceholderText
        editTextField.toolbarTextFieldDelegate = self
        addSubview(editTextField)

        editTextFieldListenerView = UIView()
        editTextFieldListenerView.userInteractionEnabled = true
        editTextFieldListenerView.accessibilityIdentifier = "url"
        editTextFieldListenerView.accessibilityLabel = NSLocalizedString("URL bar", comment: "Accessibility label for the URL bar")
        editTextFieldListenerView.backgroundColor = UIColor.clearColor()
        editTextFieldListenerView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "SELlongPressLocation:"))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "SELtapLocation:")
        tapRecognizer.numberOfTapsRequired = 1
        editTextFieldListenerView.addGestureRecognizer(tapRecognizer)
        addSubview(editTextFieldListenerView)

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
        readerModeButton.accessibilityLabel = NSLocalizedString("Reader View", comment: "Accessibility label for the Reader View button")
        readerModeButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: NSLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list."), target: self, selector: "SELreaderModeCustomAction")]

        accessibilityElements = [editTextFieldListenerView, lockImageView, editTextField, readerModeButton]
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
            make.height.equalTo(container)
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
        
        editTextFieldListenerView.snp_remakeConstraints { make in
            make.width.equalTo(editTextField.snp_width)
            make.height.equalTo(editTextField.snp_height)
            make.center.equalTo(editTextField.snp_center)
        }

        borderLayer.snp_makeConstraints { make in
            make.edges.equalTo(container).insets(EdgeInsetsMake(-borderWidth, -borderWidth, -borderWidth, -borderWidth))
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

    func SELlongPressLocation(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            delegate?.browserLocationViewDidLongPressLocation(self)
        }
    }

    func SELtapLocation(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            editTextFieldListenerView.hidden = true
            editTextField.becomeFirstResponder()
        }
    }

    func SELreaderModeCustomAction() -> Bool {
        return delegate?.browserLocationViewDidLongPressReaderMode(self) ?? false
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
            attributedString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(double: BrowserLocationViewUX.BaseURLPitch), range: nsRange)
            attributedString.pitchSubstring(baseDomain, withPitch: BrowserLocationViewUX.HostPitch)
            editTextField.attributedText = attributedString
        }
    }

    func cancel() {
        active = false
        if editTextField.text.isEmpty {
            editTextField.text = clearedText ?? ""
        } else if let url = self.url {
            highlightDomain()
        } else {
            self.url = nil
        }
    }

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        active = true
        textField.textColor = BrowserLocationViewUX.DefaultURLColor

        setNeedsUpdateConstraints()
        delegate?.browserLocationViewDidTapLocation(self)

        if inputMode == .URL {
            textField.text = url?.absoluteString
        }

        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.borderLayer.layer.borderColor = self.editingBorderColor
            self.readerModeButton.hidden = true
            self.lockImageView.hidden = true
            self.setNeedsUpdateConstraints()
        })
    }

    func textFieldDidEndEditing(textField: UITextField) {
        active = false
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.borderLayer.layer.borderColor = self.borderColor
            self.readerModeButton.hidden = (self.readerModeButton.readerModeState == ReaderModeState.Unavailable)
            self.lockImageView.hidden = self.url?.scheme != "https"
            self.setNeedsUpdateConstraints()
        })
        editTextFieldListenerView.hidden = false
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        clearedText = textField.text
        return true
    }


    func longPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            delegate?.browserLocationViewDidLongPressLocation(self)
        }
    }
}

extension BrowserLocationView: AccessibilityActionsSource {
    func accessibilityCustomActionsForView(view: UIView) -> [UIAccessibilityCustomAction]? {
        if view === editTextField {
            return delegate?.browserLocationViewLocationAccessibilityActions(self)
        }
        return nil
    }
}

private class ReaderModeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setImage(UIImage(named: "reader.png"), forState: UIControlState.Normal)
        setImage(UIImage(named: "reader_active.png"), forState: UIControlState.Selected)
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

class ToolbarTextField: AutocompleteTextField, UITextFieldDelegate {

    var toolbarTextFieldDelegate: UITextFieldDelegate?

    weak var accessibilityActionsSource: AccessibilityActionsSource?
    override var accessibilityCustomActions: [AnyObject]! {
        get {
            if !editing {
                return accessibilityActionsSource?.accessibilityCustomActionsForView(self)
            }
            return super.accessibilityCustomActions
        }
        set {
            super.accessibilityCustomActions = newValue
        }
    }

    override init(frame: CGRect) {

        super.init(frame: frame)
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
        active = toolbarTextFieldDelegate?.textFieldShouldBeginEditing?(textField) ?? super.textFieldShouldBeginEditing(textField)
        return active
    }

    override func textFieldShouldClear(textField: UITextField) -> Bool {
        let shouldClear = super.textFieldShouldClear(textField)
        return toolbarTextFieldDelegate?.textFieldShouldClear?(textField) ?? shouldClear
    }

    override func textFieldDidEndEditing(textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        toolbarTextFieldDelegate?.textFieldDidEndEditing?(textField)
    }
}
