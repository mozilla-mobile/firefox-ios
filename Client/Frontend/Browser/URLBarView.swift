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
    static let LocationLeftPadding = 5
    static let LocationHeight = 30
    static let TextFieldCornerRadius: CGFloat = 3
    static let TextFieldBorderWidth: CGFloat = 1
    // offset from edge of tabs button
    static let URLBarCurveOffset: CGFloat = 14
    // buffer so we dont see edges when animation overshoots with spring
    static let URLBarCurveBounceBuffer: CGFloat = 8

    static let TabsButtonRotationOffset: CGFloat = 1.5
    static let TabsButtonHeight: CGFloat = 18.0
}

protocol URLBarDelegate: class {
    func urlBarDidPressTabs(urlBar: URLBarView)
    func urlBarDidPressReaderMode(urlBar: URLBarView)
    func urlBarDidLongPressReaderMode(urlBar: URLBarView)
    func urlBarDidPressStop(urlBar: URLBarView)
    func urlBarDidPressReload(urlBar: URLBarView)
    func urlBarDidBeginEditing(urlBar: URLBarView)
    func urlBarDidEndEditing(urlBar: URLBarView)
    func urlBarDidLongPressLocation(urlBar: URLBarView)
    func urlBar(urlBar: URLBarView, didEnterText text: String)
    func urlBar(urlBar: URLBarView, didSubmitText text: String)
}

class URLBarView: UIView, BrowserLocationViewDelegate, AutocompleteTextFieldDelegate, BrowserToolbarProtocol {
    weak var delegate: URLBarDelegate?

    private var locationView: BrowserLocationView!
    private var editTextField: ToolbarTextField!
    private var locationContainer: UIView!
    private var tabsButton: UIButton!
    private var progressBar: UIProgressView!
    private var cancelButton: UIButton!
    private var curveShape: CurveView!

    weak var browserToolbarDelegate: BrowserToolbarDelegate?

