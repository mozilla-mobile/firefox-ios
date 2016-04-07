/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared

private struct URLBarViewUX {
    static let TextFieldBorderColor = UIColor(rgb: 0xBBBBBB)
    static let TextFieldActiveBorderColor = UIColor(rgb: 0x4A90E2)
    static let TextFieldContentInset = UIOffsetMake(9, 5)
    static let LocationLeftPadding = 5
    static let LocationHeight = 28
    static let LocationContentOffset: CGFloat = 8
    static let TextFieldCornerRadius: CGFloat = 3
    static let TextFieldBorderWidth: CGFloat = 1
    // offset from edge of tabs button
    static let URLBarCurveOffset: CGFloat = 14
    static let URLBarCurveOffsetLeft: CGFloat = -10
    // buffer so we dont see edges when animation overshoots with spring
    static let URLBarCurveBounceBuffer: CGFloat = 8
    static let ProgressTintColor = UIColor(red:1, green:0.32, blue:0, alpha:1)

    static let TabsButtonRotationOffset: CGFloat = 1.5
    static let TabsButtonHeight: CGFloat = 18.0
    static let ToolbarButtonInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.borderColor = UIConstants.PrivateModeLocationBorderColor
        theme.activeBorderColor = UIConstants.PrivateModePurple
        theme.tintColor = UIConstants.PrivateModePurple
        theme.textColor = UIColor.whiteColor()
        theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor
        theme.backgroundColor = UIColor(rgb: 0x595959)
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.borderColor = TextFieldBorderColor
        theme.activeBorderColor = TextFieldActiveBorderColor
        theme.tintColor = ProgressTintColor
        theme.textColor = UIColor.blackColor()
        theme.buttonTintColor = UIColor.darkGrayColor()
        theme.backgroundColor = UIColor.whiteColor()
        themes[Theme.NormalMode] = theme

        return themes
    }()

    static func backgroundColorWithAlpha(alpha: CGFloat) -> UIColor {
        return UIConstants.AppBackgroundColor.colorWithAlphaComponent(alpha)
    }
}

/// Implementation of existing URLBarView using new URLToolbar
class URLBarView_V2: UIView {
    private var _shareButton: ToolbarButton = .shareButton()
    private var _bookmarkButton: ToolbarButton = .bookmarkedButton()
    private var _forwardButton: ToolbarButton = .forwardButton()
    private var _backButton: ToolbarButton = .backButton()
    private var _stopReloadButton: ToolbarButton = .reloadButton()
    private var _tabsButton: ToolbarButton = .tabsButton()
    private var cancelButton: ToolbarButton = .cancelButton()

    var helper: BrowserToolbarHelper?
    var isTransitioning: Bool = false

    var locationTextField: ToolbarTextField {
        return addressContainer.locationTextField
    }

    var locationView: BrowserLocationView {
        return addressContainer.locationView
    }

    weak var delegate: URLBarDelegate?
    weak var browserToolbarDelegate: BrowserToolbarDelegate?

    private(set) var toolbarIsShowing: Bool = false
    private(set) var inOverlayMode: Bool = false

    // Constraints for animations in narrow layout
    private var tabButtonRightConstraint: Constraint?
    private var addressContainerRightConstaint: Constraint?

    // Constraints for animations in wide layout
    private var backButtonLeftConstraint: Constraint?
    private var shareLeftConstraint: Constraint?
    private var cancelLeftConstraint: Constraint?

    private lazy var leftToolbarButtons: [ToolbarButton] = {
        return [
            self._backButton,
            self._forwardButton,
            self._stopReloadButton
        ]
    }()

    private lazy var rightToolbarButtons: [ToolbarButton] = {
        return [
            self._shareButton,
            self._bookmarkButton
        ]
    }()

    private let curveBackgroundView = CurveBackgroundView()
    private let addressContainer = AddressSearchContainer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackColor()

        locationView.delegate = self
        locationTextField.autocompleteDelegate = self

        bindSelectors()

        addSubview(curveBackgroundView)

