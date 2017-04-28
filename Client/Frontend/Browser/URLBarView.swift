/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SnapKit
import XCGLogger

private let log = Logger.browserLogger

struct URLBarViewUX {
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
    // A larger offset is needed when viewing URL bar in overlay mode to get the corners right
    static let URLBarCurveOverlayOffset: CGFloat = 8
    static let URLBarMinimumOffsetToAnimate: CGFloat = 30
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
        theme.textColor = UIColor.white
        theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.borderColor = TextFieldBorderColor
        theme.activeBorderColor = TextFieldActiveBorderColor
        theme.tintColor = ProgressTintColor
        theme.textColor = UIColor.black
        theme.buttonTintColor = UIColor.darkGray
        themes[Theme.NormalMode] = theme

        return themes
    }()

    static func backgroundColorWithAlpha(_ alpha: CGFloat) -> UIColor {
        return UIConstants.AppBackgroundColor.withAlphaComponent(alpha)
    }
}

protocol URLBarDelegate: class {
    func urlBarDidPressTabs(_ urlBar: URLBarView)
    func urlBarDidPressReaderMode(_ urlBar: URLBarView)
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool
    func urlBarDidPressStop(_ urlBar: URLBarView)
    func urlBarDidPressReload(_ urlBar: URLBarView)
    func urlBarDidEnterOverlayMode(_ urlBar: URLBarView)
    func urlBarDidLeaveOverlayMode(_ urlBar: URLBarView)
    func urlBarDidLongPressLocation(_ urlBar: URLBarView)
    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]?
    func urlBarDidPressScrollToTop(_ urlBar: URLBarView)
    func urlBar(_ urlBar: URLBarView, didEnterText text: String)
    func urlBar(_ urlBar: URLBarView, didSubmitText text: String)
    func urlBarDisplayTextForURL(_ url: URL?) -> String?
}

class URLBarView: UIView {
    // Additional UIAppearance-configurable properties
    dynamic var locationBorderColor: UIColor = URLBarViewUX.TextFieldBorderColor {
        didSet {
            if !inOverlayMode {
                locationContainer.layer.borderColor = locationBorderColor.cgColor
            }
        }
    }
    dynamic var locationActiveBorderColor: UIColor = URLBarViewUX.TextFieldActiveBorderColor {
        didSet {
            if inOverlayMode {
                locationContainer.layer.borderColor = locationActiveBorderColor.cgColor
            }
        }
    }

    weak var delegate: URLBarDelegate?
    weak var tabToolbarDelegate: TabToolbarDelegate?
    var helper: TabToolbarHelper?
    var isTransitioning: Bool = false {
        didSet {
            if isTransitioning {
                // Cancel any pending/in-progress animations related to the progress bar
                self.progressBar.setProgress(1, animated: false)
                self.progressBar.alpha = 0.0
            }
        }
    }

    fileprivate var currentTheme: String = Theme.NormalMode

    var toolbarIsShowing = false
    var topTabsIsShowing = false {
        didSet {
            curveShape.isHidden = topTabsIsShowing
        }
    }

    fileprivate var locationTextField: ToolbarTextField?

    /// Overlay mode is the state where the lock/reader icons are hidden, the home panels are shown,
    /// and the Cancel button is visible (allowing the user to leave overlay mode). Overlay mode
    /// is *not* tied to the location text field's editing state; for instance, when selecting
    /// a panel, the first responder will be resigned, yet the overlay mode UI is still active.
    var inOverlayMode = false

    lazy var locationView: TabLocationView = {
        let locationView = TabLocationView()
        locationView.translatesAutoresizingMaskIntoConstraints = false
        locationView.readerModeState = ReaderModeState.unavailable
        locationView.delegate = self
        return locationView
    }()

    lazy var locationContainer: UIView = {
        let locationContainer = UIView()
        locationContainer.translatesAutoresizingMaskIntoConstraints = false

        // Enable clipping to apply the rounded edges to subviews.
        locationContainer.clipsToBounds = true

        locationContainer.layer.borderColor = self.locationBorderColor.cgColor
        locationContainer.layer.cornerRadius = URLBarViewUX.TextFieldCornerRadius
        locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidth

        return locationContainer
    }()

