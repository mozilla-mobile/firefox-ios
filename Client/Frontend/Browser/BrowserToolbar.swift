/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol BrowserToolbarDelegate {
    func didBeginEditing()
    func didClickBack()
    func didClickForward()
    func didEnterURL(url: NSURL)
    func didClickAddTab()
    func didLongPressBack()
    func didLongPressForward()
}

class BrowserToolbar: UIView, UITextFieldDelegate {
    var browserToolbarDelegate: BrowserToolbarDelegate?

    private var forwardButton: UIButton!
    private var backButton: UIButton!
    private var toolbarTextField: ToolbarTextField!
    private var cancelButton: UIButton!
    private var tabsButton: UIButton!
    
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
        self.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        backButton = UIButton()
        backButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        backButton.setTitle("<", forState: UIControlState.Normal)
        backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)
        longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressBack")
        backButton.addGestureRecognizer(longPressGestureBackButton)
        self.addSubview(backButton)

        forwardButton = UIButton()
        forwardButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        forwardButton.setTitle(">", forState: UIControlState.Normal)
        forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)
        longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: "SELdidLongPressForward")
        forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        self.addSubview(forwardButton)

        toolbarTextField = ToolbarTextField()
        toolbarTextField.keyboardType = UIKeyboardType.URL
        toolbarTextField.autocorrectionType = UITextAutocorrectionType.No
        toolbarTextField.autocapitalizationType = UITextAutocapitalizationType.None
        toolbarTextField.returnKeyType = UIReturnKeyType.Go
        toolbarTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        toolbarTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        toolbarTextField.layer.cornerRadius = 8
        toolbarTextField.setContentHuggingPriority(0, forAxis: UILayoutConstraintAxis.Horizontal)
        toolbarTextField.delegate = self
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
    
    func updateURL(url: NSURL?) {
        toolbarTextField.text = url?.absoluteString
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
    
    func SELdidLongPressBack() {
        browserToolbarDelegate?.didLongPressBack()
    }

    func SELdidClickForward() {
        browserToolbarDelegate?.didClickForward()
    }
    
    func SELdidLongPressForward() {
        browserToolbarDelegate?.didLongPressForward()
    }

    func SELdidClickCancel() {
        // toolbarTextField.text = webView.location TODO Can't do this right now because we can't access the webview
        toolbarTextField.resignFirstResponder()
        arrangeToolbar(editing: false)
    }

    func SELdidClickAddTab() {
        browserToolbarDelegate?.didClickAddTab()
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        browserToolbarDelegate?.didBeginEditing()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let urlString = toolbarTextField.text
        
        // If the URL is missing a scheme then parse then we manually prefix it with http:// and try
        // again. We can probably do some smarter things here but I think this is a
        // decent start that at least lets people skip typing the protocol.
        
        var url = NSURL(string: urlString)
        if url == nil || url?.scheme == nil {
            url = NSURL(string: "http://" + urlString)
            if url == nil {
                println("Error parsing URL: " + urlString)
                return false
            }
        }

        arrangeToolbar(editing: false)

        textField.resignFirstResponder()
        browserToolbarDelegate?.didEnterURL(url!)
        return false
    }
}

private class ToolbarTextField: UITextField {
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.textRectForBounds(bounds)
        return rect.rectByInsetting(dx: 5, dy: 5)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.editingRectForBounds(bounds)
        return rect.rectByInsetting(dx: 5, dy: 5)
    }
}