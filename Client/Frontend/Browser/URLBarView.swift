/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import Snap

private struct URLBarViewUX {
    // The color shown behind the tabs count button, and underneath the (mostly transparent) status bar.
    static let BackgroundColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)
    static let TextFieldBorderColor = UIColor.blackColor().colorWithAlphaComponent(0.05)
    static let TextFieldActiveBorderColor = UIColor(rgb: 0x4A90E2)
    static let LocationLeftPadding = 8
    static let TextFieldCornerRadius: CGFloat = 3
    static let TextFieldBorderWidth: CGFloat = 1
}

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
    private var locationContainer: UIView!
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
        locationContainer = UIView()

        locationContainer.layer.borderColor = URLBarViewUX.TextFieldBorderColor.CGColor
        locationContainer.layer.cornerRadius = URLBarViewUX.TextFieldCornerRadius
        locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidth
        addSubview(locationContainer)

        locationView = BrowserLocationView(frame: CGRectZero)
        locationView.readerModeState = ReaderModeState.Unavailable
        locationView.delegate = self
        locationContainer.addSubview(locationView)

        editTextField = ToolbarTextField()
        editTextField.keyboardType = UIKeyboardType.WebSearch
        editTextField.autocorrectionType = UITextAutocorrectionType.No
        editTextField.autocapitalizationType = UITextAutocapitalizationType.None
        editTextField.returnKeyType = UIReturnKeyType.Go
        editTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        editTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        editTextField.delegate = self
        editTextField.font = UIFont(name: "HelveticaNeue", size: 13)
        editTextField.layer.cornerRadius = URLBarViewUX.TextFieldCornerRadius
        editTextField.layer.borderColor = URLBarViewUX.TextFieldActiveBorderColor.CGColor
        editTextField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
        locationContainer.addSubview(editTextField)

        progressBar = UIProgressView()
        self.progressBar.trackTintColor = self.backgroundColor
        self.addSubview(progressBar)

        tabsButton = InsetButton()
        tabsButton.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        tabsButton.titleLabel?.layer.backgroundColor = UIColor.whiteColor().CGColor
        tabsButton.titleLabel?.layer.cornerRadius = 2
        tabsButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 11)
        tabsButton.titleLabel?.textAlignment = NSTextAlignment.Center
        tabsButton.titleLabel?.snp_makeConstraints { make in
            make.size.equalTo(18)
            return
        }
        tabsButton.addTarget(self, action: "SELdidClickAddTab", forControlEvents: UIControlEvents.TouchUpInside)
        tabsButton.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        tabsButton.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        self.addSubview(tabsButton)

        cancelButton = InsetButton()
        cancelButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
        cancelButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 12)
        cancelButton.addTarget(self, action: "SELdidClickCancel", forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.titleEdgeInsets = UIEdgeInsetsMake(10, 12, 10, 12)
        cancelButton.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        cancelButton.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        self.addSubview(cancelButton)

        updateLayoutForEditing(editing: false)

        locationView.snp_makeConstraints { make in
            make.edges.equalTo(self.locationContainer).insets(EdgeInsetsMake(URLBarViewUX.TextFieldBorderWidth, URLBarViewUX.TextFieldBorderWidth, URLBarViewUX.TextFieldBorderWidth, URLBarViewUX.TextFieldBorderWidth))
            return
        }

        editTextField.snp_makeConstraints { make in
            make.edges.equalTo(self.locationContainer)
            return
        }

        progressBar.snp_makeConstraints { make in
            make.centerY.equalTo(self.snp_bottom)
            make.width.equalTo(self)
        }

        tabsButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.locationContainer)
            make.trailing.equalTo(self)
            make.width.height.equalTo(ToolbarHeight)
        }

        cancelButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.locationContainer)
            make.trailing.equalTo(self)
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
        tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the (top) browser toolbar")
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

        editTextField.text = locationView.url?.absoluteString
        editTextField.becomeFirstResponder()

        updateLayoutForEditing(editing: true)
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
        // Without the async dispatch below, text selection doesn't work
        // intermittently and crashes on the iPhone 6 Plus (bug 1124310).
        dispatch_async(dispatch_get_main_queue(), {
            textField.selectedTextRange = textField.textRangeFromPosition(textField.beginningOfDocument, toPosition: textField.endOfDocument)
        })

        textField.layer.borderWidth = 1
        locationContainer.layer.shadowOpacity = 0
    }

    func textFieldDidEndEditing(textField: UITextField) {
        locationContainer.layer.shadowOpacity = 0.05
        textField.layer.borderWidth = 0
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        delegate?.urlBar(self, didEnterText: "")
        return true
    }

    func finishEditing() {
        editTextField.resignFirstResponder()
        updateLayoutForEditing(editing: false)
        delegate?.urlBarDidEndEditing(self)
    }

    private func updateLayoutForEditing(#editing: Bool) {
        locationView.hidden = editing
        tabsButton.hidden = editing
        progressBar.hidden = editing
        editTextField.hidden = !editing
        cancelButton.hidden = !editing

        locationContainer.snp_remakeConstraints { make in
            make.leading.equalTo(self).offset(URLBarViewUX.LocationLeftPadding)
            make.centerY.equalTo(self).offset(StatusBarHeight / 2)

            if editing {
                make.trailing.equalTo(self.cancelButton.snp_leading)
            } else {
                // Additional offset is needed here to prevent overlapping the curve.
                make.trailing.equalTo(self.tabsButton.snp_leading).offset(-10)
            }
        }

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

        path.addCurveToPoint(CGPoint(x: from.0 + width, y: from.1 + height),
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
            layer.fillColor = URLBarViewUX.BackgroundColor.CGColor
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

/**
 * Button whose insets are included in its intrinsic size.
 */
private class InsetButton: UIButton {
    private override func intrinsicContentSize() -> CGSize {
        let size = super.intrinsicContentSize()
        return CGSizeMake(size.width + titleEdgeInsets.left + titleEdgeInsets.right,
            size.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
    }
}