        addSubview(_tabsButton)
        addSubview(cancelButton)

        leftToolbarButtons.forEach(addSubview)
        rightToolbarButtons.forEach(addSubview)

        addSubview(addressContainer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindSelectors() {
        _shareButton.addTarget(self, action: #selector(URLBarView_V2.share), forControlEvents: .TouchUpInside)
        _bookmarkButton.addTarget(self, action: #selector(URLBarView_V2.bookmark), forControlEvents: .TouchUpInside)
        _forwardButton.addTarget(self, action: #selector(URLBarView_V2.goForward), forControlEvents: .TouchUpInside)
        _backButton.addTarget(self, action: #selector(URLBarView_V2.goBack), forControlEvents: .TouchUpInside)
        _stopReloadButton.addTarget(self, action: #selector(URLBarView_V2.stopOrReload), forControlEvents: .TouchUpInside)
        _tabsButton.addTarget(self, action: #selector(URLBarView_V2.goToTabs), forControlEvents: .TouchUpInside)

        cancelButton.addTarget(self, action: #selector(URLBarView_V2.cancel), forControlEvents: .TouchUpInside)
    }
}

// MARK: - Math for layouts/animations
extension URLBarView_V2 {
    // Calculations frequently used by layout/animation code
    private var leftButtonsIntrinsicWidth: CGFloat {
        return leftToolbarButtons.reduce(0) { return $0 + $1.intrinsicContentSize().width }
    }

    private var rightButtonsIntrinsicWidth: CGFloat {
        return rightToolbarButtons.reduce(0) { return $0 + $1.intrinsicContentSize().width }
    }

    private var tabInstrinsicWidth: CGFloat {
        return _tabsButton.intrinsicContentSize().width
    }

    private var overlayWideAddressOffset: CGFloat {
        return 0
    }

    private var normalWideAddressOffset: CGFloat {
        return 0
    }

    private var addressContainerMargin: CGFloat { return 8 }
}

// MARK: - Layout
extension URLBarView_V2 {
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollection.verticalSizeClass != .Compact && traitCollection.horizontalSizeClass != .Regular ?
            setupNarrowLayout() : setupWideLayout()
    }

    private func setupWideLayout() {
        _backButton.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)
            backButtonLeftConstraint = make.left.equalTo(self).offset(inOverlayMode ? -leftButtonsIntrinsicWidth : 0).constraint
            make.right.equalTo(_forwardButton.snp_left)
        }

        _forwardButton.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)
            make.right.equalTo(_stopReloadButton.snp_left)
        }

        _stopReloadButton.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)
            make.right.equalTo(addressContainer.snp_left).offset(-addressContainerMargin)
        }

        curveBackgroundView.snp_remakeConstraints { make in
            make.left.top.bottom.equalTo(self)
            make.right.equalTo(_tabsButton.snp_left)
        }

        _tabsButton.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)
            tabButtonRightConstraint = make.right.equalTo(self).offset(inOverlayMode ? tabInstrinsicWidth : 0).constraint
        }

