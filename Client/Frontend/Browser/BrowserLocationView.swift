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
    static let BaseURLPitch = 0.75
    static let HostPitch = 1.0
    static let LocationContentInset: CGFloat = 8
}

class BrowserLocationView: UIView {
    var delegate: BrowserLocationViewDelegate?

    var url: NSURL? {
        didSet {
            lockImageView.hidden = url?.scheme != "https"
            updateTextWithURL()
            self.setNeedsLayout()
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
                    self.setNeedsLayout()
                })
            }
        }
    }

    lazy var placeholder: NSAttributedString = {
        let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
        return NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
    }()

    lazy var urlTextField: UITextField = {
        let urlTextField = UITextField()
        urlTextField.userInteractionEnabled = true
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: "SELlongPressLocation:")
        gestureRecognizer.delegate = self
        urlTextField.addGestureRecognizer(gestureRecognizer)
        urlTextField.delegate = self
        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.font = UIConstants.DefaultMediumFont
        return urlTextField
    }()

    private lazy var lockImageView: UIImageView = {
        let lockImageView = UIImageView(image: UIImage(named: "lock_verified.png"))
        lockImageView.hidden = true
        lockImageView.isAccessibilityElement = true
        lockImageView.contentMode = UIViewContentMode.Center
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
        return lockImageView
    }()

    private lazy var readerModeButton: ReaderModeButton = {
        let readerModeButton = ReaderModeButton(frame: CGRectZero)
        readerModeButton.hidden = true
        readerModeButton.addTarget(self, action: "SELtapReaderModeButton", forControlEvents: .TouchUpInside)
        readerModeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "SELlongPressReaderModeButton:"))
        readerModeButton.isAccessibilityElement = true
        readerModeButton.accessibilityLabel = NSLocalizedString("Reader View", comment: "Accessibility label for the Reader View button")
        readerModeButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: NSLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list."), target: self, selector: "SELreaderModeCustomAction")]
        return readerModeButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.whiteColor()

        addSubview(urlTextField)
        addSubview(lockImageView)
        addSubview(readerModeButton)

        accessibilityElements = [lockImageView, urlTextField, readerModeButton]
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let centerY = frame.size.height / 2

        var lockFrame = CGRect()
        lockFrame.origin = CGPointZero
        if !lockImageView.hidden  {
            lockFrame.size = self.lockImageView.intrinsicContentSize()
            lockFrame.size.width += CGFloat(BrowserLocationViewUX.LocationContentInset * 2)
        } else {
            lockFrame.size = CGSize(width: BrowserLocationViewUX.LocationContentInset, height: 0)
        }
        lockFrame.center = CGPoint(x: lockFrame.size.width / 2, y: centerY)

        var readerFrame = CGRect()
        readerFrame.origin = CGPointZero
        if !readerModeButton.hidden {
            readerFrame.size = self.readerModeButton.intrinsicContentSize()
            readerFrame.size.width += CGFloat(BrowserLocationViewUX.LocationContentInset * 2)
        } else {
            readerFrame.size = CGSize(width: BrowserLocationViewUX.LocationContentInset, height: 0)
        }
        readerFrame.center = CGPoint(x: self.frame.size.width - readerFrame.size.width / 2, y: centerY)

        var urlFrame = CGRect()
        urlFrame.origin = CGPoint(x: lockFrame.width, y: 0)
        urlFrame.size = CGSize(width: self.frame.size.width - lockFrame.size.width - readerFrame.size.width, height: self.frame.size.height)

        lockImageView.frame = lockFrame
        readerModeButton.frame = readerFrame
        urlTextField.frame = urlFrame
    }

    func SELtapReaderModeButton() {
        delegate?.browserLocationViewDidTapReaderMode(self)
    }

    func SELlongPressReaderModeButton(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            delegate?.browserLocationViewDidLongPressReaderMode(self)
        }
    }

    func SELlongPressLocation(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            delegate?.browserLocationViewDidLongPressLocation(self)
        }
    }

    func SELreaderModeCustomAction() -> Bool {
        return delegate?.browserLocationViewDidLongPressReaderMode(self) ?? false
    }

    private func updateTextWithURL() {
        if let httplessURL = url?.absoluteStringWithoutHTTPScheme(), let baseDomain = url?.baseDomain() {
            // Highlight the base domain of the current URL.
            var attributedString = NSMutableAttributedString(string: httplessURL)
            let nsRange = NSMakeRange(0, count(httplessURL))
            attributedString.addAttribute(NSForegroundColorAttributeName, value: BrowserLocationViewUX.BaseURLFontColor, range: nsRange)
            attributedString.colorSubstring(baseDomain, withColor: BrowserLocationViewUX.HostFontColor)
            attributedString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(double: BrowserLocationViewUX.BaseURLPitch), range: nsRange)
            attributedString.pitchSubstring(baseDomain, withPitch: BrowserLocationViewUX.HostPitch)
            urlTextField.attributedText = attributedString
        } else {
            // If we're unable to highlight the domain, just use the URL as is.
            urlTextField.text = url?.absoluteString
        }
    }
}

extension BrowserLocationView: UIGestureRecognizerDelegate {
    // Override the default UILongPressGestureRecognizer to suppress the text zoom magnifier.
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // Override the default UILongPressGestureRecognizer to suppress the text zoom magnifier.
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension BrowserLocationView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        delegate?.browserLocationViewDidTapLocation(self)
        return false
    }
}

extension BrowserLocationView: AccessibilityActionsSource {
    func accessibilityCustomActionsForView(view: UIView) -> [UIAccessibilityCustomAction]? {
        if view === urlTextField {
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
