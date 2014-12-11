/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol BrowserToolbarDelegate {
    func didClickBack()
    func didClickForward()
    func didEnterURL(url: NSURL)
}

class BrowserToolbar: UIToolbar, UITextFieldDelegate {
    var browserToolbarDelegate: BrowserToolbarDelegate?

    private var urlTextField: UITextField!

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
        let backButton = UIButton()
        backButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        backButton.setTitle("<", forState: UIControlState.Normal)
        backButton.addTarget(self, action: "SELdidClickBack", forControlEvents: UIControlEvents.TouchUpInside)
        let backButtonItem = UIBarButtonItem()
        backButtonItem.customView = backButton

        let forwardButton = UIButton()
        forwardButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        forwardButton.setTitle(">", forState: UIControlState.Normal)
        forwardButton.addTarget(self, action: "SELdidClickForward", forControlEvents: UIControlEvents.TouchUpInside)
        let forwardButtonItem = UIBarButtonItem()
        forwardButtonItem.customView = forwardButton

        urlTextField = ToolbarTextField()
        urlTextField.keyboardType = UIKeyboardType.URL
        urlTextField.autocorrectionType = UITextAutocorrectionType.No
        urlTextField.autocapitalizationType = UITextAutocapitalizationType.None
        urlTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        urlTextField.layer.cornerRadius = 8
        urlTextField.setContentHuggingPriority(0, forAxis: UILayoutConstraintAxis.Horizontal)
        urlTextField.delegate = self
        let urlButtonItem = UIBarButtonItem()
        urlButtonItem.customView = urlTextField

        let items = [forwardButtonItem, backButtonItem, urlButtonItem]
        setItems(items, animated: true)

        backButton.snp_makeConstraints { make in
            make.left.equalTo(self)
            make.centerY.equalTo(self)
            make.width.height.equalTo(44)
        }

        forwardButton.snp_makeConstraints { make in
            make.left.equalTo(backButton.snp_right)
            make.centerY.equalTo(self)
            make.width.height.equalTo(44)
        }

        urlTextField.snp_makeConstraints { make in
            make.left.equalTo(forwardButton.snp_right)
            make.centerY.equalTo(self)
            make.right.equalTo(self).offset(-8)
        }
    }

    func SELdidClickBack() {
        browserToolbarDelegate?.didClickBack()
    }

    func SELdidClickForward() {
        browserToolbarDelegate?.didClickForward()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let urlString = urlTextField.text
        let url = NSURL(string: urlString)

        if url == nil {
            println("Error parsing URL: " + urlString)
            return false
        }

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