        addressContainer.snp_remakeConstraints { make in
            make.centerY.equalTo(curveBackgroundView)
        }
        addressContainer.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)

        cancelButton.snp_remakeConstraints { make in
            self.cancelLeftConstraint = make.left.equalTo(addressContainer.snp_right).offset(2 * addressContainerMargin).constraint
            make.right.equalTo(curveBackgroundView).offset(-curveBackgroundView.curveEdgeWidth)
        }

        _shareButton.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)
            make.right.equalTo(_bookmarkButton.snp_left)
            self.shareLeftConstraint = make.left.equalTo(addressContainer.snp_right).offset(addressContainerMargin).constraint
        }

        _bookmarkButton.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)
            make.right.equalTo(curveBackgroundView.snp_right).offset(-curveBackgroundView.curveEdgeWidth)
        }

        if inOverlayMode {
            shareLeftConstraint?.deactivate()
        } else {
            cancelLeftConstraint?.deactivate()
        }

        cancelButton.alpha = inOverlayMode ? 1 : 0
        leftToolbarButtons.forEach { $0.alpha = 1 }
        rightToolbarButtons.forEach { $0.alpha = inOverlayMode ? 0 : 1 }
    }

    private func setupNarrowLayout() {
        curveBackgroundView.snp_remakeConstraints { make in
            make.left.top.bottom.equalTo(self)
            make.right.equalTo(_tabsButton.snp_left)
        }

        _tabsButton.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)
            tabButtonRightConstraint = make.right.equalTo(self).offset(inOverlayMode ? tabInstrinsicWidth : 0).constraint
        }

        cancelButton.snp_remakeConstraints { make in
            make.top.bottom.equalTo(self)
            make.right.equalTo(curveBackgroundView.snp_right).offset(-curveBackgroundView.curveEdgeWidth)
        }

        addressContainer.snp_remakeConstraints { make in
            make.centerY.equalTo(curveBackgroundView)
            make.left.equalTo(curveBackgroundView).offset(addressContainerMargin)
            addressContainerRightConstaint = make.right.equalTo(curveBackgroundView.snp_right).offset(
                inOverlayMode ?
                    -(self.cancelButton.frame.width + 2 * addressContainerMargin + self.curveBackgroundView.curveEdgeWidth) :
                    -curveBackgroundView.curveEdgeWidth
            ).constraint
        }
        addressContainer.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)

        cancelButton.alpha = 1
        leftToolbarButtons.forEach { $0.alpha = 0 }
        rightToolbarButtons.forEach { $0.alpha = 0 }
    }
}

// MARK: - Transition Animations
extension URLBarView_V2 {
    private func transitionSubviews(overlaying: Bool, animated: Bool = true) {
        traitCollection.verticalSizeClass != .Compact && traitCollection.horizontalSizeClass != .Regular ?
            transitionNarrowLayout(overlaying, animated: animated) :
            transitionWideLayout(overlaying, animated: animated)
    }

    private func transitionNarrowLayout(overlaying: Bool, animated: Bool = true) {
        let overlayAddressOffset =
            -(self.cancelButton.frame.width + 2 * addressContainerMargin + self.curveBackgroundView.curveEdgeWidth)
        layoutIfNeeded()
        let animation: () -> Void = {
            self.addressContainer.editing = overlaying
            self.addressContainerRightConstaint?.updateOffset(overlaying ? overlayAddressOffset : -self.curveBackgroundView.curveEdgeWidth)
            self.tabButtonRightConstraint?.updateOffset(overlaying ? self.tabInstrinsicWidth : 0)
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animateWithDuration(2, delay: 0, options: [.BeginFromCurrentState, .AllowUserInteraction], animations: animation, completion: nil)
        } else {
            animation()
        }
    }

    private func transitionWideLayout(overlaying: Bool, animated: Bool = true) {
        layoutIfNeeded()
        let animation: () -> Void = {
            self.addressContainer.editing = overlaying
            
            // Movement animations
            self.backButtonLeftConstraint?.updateOffset(overlaying ? -self.leftButtonsIntrinsicWidth : 0)
            self.tabButtonRightConstraint?.updateOffset(overlaying ? self.tabInstrinsicWidth : 0)
            self.addressContainerRightConstaint?.updateOffset(
                overlaying ? -self.overlayWideAddressOffset : -self.normalWideAddressOffset)

            if overlaying {
                self.shareLeftConstraint?.deactivate()
                self.cancelLeftConstraint?.activate()
            } else {
                self.shareLeftConstraint?.activate()
                self.cancelLeftConstraint?.deactivate()
            }

            self.cancelButton.alpha = overlaying ? 1 : 0

            // Alpha animations
            self.rightToolbarButtons.forEach { $0.alpha = overlaying ? 0 : 1 }
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animateWithDuration(2, delay: 0, options: .BeginFromCurrentState, animations: animation, completion: nil)
        } else {
            animation()
        }
    }
}