    fileprivate lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.addTarget(self, action: #selector(URLBarView.SELdidClickAddTab), for: UIControlEvents.touchUpInside)
        tabsButton.accessibilityIdentifier = "URLBarView.tabsButton"
        return tabsButton
    }()

    fileprivate lazy var progressBar: UIProgressView = {
        let progressBar = UIProgressView()
        progressBar.progressTintColor = URLBarViewUX.ProgressTintColor
        progressBar.alpha = 0
        progressBar.isHidden = true
        return progressBar
    }()

    fileprivate lazy var cancelButton: UIButton = {
        let cancelButton = InsetButton()
        cancelButton.setTitleColor(UIColor.black, for: UIControlState())
        let cancelTitle = NSLocalizedString("Cancel", comment: "Label for Cancel button")
        cancelButton.setTitle(cancelTitle, for: UIControlState())
        cancelButton.titleLabel?.font = UIConstants.DefaultChromeFont
        cancelButton.addTarget(self, action: #selector(URLBarView.SELdidClickCancel), for: UIControlEvents.touchUpInside)
        cancelButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        cancelButton.setContentHuggingPriority(1000, for: UILayoutConstraintAxis.horizontal)
        cancelButton.setContentCompressionResistancePriority(1000, for: UILayoutConstraintAxis.horizontal)
        cancelButton.alpha = 0
        return cancelButton
    }()

    fileprivate lazy var curveShape: CurveView = { return CurveView() }()

    fileprivate lazy var scrollToTopButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(URLBarView.SELtappedScrollToTopArea), for: UIControlEvents.touchUpInside)
        return button
    }()

    var shareButton: UIButton = UIButton()

    var menuButton: UIButton = UIButton()

    var bookmarkButton: UIButton = UIButton()

    var forwardButton: UIButton = UIButton()

    var backButton: UIButton = {
        let backButton = UIButton()
        backButton.accessibilityIdentifier = "URLBarView.backButton"
        return backButton
    }()

    var stopReloadButton: UIButton = UIButton()

    var homePageButton: UIButton = UIButton()

    lazy var actionButtons: [UIButton] = [self.shareButton, self.menuButton, self.forwardButton, self.backButton, self.stopReloadButton, self.homePageButton]

    fileprivate var rightBarConstraint: Constraint?
    fileprivate let defaultRightOffset: CGFloat = URLBarViewUX.URLBarCurveOffset - URLBarViewUX.URLBarCurveBounceBuffer

    var currentURL: URL? {
        get {
            return locationView.url as URL?
        }

        set(newURL) {
            locationView.url = newURL
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    fileprivate func commonInit() {
        backgroundColor = URLBarViewUX.backgroundColorWithAlpha(0)
        addSubview(curveShape)
        addSubview(scrollToTopButton)

        addSubview(progressBar)
        addSubview(tabsButton)
        addSubview(cancelButton)

        addSubview(shareButton)
        addSubview(menuButton)
        addSubview(homePageButton)
        addSubview(forwardButton)
        addSubview(backButton)
        addSubview(stopReloadButton)

        locationContainer.addSubview(locationView)
        addSubview(locationContainer)

        helper = TabToolbarHelper(toolbar: self)
        setupConstraints()

        // Make sure we hide any views that shouldn't be showing in non-overlay mode.
        updateViewsForOverlayModeAndToolbarChanges()
    }

    fileprivate func setupConstraints() {
        scrollToTopButton.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.right.equalTo(self.locationContainer)
        }

        progressBar.snp.makeConstraints { make in
            make.top.equalTo(self.snp.bottom)
            make.width.equalTo(self)
        }

        locationView.snp.makeConstraints { make in
            make.edges.equalTo(self.locationContainer)
        }

        cancelButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.locationContainer)
            make.trailing.equalTo(self)
        }

        tabsButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.locationContainer)
            make.trailing.equalTo(self)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }

        curveShape.snp.makeConstraints { make in
            make.top.left.bottom.equalTo(self)
            self.rightBarConstraint = make.right.equalTo(self).constraint
            self.rightBarConstraint?.update(offset: defaultRightOffset)
        }

        backButton.snp.makeConstraints { make in
            make.left.centerY.equalTo(self)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }

        forwardButton.snp.makeConstraints { make in
            make.left.equalTo(self.backButton.snp.right)
            make.centerY.equalTo(self)
            make.size.equalTo(backButton)
        }

        stopReloadButton.snp.makeConstraints { make in
            make.left.equalTo(self.forwardButton.snp.right)
            make.centerY.equalTo(self)
            make.size.equalTo(backButton)
        }

        shareButton.snp.makeConstraints { make in
            make.right.equalTo(self.menuButton.snp.left)
            make.centerY.equalTo(self)
            make.size.equalTo(backButton)
        }

        homePageButton.snp.makeConstraints { make in
            make.center.equalTo(shareButton)
            make.size.equalTo(shareButton)
        }

        menuButton.snp.makeConstraints { make in
            make.right.equalTo(self.tabsButton.snp.left).offset(URLBarViewUX.URLBarCurveOffsetLeft)
            make.centerY.equalTo(self)
            make.size.equalTo(backButton)
        }
    }

    override func updateConstraints() {
        super.updateConstraints()
        if inOverlayMode {
            // In overlay mode, we always show the location view full width
            self.locationContainer.snp.remakeConstraints { make in
                make.leading.equalTo(self).offset(URLBarViewUX.LocationLeftPadding)
                make.trailing.equalTo(self.cancelButton.snp.leading)
                make.height.equalTo(URLBarViewUX.LocationHeight)
                make.centerY.equalTo(self)
            }
        } else {
            if topTabsIsShowing {
                tabsButton.snp.remakeConstraints { make in
                    make.centerY.equalTo(self.locationContainer)
                    make.leading.equalTo(self.snp.trailing)
                    make.size.equalTo(UIConstants.ToolbarHeight)
                }
            } else {
                tabsButton.snp.remakeConstraints { make in
                    make.centerY.equalTo(self.locationContainer)
                    make.trailing.equalTo(self)
                    make.size.equalTo(UIConstants.ToolbarHeight)
                }
            }
            self.locationContainer.snp.remakeConstraints { make in
                if self.toolbarIsShowing {
                    // If we are showing a toolbar, show the text field next to the forward button
                    make.leading.equalTo(self.stopReloadButton.snp.trailing)
                    make.trailing.equalTo(self.shareButton.snp.leading)
                } else {
                    // Otherwise, left align the location view
                    make.leading.equalTo(self).offset(URLBarViewUX.LocationLeftPadding)
                    make.trailing.equalTo(self.tabsButton.snp.leading).offset(-14)
                }

                make.height.equalTo(URLBarViewUX.LocationHeight)
                make.centerY.equalTo(self)
            }
        }

    }

    func createLocationTextField() {
        guard locationTextField == nil else { return }

        locationTextField = ToolbarTextField()

        guard let locationTextField = locationTextField else { return }

        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        locationTextField.autocompleteDelegate = self
        locationTextField.keyboardType = UIKeyboardType.webSearch
        locationTextField.autocorrectionType = UITextAutocorrectionType.no
        locationTextField.autocapitalizationType = UITextAutocapitalizationType.none
        locationTextField.returnKeyType = UIReturnKeyType.go
        locationTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        locationTextField.font = UIConstants.DefaultChromeFont
        locationTextField.accessibilityIdentifier = "address"
        locationTextField.accessibilityLabel = NSLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
        locationTextField.attributedPlaceholder = self.locationView.placeholder

        locationContainer.addSubview(locationTextField)

        locationTextField.snp.makeConstraints { make in
            make.edges.equalTo(self.locationView.urlTextField)
        }

        locationTextField.applyTheme(currentTheme)
    }

    func removeLocationTextField() {
        locationTextField?.removeFromSuperview()
        locationTextField = nil
    }

    // Ideally we'd split this implementation in two, one URLBarView with a toolbar and one without
    // However, switching views dynamically at runtime is a difficult. For now, we just use one view
    // that can show in either mode.
    func setShowToolbar(_ shouldShow: Bool) {
        toolbarIsShowing = shouldShow
        setNeedsUpdateConstraints()
        // when we transition from portrait to landscape, calling this here causes
        // the constraints to be calculated too early and there are constraint errors
        if !toolbarIsShowing {
            updateConstraintsIfNeeded()
        }
        updateViewsForOverlayModeAndToolbarChanges()
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        self.tabsButton.alpha = alpha
        self.locationContainer.alpha = alpha
        self.backgroundColor = URLBarViewUX.backgroundColorWithAlpha(1 - alpha)
        self.actionButtons.forEach { $0.alpha = alpha }
    }

    func updateTabCount(_ count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }

    func updateProgressBar(_ progress: Float) {
        if progress == 1.0 {
            self.progressBar.setProgress(progress, animated: !isTransitioning)
            UIView.animate(withDuration: 1.5, animations: {
                self.progressBar.alpha = 0.0
            })
        } else {
            if self.progressBar.alpha < 1.0 {
                self.progressBar.alpha = 1.0
            }
            self.progressBar.setProgress(progress, animated: (progress > progressBar.progress) && !isTransitioning)
        }
    }

    func updateReaderModeState(_ state: ReaderModeState) {
        locationView.readerModeState = state
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        locationTextField?.setAutocompleteSuggestion(suggestion)
    }

    func enterOverlayMode(_ locationText: String?, pasted: Bool) {
        createLocationTextField()

        // Show the overlay mode UI, which includes hiding the locationView and replacing it
        // with the editable locationTextField.
        animateToOverlayState(overlayMode: true)

        delegate?.urlBarDidEnterOverlayMode(self)

        // Bug 1193755 Workaround - Calling becomeFirstResponder before the animation happens
        // won't take the initial frame of the label into consideration, which makes the label
        // look squished at the start of the animation and expand to be correct. As a workaround,
        // we becomeFirstResponder as the next event on UI thread, so the animation starts before we
        // set a first responder.
        if pasted {
            // Clear any existing text, focus the field, then set the actual pasted text.
            // This avoids highlighting all of the text.
            self.locationTextField?.text = ""
            DispatchQueue.main.async {
                self.locationTextField?.becomeFirstResponder()
                self.locationTextField?.text = locationText
            }
        } else {
            // Copy the current URL to the editable text field, then activate it.
            self.locationTextField?.text = locationText
            DispatchQueue.main.async {
                self.locationTextField?.becomeFirstResponder()
            }
        }
    }

    func leaveOverlayMode(didCancel cancel: Bool = false) {
        locationTextField?.resignFirstResponder()
        animateToOverlayState(overlayMode: false, didCancel: cancel)
        delegate?.urlBarDidLeaveOverlayMode(self)
    }

    func prepareOverlayAnimation() {
        // Make sure everything is showing during the transition (we'll hide it afterwards).
        self.bringSubview(toFront: self.locationContainer)
        self.cancelButton.isHidden = false
        self.progressBar.isHidden = false
        self.menuButton.isHidden = !self.toolbarIsShowing
        self.forwardButton.isHidden = !self.toolbarIsShowing
        self.backButton.isHidden = !self.toolbarIsShowing
        self.stopReloadButton.isHidden = !self.toolbarIsShowing
        self.homePageButton.isHidden = !self.toolbarIsShowing
    }

    func transitionToOverlay(_ didCancel: Bool = false) {
        self.cancelButton.alpha = inOverlayMode ? 1 : 0
        self.progressBar.alpha = inOverlayMode || didCancel ? 0 : 1
        self.shareButton.alpha = inOverlayMode ? 0 : 1
        self.menuButton.alpha = inOverlayMode ? 0 : 1
        self.forwardButton.alpha = inOverlayMode ? 0 : 1
        self.backButton.alpha = inOverlayMode ? 0 : 1
        self.stopReloadButton.alpha = inOverlayMode ? 0 : 1
        self.homePageButton.alpha = inOverlayMode ? 0 : 1

        let borderColor = inOverlayMode ? locationActiveBorderColor : locationBorderColor
        locationContainer.layer.borderColor = borderColor.cgColor

        if inOverlayMode {
            self.cancelButton.transform = CGAffineTransform.identity
            let tabsButtonTransform = CGAffineTransform(translationX: self.tabsButton.frame.width + URLBarViewUX.URLBarCurveOffset, y: 0)
            self.tabsButton.transform = tabsButtonTransform
            self.rightBarConstraint?.update(offset: URLBarViewUX.URLBarCurveOffset + URLBarViewUX.URLBarCurveBounceBuffer + tabsButton.frame.width)

            // Make the editable text field span the entire URL bar, covering the lock and reader icons.
            self.locationTextField?.snp.remakeConstraints { make in
                make.leading.equalTo(self.locationContainer).offset(URLBarViewUX.LocationContentOffset)
                make.top.bottom.trailing.equalTo(self.locationContainer)
            }
        } else {
            self.tabsButton.transform = CGAffineTransform.identity
            self.cancelButton.transform = CGAffineTransform(translationX: self.cancelButton.frame.width, y: 0)
            self.rightBarConstraint?.update(offset: defaultRightOffset)

            // Shrink the editable text field back to the size of the location view before hiding it.
            self.locationTextField?.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationView.urlTextField)
            }
        }
    }

    func updateViewsForOverlayModeAndToolbarChanges() {
        self.cancelButton.isHidden = !inOverlayMode
        self.progressBar.isHidden = inOverlayMode
        self.menuButton.isHidden = !self.toolbarIsShowing || inOverlayMode
        self.forwardButton.isHidden = !self.toolbarIsShowing || inOverlayMode
        self.backButton.isHidden = !self.toolbarIsShowing || inOverlayMode
        self.stopReloadButton.isHidden = !self.toolbarIsShowing || inOverlayMode
        self.tabsButton.isHidden = self.topTabsIsShowing
    }

    func animateToOverlayState(overlayMode overlay: Bool, didCancel cancel: Bool = false) {
        prepareOverlayAnimation()
        layoutIfNeeded()

        inOverlayMode = overlay

        if !overlay {
            removeLocationTextField()
        }

        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: [], animations: { _ in
            self.transitionToOverlay(cancel)
            self.setNeedsUpdateConstraints()
            self.layoutIfNeeded()
        }, completion: { _ in
            self.updateViewsForOverlayModeAndToolbarChanges()
        })
    }

    func SELdidClickAddTab() {
        delegate?.urlBarDidPressTabs(self)
    }

    func SELdidClickCancel() {
        leaveOverlayMode(didCancel: true)
    }

    func SELtappedScrollToTopArea() {
        delegate?.urlBarDidPressScrollToTop(self)
    }
}

