/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Snap

protocol URLBarDelegate: class {
    func urlBarDidPressTabs(urlBar: URLBarView)
    func urlBarDidPressReaderMode(urlBar: URLBarView)
    func urlBarDidPressStop(urlBar: URLBarView)
    func urlBarDidPressReload(urlBar: URLBarView)
    func urlBarDidBeginEditing(urlBar: URLBarView)
    func urlBarDidEndEditing(urlBar: URLBarView)
    func urlBar(urlBar: URLBarView, didEnterText text: String)
    func urlBar(urlBar: URLBarView, didSubmitText text: String)
}

class URLBarView: UIView, BrowserLocationViewDelegate, UITextFieldDelegate {
    weak var delegate: URLBarDelegate?

    private var locationView: BrowserLocationView!
    private var editTextField: ToolbarTextField!
    private var tabsButton: UIButton!
    private var progressBar: UIProgressView!
    private var cancelButton: UIButton!

    override init() {
        // super.init() calls init(frame: CGRect)
        super.init()
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

        editTextField = ToolbarTextField()
        editTextField.keyboardType = UIKeyboardType.WebSearch
        editTextField.autocorrectionType = UITextAutocorrectionType.No
        editTextField.autocapitalizationType = UITextAutocapitalizationType.None
        editTextField.returnKeyType = UIReturnKeyType.Go
        editTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        editTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        editTextField.layer.cornerRadius = 3
        editTextField.delegate = self
        editTextField.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        editTextField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")

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

        cancelButton = UIButton()
        cancelButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
        cancelButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        cancelButton.addTarget(self, action: "SELdidClickCancel", forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.hidden = true
        self.addSubview(cancelButton)

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

        cancelButton.snp_makeConstraints { make in
            make.centerY.equalTo(self).offset(StatusBarHeight/2.0)
            make.right.equalTo(self).offset(-8)
        }
    }

    func updateURL(url: NSURL?) {
        locationView.url = url
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
        delegate?.urlBarDidPressTabs(self)
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
        delegate?.urlBarDidPressReaderMode(self)
    }

    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidBeginEditing(self)

        insertSubview(editTextField, aboveSubview: locationView)
        editTextField.snp_remakeConstraints { make in
            make.edges.equalTo(self.locationView)
            return
        }
        editTextField.text = locationView.url?.absoluteString
        editTextField.becomeFirstResponder()

        updateVisibleViews(editing: true)
    }

    func browserLocationViewDidTapReload(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidPressReload(self)
    }
    
    func browserLocationViewDidTapStop(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidPressStop(self)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        delegate?.urlBar(self, didSubmitText: editTextField.text)
        return true
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString
        let fullText = text.stringByReplacingCharactersInRange(range, withString: string)
        delegate?.urlBar(self, didEnterText: fullText)

        return true
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        textField.selectAll(nil)
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        delegate?.urlBar(self, didEnterText: "")
        return true
    }

    func finishEditing() {
        editTextField.resignFirstResponder()
        updateVisibleViews(editing: false)
        delegate?.urlBarDidEndEditing(self)
    }

    private func updateVisibleViews(#editing: Bool) {
        locationView.hidden = editing
        tabsButton.hidden = editing
        progressBar.hidden = editing
        editTextField.hidden = !editing
        cancelButton.hidden = !editing
    }

    func SELdidClickCancel() {
        finishEditing()
    }

    override func accessibilityPerformEscape() -> Bool {
        self.SELdidClickCancel()
        return true
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