// MARK: - Selectors
extension URLBarView_V2 {
    func goBack() {
        browserToolbarDelegate?.browserToolbarDidPressBack(self, button: _backButton)
    }

    func goForward() {
        browserToolbarDelegate?.browserToolbarDidPressForward(self, button: _forwardButton)
    }

    func stopOrReload() {
        browserToolbarDelegate?.browserToolbarDidPressReload(self, button: _stopReloadButton)
    }

    func share() {
        browserToolbarDelegate?.browserToolbarDidPressShare(self, button: _shareButton)
    }

    func bookmark() {
        browserToolbarDelegate?.browserToolbarDidPressBookmark(self, button: _bookmarkButton)
    }

    func goToTabs() {
        delegate?.urlBarDidPressTabs(self)
    }

    func cancel() {
        leaveOverlayMode(didCancel: true)
    }
}

// MARK: - BrowserToolbarProtocol
extension URLBarView_V2: BrowserToolbarProtocol {
    var shareButton: UIButton { return _shareButton }
    var bookmarkButton: UIButton { return _bookmarkButton }
    var forwardButton: UIButton { return _forwardButton }
    var backButton: UIButton { return _backButton }
    var stopReloadButton: UIButton { return _stopReloadButton }

    var actionButtons: [UIButton] {
        return [
            self.shareButton,
            self.bookmarkButton,
            self.forwardButton,
            self.backButton,
            self.stopReloadButton
        ]
    }

    func updateBackStatus(canGoBack: Bool) {
        backButton.enabled = canGoBack
    }

    func updateForwardStatus(canGoForward: Bool) {
        forwardButton.enabled = canGoForward
    }

    func updateBookmarkStatus(isBookmarked: Bool) {
        bookmarkButton.selected = isBookmarked
    }

    func updateReloadStatus(isLoading: Bool) {
        if isLoading {
            stopReloadButton.setImage(UIImage.stopIcon(), forState: .Normal)
            stopReloadButton.setImage(UIImage.stopPressedIcon(), forState: .Highlighted)
        } else {
            stopReloadButton.setImage(UIImage.reloadIcon(), forState: .Normal)
            stopReloadButton.setImage(UIImage.reloadPressedIcon(), forState: .Highlighted)
        }
    }

    func updatePageStatus(isWebPage isWebPage: Bool) {
        bookmarkButton.enabled = isWebPage
        stopReloadButton.enabled = isWebPage
        shareButton.enabled = isWebPage
    }
}

// MARK: - BrowserLocationViewDelegate
extension URLBarView_V2: BrowserLocationViewDelegate {
    func browserLocationViewDidLongPressReaderMode(browserLocationView: BrowserLocationView) -> Bool {
        return delegate?.urlBarDidLongPressReaderMode(self) ?? false
    }

    func browserLocationViewDidTapLocation(browserLocationView: BrowserLocationView) {
        let locationText = delegate?.urlBarDisplayTextForURL(locationView.url)
        enterOverlayMode(locationText, pasted: false)
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

    func browserLocationViewDidTapReaderMode(browserLocationView: BrowserLocationView) {
        delegate?.urlBarDidPressReaderMode(self)
    }

    func browserLocationViewLocationAccessibilityActions(browserLocationView: BrowserLocationView) -> [UIAccessibilityCustomAction]? {
        return delegate?.urlBarLocationAccessibilityActions(self)
    }
}

// MARK: - AutocompleteTextFieldDelegate
extension URLBarView_V2: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldReturn(autocompleteTextField: AutocompleteTextField) -> Bool {
        guard let text = locationTextField.text else { return false }
        delegate?.urlBar(self, didSubmitText: text)
        return true
    }

    func autocompleteTextField(autocompleteTextField: AutocompleteTextField, didEnterText text: String) {
        delegate?.urlBar(self, didEnterText: text)
    }

    func autocompleteTextFieldDidBeginEditing(autocompleteTextField: AutocompleteTextField) {
        autocompleteTextField.highlightAll()
    }