extension URLBarView: TabToolbarProtocol {
    func updateBackStatus(_ canGoBack: Bool) {
        backButton.isEnabled = canGoBack
    }

    func updateForwardStatus(_ canGoForward: Bool) {
        forwardButton.isEnabled = canGoForward
    }

    func updateBookmarkStatus(_ isBookmarked: Bool) {
        bookmarkButton.isSelected = isBookmarked
    }

    func updateReloadStatus(_ isLoading: Bool) {
        helper?.updateReloadStatus(isLoading)
        if isLoading {
            stopReloadButton.setImage(helper?.ImageStop, for: .normal)
            stopReloadButton.setImage(helper?.ImageStopPressed, for: .highlighted)
        } else {
            stopReloadButton.setImage(helper?.ImageReload, for: .normal)
            stopReloadButton.setImage(helper?.ImageReloadPressed, for: .highlighted)
        }
    }

    func updatePageStatus(_ isWebPage: Bool) {
        stopReloadButton.isEnabled = isWebPage
        shareButton.isEnabled = isWebPage
    }

    var access: [Any]? {
        get {
            if inOverlayMode {
                guard let locationTextField = locationTextField else { return nil }
                return [locationTextField, cancelButton]
            } else {
                if toolbarIsShowing {
                    return [backButton, forwardButton, stopReloadButton, locationView, shareButton, menuButton, tabsButton, progressBar]
                } else {
                    return [locationView, tabsButton, progressBar]
                }
            }
        }
        set {
            super.accessibilityElements = newValue
        }
    }
}

