/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Snappy

protocol BrowserLocationViewDelegate {
    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView)
    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView)
}

class ReaderModeButton: UIButton {
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

protocol BrowserToolbarDelegate {
    func didBeginEditing()
    func didClickBack()
    func didClickForward()
    func didClickAddTab()
    func didLongPressBack()
    func didLongPressForward()
    func didClickReaderMode()
}

class BrowserToolbar: UIView, UITextFieldDelegate, BrowserLocationViewDelegate {
    var browserToolbarDelegate: BrowserToolbarDelegate?

    private var forwardButton: UIButton!
    private var backButton: UIButton!
    private var locationView: BrowserLocationView!
    private var tabsButton: UIButton!
    private var progressBar: UIProgressView!

    private var longPressGestureBackButton: UILongPressGestureRecognizer!
    private var longPressGestureForwardButton: UILongPressGestureRecognizer!

    override init() {
        super.init()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        viewDidInit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewDidInit()
    }

    private func viewDidInit() {
        self.backgroundColor = UIColor(white: 0.80, alpha: 1.0)

        backButton = UIButton()
        backButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        backButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        backButton.setTitle("<", forState: UIControlState.Normal)
        backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)
        longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack")
        backButton.addGestureRecognizer(longPressGestureBackButton)
        self.addSubview(backButton)

        forwardButton = UIButton()
        forwardButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        forwardButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        forwardButton.setTitle(">", forState: UIControlState.Normal)
        forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)
        longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward")
        forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        self.addSubview(forwardButton)

        locationView = BrowserLocationView(frame: CGRectZero)
        locationView.readerModeState = ReaderModeState.Unavailable
        locationView.delegate = self
        addSubview(locationView)

        progressBar = UIProgressView()
        self.progressBar.trackTintColor = self.backgroundColor
        self.addSubview(progressBar)

        tabsButton = UIButton()
        tabsButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        tabsButton.titleLabel?.layer.borderColor = UIColor.blackColor().CGColor
        tabsButton.titleLabel?.layer.cornerRadius = 4
        tabsButton.titleLabel?.layer.borderWidth = 1
        tabsButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        tabsButton.titleLabel?.textAlignment = NSTextAlignment.Center
        tabsButton.titleLabel?.snp_makeConstraints { make in
            make.size.equalTo(24)
            return
        }
        tabsButton.addTarget(self, action: "SELdidClickAddTab", forControlEvents: UIControlEvents.TouchUpInside)
        self.addSubview(tabsButton)

        self.backButton.snp_remakeConstraints { make in
            make.left.equalTo(self)
            make.centerY.equalTo(self).offset(10)
            make.width.height.equalTo(44)
        }

        self.forwardButton.snp_remakeConstraints { make in
            make.left.equalTo(self.backButton.snp_right)
            make.centerY.equalTo(self).offset(10)
            make.width.height.equalTo(44)
        }

        self.locationView.snp_remakeConstraints { make in
            make.left.equalTo(self.forwardButton.snp_right)
            make.centerY.equalTo(self).offset(10)
        }

        self.tabsButton.snp_remakeConstraints { make in
            make.left.equalTo(self.locationView.snp_right)
            make.centerY.equalTo(self).offset(10)
            make.width.height.equalTo(44)
            make.right.equalTo(self).offset(-8)
        }

        self.progressBar.snp_remakeConstraints { make in
            make.centerY.equalTo(self.snp_bottom)
            make.width.equalTo(self)
        }
    }
    
    func currentURL() -> NSURL? {
        return locationView.url
    }
    
    func updateURL(url: NSURL?) {
        if let url = url {
            locationView.url = url
        }
    }

    func updateTabCount(count: Int) {
        tabsButton.setTitle(count.description, forState: UIControlState.Normal)
    }

    func updateBackStatus(canGoBack: Bool) {
        backButton.enabled = canGoBack
    }

    func updateFowardStatus(canGoForward: Bool) {
        forwardButton.enabled = canGoForward
    }

    func SELdidClickBack() {
        browserToolbarDelegate?.didClickBack()
    }

    func SELdidLongPressBack() {
        browserToolbarDelegate?.didLongPressBack()
    }

    func SELdidClickForward() {
        browserToolbarDelegate?.didClickForward()
    }

    func SELdidLongPressForward() {
        browserToolbarDelegate?.didLongPressForward()
    }

    func SELdidClickAddTab() {
        browserToolbarDelegate?.didClickAddTab()
    }

    func updateProgressBar(progress: Float) {
        //TODO: Float == Float ?
        if progress == 1.0 {
            self.progressBar.setProgress(progress, animated: true)
            UIView.animateWithDuration(1.5, animations: {self.progressBar.alpha = 0.0},
                completion: {_ in self.progressBar.setProgress(0.0, animated: false)})
        } else {
            self.progressBar.alpha = 1.0
            self.progressBar.setProgress(progress, animated: (progress > progressBar.progress))
        }
    }


    func updateReaderModeState(state: ReaderModeState) {
        locationView.readerModeState = state
    }

    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView) {
        browserToolbarDelegate?.didClickReaderMode()
    }

    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView) {
        browserToolbarDelegate?.didBeginEditing()
    }
}