    func autocompleteTextFieldShouldClear(autocompleteTextField: AutocompleteTextField) -> Bool {
        delegate?.urlBar(self, didEnterText: "")
        return true
    }
}

// MARK: - URLBarViewProtocol for URLBarView conformance
extension URLBarView_V2: URLBarViewProtocol {
    var view: UIView {
        return self
    }

    var locationBorderColor: UIColor {
        return addressContainer.locationBorderColor
    }

    var locationActiveBorderColor: UIColor {
        return addressContainer.locationActiveBorderColor
    }

    var currentURL: NSURL? {
        get {
            return locationView.url
        }
        set(newURL) {
            locationView.url = newURL
        }
    }

    func updateAlphaForSubviews(alpha: CGFloat) {
//        subviews.forEach { $0.alpha = alpha }
    }

    func updateTabCount(count: Int, animated: Bool) {
        (_tabsButton as? TabCountToolbarButton)?.setCount(count, animated: animated)
    }

    func updateProgressBar(progress: Float) {

    }

    func updateReaderModeState(state: ReaderModeState) {
        locationView.readerModeState = state
    }

    func setAutocompleteSuggestion(suggestion: String?) {
        locationTextField.setAutocompleteSuggestion(suggestion)
    }

    func setShowToolbar(shouldShow: Bool) {
        // Not needed since we use traitCollectionDidChange callback.
    }

    func enterOverlayMode(locationText: String?, pasted: Bool) {
        locationView.urlTextField.hidden = true
        locationTextField.hidden = false
        locationTextField.text = locationText
        locationTextField.highlightAll()
        locationTextField.becomeFirstResponder()
        inOverlayMode = true
        transitionSubviews(inOverlayMode)
        delegate?.urlBarDidEnterOverlayMode(self)
    }

    func leaveOverlayMode(didCancel cancel: Bool = false) {
        locationView.urlTextField.hidden = false
        locationTextField.hidden = true
        locationTextField.resignFirstResponder()
        inOverlayMode = false
        transitionSubviews(inOverlayMode)
        delegate?.urlBarDidLeaveOverlayMode(self)
    }

    func applyTheme(themeName: String) {
        // Delegate to subviews to apply their themes as well
        locationView.applyTheme(themeName)
        locationTextField.applyTheme(themeName)
        (_tabsButton as? TabCountToolbarButton)?.applyTheme(themeName)
        (cancelButton as? CancelToolbarButton)?.applyTheme(themeName)

        // Apply our own theme
        guard let theme = URLBarViewUX.Themes[themeName] else {
            return
        }

        addressContainer.locationBorderColor = theme.borderColor!
        addressContainer.locationActiveBorderColor = theme.activeBorderColor!
        curveBackgroundView.curveBackgroundColor = theme.backgroundColor!
//        progressBarTint = theme.tintColor
        leftToolbarButtons.forEach { $0.tintColor = theme.buttonTintColor }
        rightToolbarButtons.forEach { $0.tintColor = theme.buttonTintColor }
    }

    func SELdidClickCancel() {
        cancel()
    }
}

// MARK: Private View Subclasses

/// Address/search input field and associated subviews
private class AddressSearchContainer: UIView {
    private let locationViewHeight: CGFloat = 32

    private lazy var locationTextField: ToolbarTextField = {
        let locationTextField = ToolbarTextField()
        locationTextField.keyboardType = UIKeyboardType.WebSearch
        locationTextField.autocorrectionType = UITextAutocorrectionType.No
        locationTextField.autocapitalizationType = UITextAutocapitalizationType.None
        locationTextField.returnKeyType = UIReturnKeyType.Go
        locationTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        locationTextField.font = UIConstants.DefaultChromeFont
        locationTextField.accessibilityIdentifier = "address"
        locationTextField.accessibilityLabel = Strings.ChromeAddressAccessibilityLabel
        return locationTextField
    }()

    lazy var locationView: BrowserLocationView = {
        let locationView = BrowserLocationView()
        locationView.readerModeState = ReaderModeState.Unavailable
        return locationView
    }()

