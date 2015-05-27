/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol BrowserLocationViewDelegate {
    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidLongPressLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView)
    func browserLocationViewDidLongPressReaderMode(browserLocationView: BrowserLocationView)
}

class BrowserLocationView : UIView, UIGestureRecognizerDelegate, ToolbarTextFieldDelegate {
    var delegate: BrowserLocationViewDelegate?

    private var lockImageView: UIImageView!
    private var readerModeButton: ReaderModeButton!
    var editTextField: ToolbarTextField!

    var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set(newCornerRadius) {
            self.layer.cornerRadius = newCornerRadius
            editTextField.layer.cornerRadius = cornerRadius
        }
    }

    var editingBorderColor: CGColorRef {
        get{
            return editTextField.layer.borderColor
        }
        set(borderColor){
            editTextField.layer.borderColor = borderColor
        }
    }

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
            if active {
                editTextField.layer.borderWidth = 1
            }
            else {
                editTextField.layer.borderWidth = 0
                if editTextField.isFirstResponder() {
                    editTextField.resignFirstResponder()
                }
            }
            readerModeButton.hidden = active
        }
    }

    var editingInset: CGPoint  {
        get {
            return editTextField.editingRectInset
        }
        set(inset) {
            editTextField.editingRectInset = inset
        }
    }

    var textInset: CGPoint  {
        get {
            return editTextField.textRectInset
        }
        set(inset) {
            editTextField.textRectInset = inset
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

        editTextField = ToolbarTextField()
        editTextField.keyboardType = UIKeyboardType.WebSearch
        editTextField.autocorrectionType = UITextAutocorrectionType.No
        editTextField.autocapitalizationType = UITextAutocapitalizationType.None
        editTextField.returnKeyType = UIReturnKeyType.Go
        editTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        editTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        editTextField.font = AppConstants.DefaultMediumFont
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
            make.leading.equalTo(container).offset(8)
            make.width.equalTo(self.lockImageView.intrinsicContentSize().width)
        }

        editTextField.snp_remakeConstraints { make in
            make.edges.equalTo(container)
        }

        readerModeButton.snp_remakeConstraints { make in
            make.centerY.equalTo(container)
            make.trailing.equalTo(self.snp_trailing).offset(-4)

            // We fix the width of the button (to the height of the view) to prevent content
            // compression when the locationLabel has more text contents than will fit. It
            // would be nice to do this with a content compression priority but that does
            // not seem to work.
            make.width.equalTo(container.snp_height)
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
            showLockImage((url?.scheme == "https"))
            if let url = url?.absoluteString {
                if url.hasPrefix("http://") ?? false {
                    editTextField.text = url.substringFromIndex(advance(url.startIndex, 7))
                } else if url.hasPrefix("https://") ?? false {
                    editTextField.text = url.substringFromIndex(advance(url.startIndex, 8))
                } else {
                    editTextField.text = url
                }
            }

            setNeedsUpdateConstraints()
        }
    }

    func showLockImage(show: Bool) {
        // I know this could be written show == lockImageView.hidden but this made the code more semantically meaningful
        let isVisible = !lockImageView.hidden
        if show != isVisible {
            if show {
                editTextField.textRectInset.x += lockImageView.bounds.width
                editTextField.editingRectInset.x += lockImageView.bounds.width
            }
            else {
                editTextField.textRectInset.x -= lockImageView.bounds.width
                editTextField.editingRectInset.x -= lockImageView.bounds.width
            }
        }
        lockImageView.hidden = !show
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            if newReaderModeState != self.readerModeButton.readerModeState {
                self.readerModeButton.readerModeState = newReaderModeState
                setNeedsUpdateConstraints()
                readerModeButton.hidden = (newReaderModeState == ReaderModeState.Unavailable)
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    if newReaderModeState == ReaderModeState.Unavailable {
                        self.readerModeButton.alpha = 0.0
                    } else {
                        self.readerModeButton.alpha = 1.0
                    }
                    self.layoutIfNeeded()
                })
            }
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
        textField.text = url?.absoluteString
        delegate?.browserLocationViewDidTapLocation(self)
        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {
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

    var textRectInset: CGPoint = CGPointZero
    var editingRectInset: CGPoint = CGPointZero

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

    override func textRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.textRectForBounds(bounds)
        return rect.rectByInsetting(dx: textRectInset.x, dy: textRectInset.y)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.editingRectForBounds(bounds)
        return rect.rectByInsetting(dx:editingRectInset.x, dy: editingRectInset.y)
    }

    override func textFieldDidBeginEditing(textField: UITextField) {
        println("textFieldDidBeginEditing")
        super.textFieldDidBeginEditing(textField)
        toolbarTextFieldDelegate?.textFieldDidBeginEditing?(textField)
    }

    override func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        println("textFieldShouldBeginEditing \(!longPress)")
        var shouldBeginEditing = super.textFieldShouldBeginEditing(textField)

        return (toolbarTextFieldDelegate?.textFieldShouldBeginEditing?(textField) ?? shouldBeginEditing) && !longPress
    }

    override func textFieldShouldClear(textField: UITextField) -> Bool {
        let shouldClear = super.textFieldShouldClear(textField)
        return toolbarTextFieldDelegate?.textFieldShouldClear?(textField) ?? shouldClear
    }

    func textFieldDidEndEditing(textField: UITextField) {
        println("textFieldDidEndEditing")
        toolbarTextFieldDelegate?.textFieldDidEndEditing?(textField)
    }

    func longPress(gestureRecognizer: UIGestureRecognizer) {
        print("long press")
        if gestureRecognizer.state == .Began {
            println(" Began")
            longPress = true
        }
        else if gestureRecognizer.state == .Ended {
            println(" Ended")
            toolbarTextFieldDelegate?.textFieldDidLongPress?(self)
            longPress = false
        }
        else {
            longPress = false
        }
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
            println("long press shouldRecognizeSimultaneouslyWithGestureRecognizer \(otherGestureRecognizer)")
        }
        return true
    }

//    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
//        println("\ntouches began \(event)")
//        super.touchesBegan(touches, withEvent: event)
//        pressing = true
//    }
//
//    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
//        println("\ntouches ended \(event)")
//        super.touchesEnded(touches, withEvent: event)
//        pressing = false
//    }
//
//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
//
//        if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
//            println("long press shouldReceiveTouch \(gestureRecognizer)")
//        }
//        return true
//    }
//
//    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
//        let shouldBegin = super.gestureRecognizerShouldBegin(gestureRecognizer)
//        if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
//            println("long press gestureRecognizerShouldBegin \(gestureRecognizer)")
//        }
//        return shouldBegin
//    }
//
//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
//            println("long press shouldRequireFailureOfGestureRecognizer \(gestureRecognizer), \(otherGestureRecognizer)")
//        }
//
//        return false
//    }
//
//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
//            println("long press shouldBeRequiredToFailByGestureRecognizer \(gestureRecognizer), \(otherGestureRecognizer)")
//        }
//
//        return false
//    }
}
