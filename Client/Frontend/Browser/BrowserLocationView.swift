/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol BrowserLocationViewDelegate {
    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapStop(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapReload(browserLocationView: BrowserLocationView)
}

let ImageReload = UIImage(named: "toolbar_reload.png")
let ImageStop = UIImage(named: "toolbar_stop.png")

class BrowserLocationView : UIView, UIGestureRecognizerDelegate {
    var delegate: BrowserLocationViewDelegate?

    private var lockImageView: UIImageView!
    private var locationLabel: UILabel!
    private var stopReloadButton: UIButton!
    private var readerModeButton: ReaderModeButton!
    var readerModeButtonWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.layer.cornerRadius = 3

        lockImageView = UIImageView(image: UIImage(named: "lock_verified.png"))
        lockImageView.hidden = false
        lockImageView.isAccessibilityElement = true
        lockImageView.accessibilityLabel = NSLocalizedString("Secure connection", comment: "")
        addSubview(lockImageView)

        locationLabel = UILabel()
        locationLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        locationLabel.lineBreakMode = .ByClipping
        locationLabel.userInteractionEnabled = true
        // TODO: This label isn't useful for people. We probably want this to be the page title or URL (see Safari).
        locationLabel.accessibilityLabel = NSLocalizedString("URL", comment: "Accessibility label")
        addSubview(locationLabel)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "SELtapLocationLabel:")
        locationLabel.addGestureRecognizer(tapGestureRecognizer)

        stopReloadButton = UIButton()
        stopReloadButton.setImage(ImageReload, forState: .Normal)
        stopReloadButton.addTarget(self, action: "SELtapStopReload", forControlEvents: .TouchUpInside)
        addSubview(stopReloadButton)

        readerModeButton = ReaderModeButton(frame: CGRectZero)
        readerModeButton.hidden = true
        readerModeButton.addTarget(self, action: "SELtapReaderModeButton", forControlEvents: .TouchUpInside)
        addSubview(readerModeButton)

        makeConstraints()
    }

    private func makeConstraints() {
        let container = self

        lockImageView.snp_remakeConstraints { make in
            make.centerY.equalTo(container).centerY
            make.leading.equalTo(container).with.offset(8)
            make.width.equalTo(self.lockImageView.intrinsicContentSize().width)
        }

        locationLabel.snp_remakeConstraints { make in
            make.centerY.equalTo(container.snp_centerY)
            if self.url?.scheme == "https" {
                make.leading.equalTo(self.lockImageView.snp_trailing).with.offset(8)
            } else {
                make.leading.equalTo(container).with.offset(8)
            }
            if self.readerModeButton.readerModeState == ReaderModeState.Unavailable {
                make.trailing.equalTo(self.stopReloadButton.snp_leading).with.offset(-8)
            } else {
                make.trailing.equalTo(self.readerModeButton.snp_leading).with.offset(-8)
            }
        }

        stopReloadButton.snp_remakeConstraints { make in
            make.centerY.equalTo(container).centerY
            make.trailing.equalTo(container).with.offset(-4)
            make.size.equalTo(20)
        }

        readerModeButton.snp_remakeConstraints { make in
            make.centerY.equalTo(container).centerY
            make.trailing.equalTo(self.stopReloadButton.snp_leading).offset(-4)

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

    func SELtapReaderModeButton() {
        delegate?.browserLocationViewDidTapReaderMode(self)
    }

    func SELtapStopReload() {
        if loading {
            delegate?.browserLocationViewDidTapStop(self)
        } else {
            delegate?.browserLocationViewDidTapReload(self)
        }
    }

    var url: NSURL? {
        didSet {
            lockImageView.hidden = (url?.scheme != "https")
            let t = url?.absoluteString
            if t?.hasPrefix("http://") ?? false {
                locationLabel.text = t!.substringFromIndex(advance(t!.startIndex, 7))
            } else if t?.hasPrefix("https://") ?? false {
                locationLabel.text = t!.substringFromIndex(advance(t!.startIndex, 8))
            } else if t == "about:home" {
                let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
                locationLabel.attributedText = NSAttributedString(string: placeholderText, attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
            } else {
                locationLabel.text = t
            }
            makeConstraints()
        }
    }

    var loading: Bool = false {
        didSet {
            if loading {
                stopReloadButton.setImage(ImageStop, forState: .Normal)
            } else {
                stopReloadButton.setImage(ImageReload, forState: .Normal)
            }
        }
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            if newReaderModeState != self.readerModeButton.readerModeState {
                self.readerModeButton.readerModeState = newReaderModeState
                makeConstraints()
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
