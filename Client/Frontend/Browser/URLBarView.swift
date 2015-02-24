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
        editTextField.hidden = true

        progressBar = UIProgressView()
        self.progressBar.trackTintColor = self.backgroundColor
        self.addSubview(progressBar)

        tabsButton = UIButton()
        tabsButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        tabsButton.titleLabel?.layer.borderColor = UIColor.whiteColor().CGColor
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
        cancelButton.setTitleColor(UIColor.blackColor   (), forState: UIControlState.Normal)
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
            make.left.equalTo(self.locationView.snp_right).offset(8)
            make.centerY.equalTo(self).offset(StatusBarHeight/2.0)
            make.width.height.equalTo(ToolbarHeight)
            make.right.equalTo(self)
        }

        self.progressBar.snp_remakeConstraints { make in
            make.centerY.equalTo(self.snp_bottom)
            make.width.equalTo(self)
        }

        cancelButton.snp_makeConstraints { make in
            make.centerY.equalTo(self).offset(StatusBarHeight/2.0)
            make.right.equalTo(self).offset(-2)
        }
    }

    var isEditing: Bool {
        get {
            return !editTextField.hidden
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
        setNeedsLayout()
    }

    func SELdidClickCancel() {
        finishEditing()
    }

    override func accessibilityPerformEscape() -> Bool {
        self.SELdidClickCancel()
        return true
    }
}

/* Code for drawing the urlbar curve */
// Curve's aspect ratio
private let ASPECT_RATIO = 0.729

// Width multipliers
private let W_M1 = 0.343
private let W_M2 = 0.514
private let W_M3 = 0.49
private let W_M4 = 0.545
private let W_M5 = 0.723

// Height multipliers
private let H_M1 = 0.25
private let H_M2 = 0.5
private let H_M3 = 0.72
private let H_M4 = 0.961
extension URLBarView {
    func getWidthForHeight(height: Double) -> Double {
        return height * ASPECT_RATIO
    }

    func drawFromTop(path: UIBezierPath) {
        let height: Double = Double(ToolbarHeight)
        let width = getWidthForHeight(height)
        var from: (Double, Double) = (0, 0)

        if cancelButton.hidden {
            from = (Double(self.tabsButton.frame.origin.x) - width/2, Double(StatusBarHeight))
        } else {
            from = (Double(self.cancelButton.frame.origin.x + self.cancelButton.frame.width), Double(StatusBarHeight))
        }

        path.moveToPoint(CGPoint(x: from.0, y: from.1))
        path.addCurveToPoint(CGPoint(x: from.0 + width * W_M2, y: from.1 + height * H_M2),
            controlPoint1: CGPoint(x: from.0 + width * W_M1, y: from.1),
            controlPoint2: CGPoint(x: from.0 + width * W_M3, y: from.1 + height * H_M1))

        path.addCurveToPoint(CGPoint(x: from.0 + width,        y: from.1 + height),
            controlPoint1: CGPoint(x: from.0 + width * W_M4, y: from.1 + height * H_M3),
            controlPoint2: CGPoint(x: from.0 + width * W_M5, y: from.1 + height * H_M4))
    }

    private func getPath() -> UIBezierPath {
        let path = UIBezierPath()
        self.drawFromTop(path)
        path.addLineToPoint(CGPoint(x: self.frame.width, y: self.frame.height))
        path.addLineToPoint(CGPoint(x: self.frame.width, y: 0))
        path.addLineToPoint(CGPoint(x: 0, y: 0))
        path.addLineToPoint(CGPoint(x: 0, y: StatusBarHeight))
        path.closePath()
        return path
    }

    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let layer = layer as? CAShapeLayer {
            layer.path = self.getPath().CGPath
            layer.fillColor = UIColor.darkGrayColor().CGColor
        }
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
