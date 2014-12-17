/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol BrowserToolbarDelegate {
    func didClickBack()
    func didClickForward()
    func didEnterURL(url: NSURL)
    func didClickAddTab()
}

class BrowserToolbar: UIView, LocationTextFieldDelegate {
    var browserToolbarDelegate: BrowserToolbarDelegate?

    private var forwardButton: UIButton!
    private var backButton: UIButton!
    private var toolbarTextField: LocationTextField!
    private var cancelButton: UIButton!
    private var tabsButton: UIButton!

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
        self.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        backButton = UIButton()
        backButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        backButton.setTitle("<", forState: UIControlState.Normal)
        backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)
        self.addSubview(backButton)

        forwardButton = UIButton()
        forwardButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        forwardButton.setTitle(">", forState: UIControlState.Normal)
        forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)
        self.addSubview(forwardButton)

        toolbarTextField = LocationTextField(frame: CGRectZero)
        toolbarTextField.keyboardType = UIKeyboardType.URL
        toolbarTextField.autocorrectionType = UITextAutocorrectionType.No
        toolbarTextField.autocapitalizationType = UITextAutocapitalizationType.None
        toolbarTextField.returnKeyType = UIReturnKeyType.Go
        toolbarTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        toolbarTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        toolbarTextField.layer.cornerRadius = 8
        toolbarTextField.setContentHuggingPriority(0, forAxis: UILayoutConstraintAxis.Horizontal)
        toolbarTextField.locationTextFieldDelegate = self
        self.addSubview(toolbarTextField)

        cancelButton = UIButton()
        cancelButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: "SELdidClickCancel", forControlEvents: UIControlEvents.TouchUpInside)
        self.addSubview(cancelButton)

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

        arrangeToolbar(editing: false)
    }

    func updateTabCount(count: Int) {
        tabsButton.setTitle(count.description, forState: UIControlState.Normal)
    }

    private func arrangeToolbar(#editing: Bool) {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            if editing {
                // These two buttons are off screen
                self.backButton.snp_remakeConstraints { make in
                    make.right.equalTo(self.forwardButton.snp_left)
                    make.centerY.equalTo(self)
                    make.width.height.equalTo(44)
                }
                
                self.forwardButton.snp_remakeConstraints { make in
                    make.right.equalTo(self.toolbarTextField.snp_left)
                    make.centerY.equalTo(self)
                    make.width.height.equalTo(44)
                }
                
                self.toolbarTextField.snp_remakeConstraints { make in
                    make.left.equalTo(self).offset(8)
                    make.centerY.equalTo(self)
                }

                self.cancelButton.snp_remakeConstraints { make in
                    make.left.equalTo(self.toolbarTextField.snp_right).offset(8)
                    make.centerY.equalTo(self)
                    make.right.equalTo(self).offset(-8)
                }

                // Tabs button is off the screen.
                self.tabsButton.snp_remakeConstraints { make in
                    make.left.equalTo(self.cancelButton.snp_right)
                    make.centerY.equalTo(self)
                    make.width.height.equalTo(44)
                }
            } else {
                self.backButton.snp_remakeConstraints { make in
                    make.left.equalTo(self)
                    make.centerY.equalTo(self)
                    make.width.height.equalTo(44)
                }
                
                self.forwardButton.snp_remakeConstraints { make in
                    make.left.equalTo(self.backButton.snp_right)
                    make.centerY.equalTo(self)
                    make.width.height.equalTo(44)
                }
                
                self.toolbarTextField.snp_remakeConstraints { make in
                    make.left.equalTo(self.forwardButton.snp_right)
                    make.centerY.equalTo(self)
                }

                self.tabsButton.snp_remakeConstraints { make in
                    make.left.equalTo(self.toolbarTextField.snp_right)
                    make.centerY.equalTo(self)
                    make.width.height.equalTo(44)
                    make.right.equalTo(self).offset(-8)
                }

                // The cancel button is off screen
                self.cancelButton.snp_remakeConstraints { make in
                    make.left.equalTo(self.tabsButton.snp_right).offset(8)
                    make.centerY.equalTo(self)
                }
            }
        })
    }
    
    func SELdidClickBack() {
        browserToolbarDelegate?.didClickBack()
    }

    func SELdidClickForward() {
        browserToolbarDelegate?.didClickForward()
    }

    func SELdidClickCancel() {
        // toolbarTextField.text = webView.location TODO Can't do this right now because we can't access the webview
        toolbarTextField.resignFirstResponder()
        arrangeToolbar(editing: false)
    }

    func SELdidClickAddTab() {
        browserToolbarDelegate?.didClickAddTab()
    }

    func locationTextFieldDidBeginEditing(locationTextField: LocationTextField) {
        arrangeToolbar(editing: true)
    }

    func locationTextFieldDidReturn(locationTextField: LocationTextField, url: NSURL) {
        arrangeToolbar(editing: false)
        locationTextField.resignFirstResponder()
        browserToolbarDelegate?.didEnterURL(url)
    }
    
    /// Suggest a completion based on a prefix. Currently this just has some predefined sites and this also only works for hostnames and is currently ignoring paths.
    /// TODO: Hook this up to our real data sources.

    func locationTextField(locationTextField: LocationTextField, completionForPrefix prefix: String) -> LocationSuggestion? {
        let MOCK_SUGGESTIONS = [
            "http://www.apple.com",
            "https://ask.mozilla.org",
            "http://apple.stackexchange.com",
            "http://www.wikipedia.org",
            "https://wiki.mozilla.org",
            "https://www.mozilla.org",
            "https://news.ycombinator.com",
            "https://bugzilla.mozilla.org",
            "http://www.reddit.com",
            "https://twitter.com",
            "https://mobile.twitter.com"
        ]

        // First try to find a match on full urls that include the scheme
        for s in MOCK_SUGGESTIONS {
            if s.hasPrefix(prefix) {
                return LocationSuggestion(location: s, url: NSURL(string: s)!)
            }
        }
        
        // Then, if the partial completion has no scheme, try to find a match on just the hostname
        if !prefix.hasPrefix("http://") && !prefix.hasPrefix("https://") {
            for s in MOCK_SUGGESTIONS {
                let url = NSURL(string: s)!
                if let host = url.host {
                    if host.hasPrefix(prefix) {
                        // If we directly match the host then we are done
                        return LocationSuggestion(location: host, url: url)
                    } else {
                        // If the host has a www. prefix, chop that off and see if we can match
                        if host.hasPrefix("www.") {
                            let partialHost = host.substringFromIndex(advance(host.startIndex, countElements("www.")))
                            if partialHost.hasPrefix(prefix) {
                                return LocationSuggestion(location: partialHost, url: url)
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
}