extension URLBarView: TabLocationViewDelegate {
    func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool {
        return delegate?.urlBarDidLongPressReaderMode(self) ?? false
    }

    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView) {
        var locationText = delegate?.urlBarDisplayTextForURL(locationView.url as URL?)

        // Make sure to use the result from urlBarDisplayTextForURL as it is responsible for extracting out search terms when on a search page
        if let text = locationText, let url = URL(string: text), let host = url.host, AppConstants.MOZ_PUNYCODE {
            locationText = url.absoluteString.replacingOccurrences(of: host, with: host.asciiHostToUTF8())
        }
        enterOverlayMode(locationText, pasted: false)
    }

    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidLongPressLocation(self)
    }

    func tabLocationViewDidTapReload(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidPressReload(self)
    }
    
    func tabLocationViewDidTapStop(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidPressStop(self)
    }

    func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidPressReaderMode(self)
    }

    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]? {
        return delegate?.urlBarLocationAccessibilityActions(self)
    }
}

extension URLBarView: AutocompleteTextFieldDelegate {
    func autocompleteTextFieldShouldReturn(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        guard let text = locationTextField?.text else { return true }
        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
            delegate?.urlBar(self, didSubmitText: text)
            return true
        } else {
            return false
        }
    }

    func autocompleteTextField(_ autocompleteTextField: AutocompleteTextField, didEnterText text: String) {
        delegate?.urlBar(self, didEnterText: text)
    }

    func autocompleteTextFieldDidBeginEditing(_ autocompleteTextField: AutocompleteTextField) {
        autocompleteTextField.highlightAll()
    }

    func autocompleteTextFieldShouldClear(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        delegate?.urlBar(self, didEnterText: "")
        return true
    }
}