    let shareButton = UIButton()
    let bookmarkButton = UIButton()
    let forwardButton = UIButton()
    let backButton = UIButton()
    let stopReloadButton = UIButton()
    var helper: BrowserToolbarHelper?
    var toolbarIsShowing = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initViews()
    }

    private func initViews() {
        curveShape = CurveView()
        self.addSubview(curveShape);

        locationContainer = UIView()
        locationContainer.setTranslatesAutoresizingMaskIntoConstraints(false)
        locationContainer.layer.borderColor = URLBarViewUX.TextFieldBorderColor.CGColor
        locationContainer.layer.cornerRadius = URLBarViewUX.TextFieldCornerRadius
        locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidth
        addSubview(locationContainer)

        locationView = BrowserLocationView(frame: CGRectZero)
        locationView.setTranslatesAutoresizingMaskIntoConstraints(false)
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
        editTextField.autocompleteDelegate = self
        editTextField.font = AppConstants.DefaultMediumFont
        editTextField.layer.cornerRadius = URLBarViewUX.TextFieldCornerRadius
        editTextField.layer.borderColor = URLBarViewUX.TextFieldActiveBorderColor.CGColor
        editTextField.hidden = true
        editTextField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
        locationContainer.addSubview(editTextField)

        self.progressBar = UIProgressView()
        self.progressBar.trackTintColor = self.backgroundColor
        self.progressBar.alpha = 0
        self.progressBar.hidden = true
        self.addSubview(progressBar)

        tabsButton = InsetButton()
        tabsButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        tabsButton.setTitleColor(URLBarViewUX.BackgroundColor, forState: UIControlState.Normal)
        tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility Label for the urlbar tabs button")
        tabsButton.titleLabel?.layer.backgroundColor = UIColor.whiteColor().CGColor
        tabsButton.titleLabel?.layer.cornerRadius = 2
        tabsButton.titleLabel?.font = AppConstants.DefaultSmallFontBold
        tabsButton.titleLabel?.textAlignment = NSTextAlignment.Center
        tabsButton.titleLabel?.layer.anchorPoint = CGPoint(x: 0.5, y: URLBarViewUX.TabsButtonRotationOffset)
        tabsButton.titleLabel?.snp_makeConstraints { make in
            make.size.equalTo(URLBarViewUX.TabsButtonHeight)
            return
        }
        tabsButton.addTarget(self, action: "SELdidClickAddTab", forControlEvents: UIControlEvents.TouchUpInside)
        tabsButton.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        tabsButton.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        self.addSubview(tabsButton)

        cancelButton = InsetButton()
        cancelButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        let cancelTitle = NSLocalizedString("Cancel", comment: "Button label to cancel entering a URL or search query")
        cancelButton.setTitle(cancelTitle, forState: UIControlState.Normal)
        cancelButton.titleLabel?.font = AppConstants.DefaultMediumFont
        cancelButton.addTarget(self, action: "SELdidClickCancel", forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.titleEdgeInsets = UIEdgeInsetsMake(10, 12, 10, 12)
        cancelButton.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        cancelButton.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        self.addSubview(cancelButton)

        addSubview(self.shareButton)
        addSubview(self.bookmarkButton)
        addSubview(self.forwardButton)
        addSubview(self.backButton)
        addSubview(self.stopReloadButton)

        self.helper = BrowserToolbarHelper(toolbar: self)

        // Make sure we hide any views that shouldn't be showing in non-editing mode
        finishEditingAnimation(false)
    }

    private func updateToolbarConstraints() {
        if toolbarIsShowing {
            backButton.snp_remakeConstraints { (make) -> () in
                make.left.bottom.equalTo(self)
                make.height.equalTo(AppConstants.ToolbarHeight)
                make.width.equalTo(AppConstants.ToolbarHeight)
            }
            backButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

            forwardButton.snp_remakeConstraints { (make) -> () in
                make.left.equalTo(self.backButton.snp_right)
                make.bottom.equalTo(self)
                make.height.equalTo(AppConstants.ToolbarHeight)
                make.width.equalTo(AppConstants.ToolbarHeight)
            }
            forwardButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

            stopReloadButton.snp_remakeConstraints { (make) -> () in
                make.left.equalTo(self.forwardButton.snp_right)
                make.bottom.equalTo(self)
                make.height.equalTo(AppConstants.ToolbarHeight)
                make.width.equalTo(AppConstants.ToolbarHeight)
            }
            stopReloadButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

            shareButton.snp_remakeConstraints { (make) -> () in
                make.right.equalTo(self.bookmarkButton.snp_left)
                make.bottom.equalTo(self)
                make.height.equalTo(AppConstants.ToolbarHeight)
                make.width.equalTo(AppConstants.ToolbarHeight)
            }
            shareButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

            bookmarkButton.snp_remakeConstraints { (make) -> () in
                make.right.equalTo(self.tabsButton.snp_left)
                make.bottom.equalTo(self)
                make.height.equalTo(AppConstants.ToolbarHeight)
                make.width.equalTo(AppConstants.ToolbarHeight)
            }
            bookmarkButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        }
    }

    override func updateConstraints() {
        updateToolbarConstraints()

        progressBar.snp_remakeConstraints { make in
            make.centerY.equalTo(self.snp_bottom)
            make.width.equalTo(self)
        }

        locationView.snp_remakeConstraints { make in
            make.edges.equalTo(self.locationContainer).insets(EdgeInsetsMake(URLBarViewUX.TextFieldBorderWidth,
                URLBarViewUX.TextFieldBorderWidth,
                URLBarViewUX.TextFieldBorderWidth,
                URLBarViewUX.TextFieldBorderWidth))
            return
        }

        tabsButton.snp_remakeConstraints { make in
            make.centerY.equalTo(self.locationContainer).offset((URLBarViewUX.TabsButtonRotationOffset - 0.5) * URLBarViewUX.TabsButtonHeight)
            make.trailing.equalTo(self)
            make.width.height.equalTo(AppConstants.ToolbarHeight)
        }

        editTextField.snp_remakeConstraints { make in
            make.edges.equalTo(self.locationContainer)
            return
        }

        cancelButton.snp_remakeConstraints { make in
            make.centerY.equalTo(self.locationContainer)
            make.trailing.equalTo(self)
        }

        // Add an offset to the left for slide animation, and a bit of extra offset for spring bounces
        let leftOffset = self.tabsButton.frame.width + URLBarViewUX.URLBarCurveOffset + URLBarViewUX.URLBarCurveBounceBuffer
        self.curveShape.snp_remakeConstraints { make in
            make.edges.equalTo(self).offset(EdgeInsetsMake(0, -leftOffset, 0, -URLBarViewUX.URLBarCurveBounceBuffer))
            return
        }

        updateLayoutForEditing(editing: isEditing, animated: false)
        super.updateConstraints()
    }

    var isEditing: Bool {
        get {
            return !editTextField.hidden
        }
    }

    func updateURL(url: NSURL?) {
        locationView.url = url
    }

    // Ideally we'd split this implementation in two, one URLBarView with a toolbar and one without
    // However, switching views dynamically at runtime is a difficult. For now, we just use one view
    // that can show in either mode.
    func setShowToolbar(shouldShow: Bool) {
        toolbarIsShowing = shouldShow
        setNeedsUpdateConstraints()
    }

    func currentURL() -> NSURL {
        return locationView.url!
    }

    func updateURLBarText(text: String) {
        delegate?.urlBarDidBeginEditing(self)

        editTextField.text = text
        editTextField.becomeFirstResponder()

        updateLayoutForEditing(editing: true)

        delegate?.urlBar(self, didEnterText: text)
    }

    func updateTabCount(count: Int) {

        // make a 'clone' of the tabs button
        let newTabsButton = InsetButton()
        newTabsButton.setTitleColor(URLBarViewUX.BackgroundColor, forState: UIControlState.Normal)
        newTabsButton.titleLabel?.layer.backgroundColor = UIColor.whiteColor().CGColor
        newTabsButton.titleLabel?.layer.cornerRadius = 2
        newTabsButton.titleLabel?.font = AppConstants.DefaultSmallFontBold
        newTabsButton.titleLabel?.textAlignment = NSTextAlignment.Center

        self.addSubview(newTabsButton)

        // copy constraints from original button for positioning
        newTabsButton.snp_makeConstraints { make in
            make.edges.equalTo(self.tabsButton)
        }

        newTabsButton.titleLabel?.snp_makeConstraints { make in
            make.size.equalTo(URLBarViewUX.TabsButtonHeight)
            return
        }

        if let anchor = tabsButton.titleLabel?.layer.anchorPoint {
            newTabsButton.titleLabel?.layer.anchorPoint = anchor
        }

        newTabsButton.setTitle(count.description, forState: .Normal)

        // setup the rotation matrix
        var flipTransform = CATransform3DIdentity
        flipTransform.m34 = -1.0 / 200.0 // add some perspective
        flipTransform = CATransform3DRotate(flipTransform, CGFloat(-M_PI_2), 1.0, 0.0, 0.0)
        newTabsButton.titleLabel?.layer.transform = flipTransform

        // offset the target rotation by 180º so the new tab comes from the front and the old tab falls back
        flipTransform = CATransform3DRotate(flipTransform, CGFloat(M_PI), 1.0, 0.0, 0.0)


        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { _ in
                newTabsButton.titleLabel?.layer.transform = CATransform3DIdentity
                self.tabsButton.titleLabel?.layer.transform = flipTransform
                self.tabsButton.alpha = 0
            }, completion: { _ in
                // remove the clone and setup the actual tab button
                newTabsButton.removeFromSuperview()
                self.tabsButton.alpha = 1
                self.tabsButton.titleLabel?.layer.transform = CATransform3DIdentity
                self.tabsButton.setTitle(count.description, forState: UIControlState.Normal)
                self.tabsButton.accessibilityValue = count.description
                self.tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the (top) browser toolbar")
        })
    }

    func SELdidClickAddTab() {
        delegate?.urlBarDidPressTabs(self)
    }

    func updateProgressBar(progress: Float) {
        if progress == 1.0 {
            self.progressBar.setProgress(progress, animated: true)
            UIView.animateWithDuration(1.5, animations: {
                self.progressBar.alpha = 0.0
            }, completion: { _ in
                self.progressBar.setProgress(0.0, animated: false)
            })
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

    func browserLocationViewDidLongPressReaderMode(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidLongPressReaderMode(self)
    }

    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidBeginEditing(self)

        editTextField.text = locationView.url?.absoluteString
        editTextField.becomeFirstResponder()

        updateLayoutForEditing(editing: true)
    }

    func browserLocationViewDidLongPressLocation(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidLongPressLocation(self)
    }

    func browserLocationViewDidTapReload(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidPressReload(self)
    }
    
    func browserLocationViewDidTapStop(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidPressStop(self)
    }

    func autocompleteTextFieldShouldReturn(autocompleteTextField: AutocompleteTextField) -> Bool {
        delegate?.urlBar(self, didSubmitText: editTextField.text)
        return true
    }

    func autocompleteTextField(autocompleteTextField: AutocompleteTextField, didTextChange text: String) {
        delegate?.urlBar(self, didEnterText: text)
    }

    func autocompleteTextFieldDidBeginEditing(autocompleteTextField: AutocompleteTextField) {
        // Without the async dispatch below, text selection doesn't work
        // intermittently and crashes on the iPhone 6 Plus (bug 1124310).
        dispatch_async(dispatch_get_main_queue(), {
            autocompleteTextField.selectedTextRange = autocompleteTextField.textRangeFromPosition(autocompleteTextField.beginningOfDocument, toPosition: autocompleteTextField.endOfDocument)
        })

        autocompleteTextField.layer.borderWidth = 1
        locationContainer.layer.shadowOpacity = 0
    }

    func autocompleteTextFieldDidEndEditing(autocompleteTextField: AutocompleteTextField) {
        locationContainer.layer.shadowOpacity = 0.05
        autocompleteTextField.layer.borderWidth = 0
    }

    func autocompleteTextFieldShouldClear(autocompleteTextField: AutocompleteTextField) -> Bool {
        delegate?.urlBar(self, didEnterText: "")
        return true
    }

    func setAutocompleteSuggestion(suggestion: String?) {
        editTextField.setAutocompleteSuggestion(suggestion)
    }

    func finishEditing() {
        editTextField.resignFirstResponder()
        updateLayoutForEditing(editing: false)
        delegate?.urlBarDidEndEditing(self)
    }

    func prepareEditingAnimation(editing: Bool) {
        // Make sure everything is showing during the transition (we'll hide it afterwards).
        self.progressBar.hidden = editing
        self.locationView.hidden = editing
        self.editTextField.hidden = !editing
        self.tabsButton.hidden = false
        self.cancelButton.hidden = false
        self.forwardButton.hidden = !self.toolbarIsShowing
        self.backButton.hidden = !self.toolbarIsShowing
        self.stopReloadButton.hidden = !self.toolbarIsShowing
        self.shareButton.hidden = !self.toolbarIsShowing
        self.bookmarkButton.hidden = !self.toolbarIsShowing

        // Update the location bar's size. If we're animating, we'll call layoutIfNeeded in the Animation
        // and transition to this.
        if editing {
            // In editing mode, we always show the location view full width
            self.locationContainer.snp_remakeConstraints { make in
                make.leading.equalTo(self).offset(URLBarViewUX.LocationLeftPadding)
                make.trailing.equalTo(self.cancelButton.snp_leading)
                make.height.equalTo(URLBarViewUX.LocationHeight)
                make.centerY.equalTo(self).offset(AppConstants.StatusBarHeight / 2)
            }
        } else {
            self.locationContainer.snp_remakeConstraints { make in
                if self.toolbarIsShowing {
                    // If we are showing a toolbar, show the text field next to the forward button
                    make.left.equalTo(self.stopReloadButton.snp_right)
                    make.right.equalTo(self.shareButton.snp_left)
                } else {
                    // Otherwise, left align the location view
                    make.leading.equalTo(self).offset(URLBarViewUX.LocationLeftPadding)
                    make.trailing.equalTo(self.tabsButton.snp_leading).offset(-14)
                }

                make.height.equalTo(URLBarViewUX.LocationHeight)

                make.centerY.equalTo(self).offset(AppConstants.StatusBarHeight / 2)
            }
        }
    }

    func transitionToEditing(editing: Bool) {
        self.cancelButton.alpha = editing ? 1 : 0
        self.shareButton.alpha = editing ? 0 : 1
        self.bookmarkButton.alpha = editing ? 0 : 1

        if editing {
            self.cancelButton.transform = CGAffineTransformIdentity
            self.tabsButton.transform = CGAffineTransformMakeTranslation(self.tabsButton.frame.width + URLBarViewUX.URLBarCurveOffset, 0)
            self.curveShape.transform = CGAffineTransformMakeTranslation(self.tabsButton.frame.width + URLBarViewUX.URLBarCurveOffset + URLBarViewUX.URLBarCurveBounceBuffer, 0)

            if self.toolbarIsShowing {
                self.forwardButton.transform = CGAffineTransformMakeTranslation(-3 * AppConstants.ToolbarHeight, 0)
                self.backButton.transform = CGAffineTransformMakeTranslation(-3 * AppConstants.ToolbarHeight, 0)
                self.stopReloadButton.transform = CGAffineTransformMakeTranslation(-3 * AppConstants.ToolbarHeight, 0)
            }
        } else {
            self.tabsButton.transform = CGAffineTransformIdentity
            self.cancelButton.transform = CGAffineTransformMakeTranslation(self.cancelButton.frame.width, 0)
            self.curveShape.transform = CGAffineTransformIdentity

            if self.toolbarIsShowing {
                self.forwardButton.transform = CGAffineTransformIdentity
                self.backButton.transform = CGAffineTransformIdentity
                self.stopReloadButton.transform = CGAffineTransformIdentity
            }
        }
    }

    func finishEditingAnimation(editing: Bool) {
        self.tabsButton.hidden = editing
        self.cancelButton.hidden = !editing
        self.forwardButton.hidden = !self.toolbarIsShowing || editing
        self.backButton.hidden = !self.toolbarIsShowing || editing
        self.shareButton.hidden = !self.toolbarIsShowing || editing
        self.bookmarkButton.hidden = !self.toolbarIsShowing || editing
        self.stopReloadButton.hidden = !self.toolbarIsShowing || editing
    }

    func updateLayoutForEditing(#editing: Bool, animated: Bool = true) {
        prepareEditingAnimation(editing)

        if animated {
            UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: nil, animations: { _ in
                self.transitionToEditing(editing)
                self.layoutIfNeeded()
            }, completion: { _ in
                self.finishEditingAnimation(editing)
            })
        } else {
            finishEditingAnimation(editing)
        }
    }

    func SELdidClickCancel() {
        finishEditing()
    }

    override func accessibilityPerformEscape() -> Bool {
        self.SELdidClickCancel()
        return true
    }

    /* BrowserToolbarProtocol */
    func updateBackStatus(canGoBack: Bool) {
        backButton.enabled = canGoBack
    }

    func updateFowardStatus(canGoForward: Bool) {
        forwardButton.enabled = canGoForward
    }

    func updateBookmarkStatus(isBookmarked: Bool) {
        bookmarkButton.selected = isBookmarked
    }

    func updateReloadStatus(isLoading: Bool) {
        if isLoading {
            stopReloadButton.setImage(helper?.ImageStop, forState: .Normal)
            stopReloadButton.setImage(helper?.ImageStopPressed, forState: .Highlighted)
        } else {
            stopReloadButton.setImage(helper?.ImageReload, forState: .Normal)
            stopReloadButton.setImage(helper?.ImageReloadPressed, forState: .Highlighted)
        }
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

/* Code for drawing the urlbar curve */
private class CurveView: UIView {

    func getWidthForHeight(height: Double) -> Double {
        return height * ASPECT_RATIO
    }

    func drawFromTop(path: UIBezierPath) {
        let height: Double = Double(AppConstants.ToolbarHeight)
        let width = getWidthForHeight(height)
        var from = (Double(self.frame.width) - width * 2 - Double(URLBarViewUX.URLBarCurveOffset - URLBarViewUX.URLBarCurveBounceBuffer), Double(AppConstants.StatusBarHeight))

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
        path.addLineToPoint(CGPoint(x: self.frame.width, y: AppConstants.ToolbarHeight + AppConstants.StatusBarHeight))
        path.addLineToPoint(CGPoint(x: self.frame.width, y: -10))
        path.addLineToPoint(CGPoint(x: 0, y: -10))
        path.addLineToPoint(CGPoint(x: 0, y: AppConstants.StatusBarHeight))
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

private class ToolbarTextField: AutocompleteTextField {
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.textRectForBounds(bounds)
        return rect.rectByInsetting(dx: 5, dy: 5)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.editingRectForBounds(bounds)
        return rect.rectByInsetting(dx: 5, dy: 5)
    }
}
