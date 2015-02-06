/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Snappy

protocol UrlBarDelegate {
    func didBeginEditing()
    func didClickAddTab()
    func didClickReaderMode()
    func didClickStop()
    func didClickReload()
}

class URLBarView: UIView, UITextFieldDelegate, BrowserLocationViewDelegate {
    var delegate: UrlBarDelegate?

    private var locationView: BrowserLocationView!
    private var tabsButton: UIButton!
    private var progressBar: UIProgressView!

    override init() {
        super.init()
        initViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initViews()
    }

    private func initViews() {
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

        self.locationView.snp_remakeConstraints { make in
            make.left.equalTo(self.snp_left).offset(DefaultPadding)
            make.centerY.equalTo(self).offset(StatusBarHeight/2.0)
        }

        self.tabsButton.snp_remakeConstraints { make in
            make.left.equalTo(self.locationView.snp_right)
            make.centerY.equalTo(self).offset(StatusBarHeight/2.0)
            make.width.height.equalTo(ToolbarHeight)
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

    func updateLoading(loading: Bool) {
        locationView.loading = loading
    }

    func SELdidClickAddTab() {
        delegate?.didClickAddTab()
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
        delegate?.didClickReaderMode()
    }

    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView) {
        delegate?.didBeginEditing()
    }

    func browserLocationViewDidTapReload(browserLocationView: BrowserLocationView) {
        delegate?.didClickReload()
    }
    
    func browserLocationViewDidTapStop(browserLocationView: BrowserLocationView) {
        delegate?.didClickStop()
    }
}