    var locationBorderColor: UIColor = URLBarViewUX.TextFieldBorderColor {
        didSet {
            if !editing {
                layer.borderColor = locationBorderColor.CGColor
            }
        }
    }

    var locationActiveBorderColor: UIColor = URLBarViewUX.TextFieldActiveBorderColor {
        didSet {
            if editing {
                layer.borderColor = locationActiveBorderColor.CGColor
            }
        }
    }

    var editing: Bool {
        get {
            return locationView.editing
        }
        set(value) {
            locationView.editing = value
            layer.borderColor = value ? locationActiveBorderColor.CGColor : locationBorderColor.CGColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        userInteractionEnabled = true
        backgroundColor = .whiteColor()

        layer.borderColor = URLBarViewUX.TextFieldBorderColor.CGColor
        layer.cornerRadius = URLBarViewUX.TextFieldCornerRadius
        layer.borderWidth = URLBarViewUX.TextFieldBorderWidth

        addSubview(locationView)
        addSubview(locationTextField)

        locationView.snp_makeConstraints { $0.edges.equalTo(self) }
        locationTextField.snp_makeConstraints { $0.edges.equalTo(locationView.urlTextField) }
        locationTextField.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        locationTextField.hidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 0, height: locationViewHeight)
    }
}

/// Firefox curved tab background view
private class CurveBackgroundView: UIView {
    let curveEdgeWidth: CGFloat = 32

    var curveBackgroundColor: UIColor = .whiteColor()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentMode = .Redraw
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        CGContextClearRect(context, rect)
        drawBackgroundCurveInsideRect(rect, context: context)
    }

    private func drawBackgroundCurveInsideRect(rect: CGRect, context: CGContext) {
        CGContextSaveGState(context)
        CGContextSetFillColorWithColor(context, curveBackgroundColor.CGColor)

        // Curve's aspect ratio
        let ASPECT_RATIO: CGFloat = 0.729

        // Width multipliers
        let W_M1: CGFloat = 0.343
        let W_M2: CGFloat = 0.514
        let W_M3: CGFloat = 0.49
        let W_M4: CGFloat = 0.545
        let W_M5: CGFloat = 0.723

        // Height multipliers
        let H_M1: CGFloat = 0.25
        let H_M2: CGFloat = 0.5
        let H_M3: CGFloat = 0.72
        let H_M4: CGFloat = 0.961

        let height = rect.height
        let width = rect.width
        let curveStart = CGPoint(x: width - curveEdgeWidth, y: 0)
        let curveWidth = height * ASPECT_RATIO

        let path = UIBezierPath()
        // Start from the bottom-left
        path.moveToPoint(CGPoint(x: 0, y: height))
        path.addLineToPoint(CGPoint(x: 0, y: 5))

        // Left curved corner
        path.addArcWithCenter(CGPoint(x: 5, y: 5), radius: 5, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI + M_PI_2), clockwise: true)
        path.addLineToPoint(CGPoint(x: width - 32, y: 0))

        // Add tab curve on the right side
        path.addCurveToPoint(CGPoint(x: curveStart.x + curveWidth * W_M2, y: curveStart.y + height * H_M2),
                             controlPoint1: CGPoint(x: curveStart.x + curveWidth * W_M1, y: curveStart.y),
                             controlPoint2: CGPoint(x: curveStart.x + curveWidth * W_M3, y: curveStart.y + height * H_M1))
        path.addCurveToPoint(CGPoint(x: curveStart.x + curveWidth, y: curveStart.y + height),
              controlPoint1: CGPoint(x: curveStart.x + curveWidth * W_M4, y: curveStart.y + height * H_M3),
              controlPoint2: CGPoint(x: curveStart.x + curveWidth * W_M5, y: curveStart.y + height * H_M4))
        path.addLineToPoint(CGPoint(x: width, y: height))
        path.closePath()

        CGContextAddPath(context, path.CGPath)
        CGContextFillPath(context)
        CGContextRestoreGState(context)
    }
}