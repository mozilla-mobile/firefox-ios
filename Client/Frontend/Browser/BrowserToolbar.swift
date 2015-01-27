/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Snappy

protocol BrowserToolbarDelegate {
    func didBeginEditing()
    func didClickBack()
    func didClickForward()
    func didClickAddTab()
    func didLongPressBack()
    func didLongPressForward()
    func didClickReaderMode()
    func didClickStop()
    func didClickReload()
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
        backButton.accessibilityLabel = NSLocalizedString("Back", comment: "")
        backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)
        longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack")
        backButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
        backButton.addGestureRecognizer(longPressGestureBackButton)
        self.addSubview(backButton)

        forwardButton = UIButton()
        forwardButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        forwardButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        forwardButton.setTitle(">", forState: UIControlState.Normal)
        forwardButton.accessibilityLabel = NSLocalizedString("Forward", comment: "")
        forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)
        longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward")
        forwardButton.accessibilityHint = NSLocalizedString("Double tap and hold to open history", comment: "")
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

    func updateURL(url: NSURL?) {
        if let url = url {
            locationView.url = url
        }
    }

    func updateTabCount(count: Int) {
        tabsButton.setTitle(count.description, forState: UIControlState.Normal)
        tabsButton.accessibilityValue = count.description
        tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "")
    }

    func updateBackStatus(canGoBack: Bool) {
        backButton.enabled = canGoBack
    }

    func updateFowardStatus(canGoForward: Bool) {
        forwardButton.enabled = canGoForward
    }

    func updateLoading(loading: Bool) {
        locationView.loading = loading
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

    func browserLocationViewDidTapReload(browserLocationView: BrowserLocationView) {
        browserToolbarDelegate?.didClickReload()
    }

    func browserLocationViewDidTapStop(browserLocationView: BrowserLocationView) {
        browserToolbarDelegate?.didClickStop()
    }
}