// MARK: UIAppearance
extension URLBarView {
    dynamic var progressBarTint: UIColor? {
        get { return progressBar.progressTintColor }
        set { progressBar.progressTintColor = newValue }
    }

    dynamic var cancelTextColor: UIColor? {
        get { return cancelButton.titleColor(for: UIControlState()) }
        set { return cancelButton.setTitleColor(newValue, for: UIControlState()) }
    }

    dynamic var actionButtonTintColor: UIColor? {
        get { return helper?.buttonTintColor }
        set {
            guard let value = newValue else { return }
            helper?.buttonTintColor = value
        }
    }

}

extension URLBarView: Themeable {
    
    func applyTheme(_ themeName: String) {
        locationView.applyTheme(themeName)
        locationTextField?.applyTheme(themeName)

        guard let theme = URLBarViewUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        currentTheme = themeName
        locationBorderColor = theme.borderColor!
        locationActiveBorderColor = theme.activeBorderColor!
        progressBarTint = theme.tintColor
        cancelTextColor = theme.textColor
        actionButtonTintColor = theme.buttonTintColor

        tabsButton.applyTheme(themeName)
    }
}

extension URLBarView: AppStateDelegate {
    func appDidUpdateState(_ appState: AppState) {
        if toolbarIsShowing {
            let showShareButton = HomePageAccessors.isButtonInMenu(appState)
            homePageButton.isHidden = showShareButton
            shareButton.isHidden = !showShareButton || inOverlayMode
            homePageButton.isEnabled = HomePageAccessors.isButtonEnabled(appState)
        } else {
            homePageButton.isHidden = true
            shareButton.isHidden = true
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
    fileprivate lazy var leftCurvePath: UIBezierPath = {
        var leftArc = UIBezierPath(arcCenter: CGPoint(x: 5, y: 5), radius: CGFloat(5), startAngle: CGFloat(-Double.pi), endAngle: CGFloat(-(Double.pi / 2)), clockwise: true)
        leftArc.addLine(to: CGPoint(x: 0, y: 0))
        leftArc.addLine(to: CGPoint(x: 0, y: 5))
        leftArc.close()
        return leftArc
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    fileprivate func commonInit() {
        self.isOpaque = false
        self.contentMode = .redraw
    }

    fileprivate func getWidthForHeight(_ height: Double) -> Double {
        return height * ASPECT_RATIO
    }

    fileprivate func drawFromTop(_ path: UIBezierPath) {
        let height: Double = Double(UIConstants.ToolbarHeight)
        let width = getWidthForHeight(height)
        let from = (Double(self.frame.width) - width * 2 - Double(URLBarViewUX.URLBarCurveOffset - URLBarViewUX.URLBarCurveBounceBuffer), Double(0))

        path.move(to: CGPoint(x: from.0, y: from.1))
        path.addCurve(to: CGPoint(x: from.0 + width * W_M2, y: from.1 + height * H_M2),
              controlPoint1: CGPoint(x: from.0 + width * W_M1, y: from.1),
              controlPoint2: CGPoint(x: from.0 + width * W_M3, y: from.1 + height * H_M1))

        path.addCurve(to: CGPoint(x: from.0 + width, y: from.1 + height),
              controlPoint1: CGPoint(x: from.0 + width * W_M4, y: from.1 + height * H_M3),
              controlPoint2: CGPoint(x: from.0 + width * W_M5, y: from.1 + height * H_M4))
    }

    fileprivate func getPath() -> UIBezierPath {
        let path = UIBezierPath()
        self.drawFromTop(path)
        path.addLine(to: CGPoint(x: self.frame.width, y: UIConstants.ToolbarHeight))
        path.addLine(to: CGPoint(x: self.frame.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.close()
        return path
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.clear(rect)
        context.setFillColor(URLBarViewUX.backgroundColorWithAlpha(1).cgColor)
        getPath().fill()
        leftCurvePath.fill()
        context.drawPath(using: CGPathDrawingMode.fill)
        context.restoreGState()
    }
}

class ToolbarTextField: AutocompleteTextField {
    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.backgroundColor = UIConstants.PrivateModeLocationBackgroundColor
        theme.textColor = UIColor.white
        theme.buttonTintColor = UIColor.white
        theme.highlightColor = UIConstants.PrivateModeInputHighlightColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.backgroundColor = UIColor.white
        theme.textColor = UIColor.black
        theme.highlightColor = AutocompleteTextFieldUX.HighlightColor
        themes[Theme.NormalMode] = theme

        return themes
    }()

    dynamic var clearButtonTintColor: UIColor? {
        didSet {
            // Clear previous tinted image that's cache and ask for a relayout
            tintedClearImage = nil
            setNeedsLayout()
        }
    }

    fileprivate var tintedClearImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Since we're unable to change the tint color of the clear image, we need to iterate through the
        // subviews, find the clear button, and tint it ourselves. Thanks to Mikael Hellman for the tip:
        // http://stackoverflow.com/questions/27944781/how-to-change-the-tint-color-of-the-clear-button-on-a-uitextfield
        for view in subviews as [UIView] {
            if let button = view as? UIButton {
                if let image = button.image(for: UIControlState()) {
                    if tintedClearImage == nil {
                        tintedClearImage = tintImage(image, color: clearButtonTintColor)
                    }

                    if button.imageView?.image != tintedClearImage {
                        button.setImage(tintedClearImage, for: UIControlState())
                    }
                }
            }
        }
    }

    fileprivate func tintImage(_ image: UIImage, color: UIColor?) -> UIImage {
        guard let color = color else { return image }

        let size = image.size

        UIGraphicsBeginImageContextWithOptions(size, false, 2)
        let context = UIGraphicsGetCurrentContext()!
        image.draw(at: CGPoint.zero, blendMode: CGBlendMode.normal, alpha: 1.0)

        context.setFillColor(color.cgColor)
        context.setBlendMode(CGBlendMode.sourceIn)
        context.setAlpha(1.0)

        let rect = CGRect(
            x: CGPoint.zero.x,
            y: CGPoint.zero.y,
            width: image.size.width,
            height: image.size.height)
        context.fill(rect)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return tintedImage
    }
}

extension ToolbarTextField: Themeable {
    func applyTheme(_ themeName: String) {
        guard let theme = ToolbarTextField.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        backgroundColor = theme.backgroundColor
        textColor = theme.textColor
        clearButtonTintColor = theme.buttonTintColor
        highlightColor = theme.highlightColor!
    }
}
