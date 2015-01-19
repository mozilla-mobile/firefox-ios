/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol BrowserLocationViewDelegate {
    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView)
}

class BrowserLocationView : UIView, UIGestureRecognizerDelegate {
    var delegate: BrowserLocationViewDelegate?

    private var lockImageView: UIImageView!
    private var locationLabel: UILabel!
    private var readerModeButton: ReaderModeButton!
    var readerModeButtonWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.clipsToBounds = true
        self.layer.cornerRadius = 5

        lockImageView = UIImageView(image: UIImage(named: "lock_verified.png"))
        lockImageView.hidden = false
        addSubview(lockImageView)

        locationLabel = UILabel()
        locationLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        locationLabel.lineBreakMode = NSLineBreakMode.ByClipping
        locationLabel.userInteractionEnabled = true
        addSubview(locationLabel)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "SELtapLocationLabel:")
        locationLabel.addGestureRecognizer(tapGestureRecognizer)

        readerModeButton = ReaderModeButton(frame: CGRectZero)
        readerModeButton.hidden = true
        readerModeButton.addTarget(self, action: "SELtapReaderModeButton", forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(readerModeButton)

        makeConstraints()
    }

    private func makeConstraints() {
        let container = self
        let padding = UIEdgeInsetsMake(4, 8, 4, 8)

        lockImageView.snp_remakeConstraints { make in
            make.centerY.equalTo(container).centerY
            make.left.equalTo(container.snp_left).with.offset(8)
            make.width.equalTo(self.lockImageView.intrinsicContentSize().width)
        }

        locationLabel.snp_remakeConstraints { make in
            make.centerY.equalTo(container.snp_centerY)
            if self.url?.scheme == "https" {
                make.left.equalTo(self.lockImageView.snp_right).with.offset(8)
            } else {
                make.left.equalTo(container.snp_left).with.offset(8)
            }
            if self.readerModeButton.readerModeState == ReaderModeState.Unavailable {
                make.right.equalTo(container.snp_right).with.offset(-8)
            } else {
                make.right.equalTo(self.readerModeButton.snp_left).with.offset(-4)
            }
        }

        readerModeButton.snp_remakeConstraints { make in
            make.centerY.equalTo(container).centerY
            make.right.equalTo(container.snp_right).with.offset(-4)
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

    var _url: NSURL?
    var url: NSURL? {
        get {
            return _url
        }
        set (newURL) {
            _url = newURL
            lockImageView.hidden = (_url?.scheme != "https")
            if let t = _url?.absoluteString {
                if t.hasPrefix("http://") {
                    locationLabel.text = t.substringFromIndex(advance(t.startIndex, 7))
                } else if t.hasPrefix("https://") {
                    locationLabel.text = t.substringFromIndex(advance(t.startIndex, 8))
                } else {
                    locationLabel.text = t
                }
            }
            makeConstraints()
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
}
