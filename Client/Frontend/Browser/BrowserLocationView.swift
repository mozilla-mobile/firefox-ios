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

class BrowserLocationView : UIView, UIGestureRecognizerDelegate {
    var delegate: BrowserLocationViewDelegate?

    private var lockImageView: UIImageView!
    private var locationLabel: UILabel!
    private var readerModeButton: ReaderModeButton!
    var readerModeButtonWidthConstraint: NSLayoutConstraint?

    static var PlaceholderText: NSAttributedString {
        let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
        return NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.layer.cornerRadius = 2

        lockImageView = UIImageView(image: UIImage(named: "lock_verified.png"))
        lockImageView.hidden = false
        lockImageView.isAccessibilityElement = true
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
        addSubview(lockImageView)

        locationLabel = UILabel()
        locationLabel.font = AppConstants.DefaultMediumFont
        locationLabel.lineBreakMode = .ByClipping
        locationLabel.userInteractionEnabled = true
        locationLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        locationLabel.accessibilityIdentifier = "url"
        locationLabel.accessibilityTraits |= UIAccessibilityTraitButton
        addSubview(locationLabel)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "SELtapLocationLabel:")
        locationLabel.addGestureRecognizer(tapGestureRecognizer)

        // Long press gesture recognizer (for URL bar copying/pasting without entering editing mode)
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "SELlongPressLocationLabel:")
        locationLabel.addGestureRecognizer(longPressGestureRecognizer)

        readerModeButton = ReaderModeButton(frame: CGRectZero)
        readerModeButton.hidden = true
        readerModeButton.addTarget(self, action: "SELtapReaderModeButton", forControlEvents: .TouchUpInside)
        readerModeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "SELlongPressReaderModeButton:"))
        addSubview(readerModeButton)
        readerModeButton.isAccessibilityElement = true
        readerModeButton.accessibilityLabel = NSLocalizedString("Reader Mode", comment: "Accessibility label for the reader mode button")

        accessibilityElements = [lockImageView, locationLabel, readerModeButton]
    }

    override func updateConstraints() {
        super.updateConstraints()

        let container = self

        lockImageView.snp_remakeConstraints { make in
            make.centerY.equalTo(container)
            make.leading.equalTo(container).offset(8)
            make.width.equalTo(self.lockImageView.intrinsicContentSize().width)
        }

        locationLabel.snp_remakeConstraints { make in
            make.centerY.equalTo(container.snp_centerY)
            if self.url?.scheme == "https" {
                make.leading.equalTo(self.lockImageView.snp_trailing).offset(8)
            } else {
                make.leading.equalTo(container).offset(8)
            }

            if self.readerModeButton.readerModeState == ReaderModeState.Unavailable {
                make.trailing.equalTo(self).offset(-8)
            } else {
                make.trailing.equalTo(self.readerModeButton.snp_leading).offset(-8)
            }
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

    func SELtapLocationLabel(recognizer: UITapGestureRecognizer) {
        delegate?.browserLocationViewDidTapLocation(self)
    }

    func SELlongPressLocationLabel(recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.Began) {
            delegate?.browserLocationViewDidLongPressLocation(self)
        }
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
            lockImageView.hidden = (url?.scheme != "https")
            if let url = url?.absoluteString {
                if url.hasPrefix("http://") ?? false {
                    locationLabel.text = url.substringFromIndex(advance(url.startIndex, 7))
                } else if url.hasPrefix("https://") ?? false {
                    locationLabel.text = url.substringFromIndex(advance(url.startIndex, 8))
                } else {
                    locationLabel.text = url
                }
            } else {
                locationLabel.attributedText = BrowserLocationView.PlaceholderText
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

    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        // We only care about the horizontal position of this touch. Find the first
        // subview that takes up that space and return it.
        for view in subviews {
            let x1 = view.frame.origin.x
            let x2 = x1 + view.frame.width
            if point.x >= x1 && point.x <= x2 {
                return view as? UIView
            }
        }

        return nil
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
