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
    static let TextFieldActiveBorderColor = UIColor(rgb: 0xB0D5FB)
    static let LocationLeftPadding: CGFloat = 8
    static let Padding: CGFloat = 10
    static let LocationHeight: CGFloat = 40
    static let ButtonHeight: CGFloat = 44
    static let LocationContentOffset: CGFloat = 8
    static let TextFieldCornerRadius: CGFloat = 8
    static let TextFieldBorderWidth: CGFloat = 1
    static let TextFieldBorderWidthSelected: CGFloat = 4
    // offset from edge of tabs button
    static let ProgressTintColor = UIColor(rgb: 0x00dcfc)
    static let ProgressBarHeight: CGFloat = 3

    static let TabsButtonRotationOffset: CGFloat = 1.5
    static let TabsButtonHeight: CGFloat = 18.0
    static let ToolbarButtonInsets = UIEdgeInsets(top: Padding, left: Padding, bottom: Padding, right: Padding)

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.borderColor = UIColor(rgb: 0x2D2D31)
        theme.backgroundColor = UIColor(rgb: 0x38383D)
        theme.activeBorderColor = UIColor(rgb: 0x4a4a4f)
        theme.tintColor = UIColor(rgb: 0xf9f9fa)
        theme.textColor = UIColor(rgb: 0xf9f9fa)
        theme.buttonTintColor = UIColor(rgb: 0xD2d2d4)
        theme.disabledButtonColor = UIColor.gray
        theme.highlightButtonColor = UIColor(rgb: 0xAC39FF)
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.borderColor =  UIColor(rgb: 0x737373).withAlphaComponent(0.3)
        theme.activeBorderColor = TextFieldActiveBorderColor
        theme.disabledButtonColor = UIColor.lightGray
        theme.highlightButtonColor = UIColor(rgb: 0x00A2FE)
        theme.tintColor = ProgressTintColor
        theme.textColor = UIColor(rgb: 0x272727)
        theme.backgroundColor = UIConstants.AppBackgroundColor
        theme.buttonTintColor = UIColor(rgb: 0x272727)
        themes[Theme.NormalMode] = theme

        return themes
    }()
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
    func urlBarDidPressQRButton(_ urlBar: URLBarView)
    func urlBarDidPressPageOptions(_ urlBar: URLBarView, from button: UIButton)
    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]?
    func urlBarDidPressScrollToTop(_ urlBar: URLBarView)
    func urlBar(_ urlBar: URLBarView, didEnterText text: String)
    func urlBar(_ urlBar: URLBarView, didSubmitText text: String)
    // Returns either (search query, true) or (url, false).
    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool)
    func urlBarDidLongPressPageOptions(_ urlBar: URLBarView, from button: UIButton)
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
    var topTabsIsShowing = false

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
        let locationContainer = TabLocationContainerView()
        locationContainer.translatesAutoresizingMaskIntoConstraints = false
        locationContainer.layer.shadowColor = self.locationBorderColor.cgColor
        locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidth
        locationContainer.layer.borderColor = self.locationBorderColor.cgColor
        locationContainer.backgroundColor = .clear
        return locationContainer
    }()
    
    let line = UIView()

    lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.accessibilityIdentifier = "URLBarView.tabsButton"
        return tabsButton
    }()

    fileprivate lazy var progressBar: GradientProgressBar = {
        let progressBar = GradientProgressBar()
        progressBar.clipsToBounds = false
        return progressBar
    }()

    fileprivate lazy var cancelButton: UIButton = {
        let cancelButton = InsetButton()
        cancelButton.setImage(UIImage.templateImageNamed("goBack"), for: .normal)
        cancelButton.accessibilityIdentifier = "urlBar-cancel"
        cancelButton.addTarget(self, action: #selector(URLBarView.SELdidClickCancel), for: .touchUpInside)
        cancelButton.alpha = 0
        return cancelButton
    }()
    
    fileprivate lazy var showQRScannerButton: InsetButton = {
        let button = InsetButton()
        button.setImage(UIImage.templateImageNamed("menu-ScanQRCode"), for: .normal)
        button.accessibilityIdentifier = "urlBar-scanQRCode"
        button.clipsToBounds = false
        button.addTarget(self, action: #selector(URLBarView.showQRScanner), for: .touchUpInside)
        button.setContentHuggingPriority(1000, for: UILayoutConstraintAxis.horizontal)
        button.setContentCompressionResistancePriority(1000, for: UILayoutConstraintAxis.horizontal)
        return button
    }()

    fileprivate lazy var scrollToTopButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(URLBarView.SELtappedScrollToTopArea), for: .touchUpInside)
        return button
    }()

    var menuButton = ToolbarButton()
    var bookmarkButton = ToolbarButton()
    var forwardButton = ToolbarButton()
    var stopReloadButton = ToolbarButton()

    var backButton: ToolbarButton = {
        let backButton = ToolbarButton()
        backButton.accessibilityIdentifier = "URLBarView.backButton"
        return backButton
    }()

    lazy var actionButtons: [Themeable & UIButton] = [self.tabsButton, self.menuButton, self.forwardButton, self.backButton, self.stopReloadButton]

    var currentURL: URL? {
        get {
            return locationView.url as URL?
        }

        set(newURL) {
            locationView.url = newURL
            line.isHidden = newURL?.isAboutHomeURL ?? true
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
        locationContainer.addSubview(locationView)
    
        [scrollToTopButton, line, tabsButton, progressBar, cancelButton, showQRScannerButton].forEach { addSubview($0) }
        [menuButton, forwardButton, backButton, stopReloadButton, locationContainer].forEach { addSubview($0) }
        
        helper = TabToolbarHelper(toolbar: self)
        setupConstraints()

        // Make sure we hide any views that shouldn't be showing in non-overlay mode.
        updateViewsForOverlayModeAndToolbarChanges()
    }

    fileprivate func setupConstraints() {
        
        line.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalTo(self)
            make.height.equalTo(1)
        }
        
        scrollToTopButton.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.right.equalTo(self.locationContainer)
        }

        progressBar.snp.makeConstraints { make in
            make.top.equalTo(self.snp.bottom).inset(URLBarViewUX.ProgressBarHeight / 2)
            make.height.equalTo(URLBarViewUX.ProgressBarHeight)
            make.left.right.equalTo(self)
        }

        locationView.snp.makeConstraints { make in
            make.edges.equalTo(self.locationContainer)
        }

        cancelButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.locationContainer)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
            make.leading.equalTo(self)
        }

        backButton.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(URLBarViewUX.Padding)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        forwardButton.snp.makeConstraints { make in
            make.left.equalTo(self.backButton.snp.right)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        stopReloadButton.snp.makeConstraints { make in
            make.left.equalTo(self.forwardButton.snp.right)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        menuButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.snp.trailing).offset(-URLBarViewUX.Padding)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }
        
        tabsButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.menuButton.snp.leading)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }
        
        showQRScannerButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.locationContainer)
            make.trailing.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }
    }

    override func updateConstraints() {
        super.updateConstraints()
        if inOverlayMode {
            // In overlay mode, we always show the location view full width
            self.locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidthSelected
            self.locationContainer.snp.remakeConstraints { make in
                let height = URLBarViewUX.LocationHeight + (URLBarViewUX.TextFieldBorderWidthSelected * 2)
                make.height.equalTo(height)
                make.trailing.equalTo(self.showQRScannerButton.snp.leading)
                make.leading.equalTo(self.cancelButton.snp.trailing)
                make.centerY.equalTo(self)
            }
            self.locationView.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationContainer).inset(UIEdgeInsets(equalInset: URLBarViewUX.TextFieldBorderWidthSelected))
            }
            self.locationTextField?.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationView).inset(UIEdgeInsets(top: 0, left: URLBarViewUX.LocationLeftPadding, bottom: 0, right: URLBarViewUX.LocationLeftPadding))
            }
        } else {
            self.locationContainer.snp.remakeConstraints { make in
                if self.toolbarIsShowing {
                    // If we are showing a toolbar, show the text field next to the forward button
                    make.leading.equalTo(self.stopReloadButton.snp.trailing).offset(URLBarViewUX.Padding)
                    if self.topTabsIsShowing {
                        make.trailing.equalTo(self.menuButton.snp.leading).offset(-URLBarViewUX.Padding)
                    } else {
                        make.trailing.equalTo(self.tabsButton.snp.leading).offset(-URLBarViewUX.Padding)
                    }

                } else {
                    // Otherwise, left align the location view
                    make.leading.trailing.equalTo(self).inset(UIEdgeInsets(top: 0, left: URLBarViewUX.LocationLeftPadding-1, bottom: 0, right: URLBarViewUX.LocationLeftPadding-1))
                }

                make.height.equalTo(URLBarViewUX.LocationHeight+2)
                make.centerY.equalTo(self)
            }
            self.locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidth
            self.locationView.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationContainer).inset(UIEdgeInsets(equalInset: URLBarViewUX.TextFieldBorderWidth))
            }
        }

    }
    
    func showQRScanner() {
        self.delegate?.urlBarDidPressQRButton(self)
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
        locationTextField.snp.remakeConstraints { make in
            make.edges.equalTo(self.locationView)
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
        self.locationContainer.alpha = alpha
        self.alpha = alpha
    }

    func updateProgressBar(_ progress: Float) {
        progressBar.alpha = 1
        progressBar.isHidden = false
        progressBar.setProgress(progress, animated: !isTransitioning)
    }

    func hideProgressBar() {
        progressBar.isHidden = true
        progressBar.setProgress(0, animated: false)
    }

    func updateReaderModeState(_ state: ReaderModeState) {
        locationView.readerModeState = state
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        locationTextField?.setAutocompleteSuggestion(suggestion)
    }

    func setLocation(_ location: String?, search: Bool) {
        locationTextField?.text = location
        if search, let location = location, !location.isEmpty {
            // Not notifying when empty agrees with AutocompleteTextField.textDidChange.
            delegate?.urlBar(self, didEnterText: location)
        }
    }

    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
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
                self.setLocation(locationText, search: search)
            }
        } else {
            // Copy the current URL to the editable text field, then activate it.
            self.setLocation(locationText, search: search)
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
        self.showQRScannerButton.isHidden = false
        self.progressBar.isHidden = false
        self.menuButton.isHidden = !self.toolbarIsShowing
        self.forwardButton.isHidden = !self.toolbarIsShowing
        self.backButton.isHidden = !self.toolbarIsShowing
        self.tabsButton.isHidden = !self.toolbarIsShowing || topTabsIsShowing
        self.stopReloadButton.isHidden = !self.toolbarIsShowing
    }

    func transitionToOverlay(_ didCancel: Bool = false) {
        self.cancelButton.alpha = inOverlayMode ? 1 : 0
        self.showQRScannerButton.alpha = inOverlayMode ? 1 : 0
        self.progressBar.alpha = inOverlayMode || didCancel ? 0 : 1
        self.tabsButton.alpha = inOverlayMode ? 0 : 1
        self.menuButton.alpha = inOverlayMode ? 0 : 1
        self.forwardButton.alpha = inOverlayMode ? 0 : 1
        self.backButton.alpha = inOverlayMode ? 0 : 1
        self.stopReloadButton.alpha = inOverlayMode ? 0 : 1

        let borderColor = inOverlayMode ? locationActiveBorderColor : locationBorderColor
        locationContainer.layer.borderColor = borderColor.cgColor

        if inOverlayMode {
            self.line.isHidden = inOverlayMode
            // Make the editable text field span the entire URL bar, covering the lock and reader icons.
            self.locationTextField?.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationView)
            }
        } else {
            // Shrink the editable text field back to the size of the location view before hiding it.
            self.locationTextField?.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationView.urlTextField)
            }
        }
    }

    func updateViewsForOverlayModeAndToolbarChanges() {
        self.cancelButton.isHidden = !inOverlayMode
        self.showQRScannerButton.isHidden = !inOverlayMode
        self.progressBar.isHidden = inOverlayMode
        self.menuButton.isHidden = !self.toolbarIsShowing || inOverlayMode
        self.forwardButton.isHidden = !self.toolbarIsShowing || inOverlayMode
        self.backButton.isHidden = !self.toolbarIsShowing || inOverlayMode
        self.tabsButton.isHidden = !self.toolbarIsShowing || inOverlayMode || topTabsIsShowing
        self.stopReloadButton.isHidden = !self.toolbarIsShowing || inOverlayMode
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

    func updateTabCount(_ count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }

    func updateReloadStatus(_ isLoading: Bool) {
        helper?.updateReloadStatus(isLoading)
        if isLoading {
            stopReloadButton.setImage(helper?.ImageStop, for: .normal)
        } else {
            stopReloadButton.setImage(helper?.ImageReload, for: .normal)
        }
    }

    func updatePageStatus(_ isWebPage: Bool) {
        stopReloadButton.isEnabled = isWebPage
    }

    var access: [Any]? {
        get {
            if inOverlayMode {
                guard let locationTextField = locationTextField else { return nil }
                return [locationTextField, cancelButton]
            } else {
                if toolbarIsShowing {
                    return [backButton, forwardButton, stopReloadButton, locationView, tabsButton, menuButton, progressBar]
                } else {
                    return [locationView, progressBar]
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
        guard var (locationText, isSearchQuery) = delegate?.urlBarDisplayTextForURL(locationView.url as URL?) else { return }

        // Make sure to use the result from urlBarDisplayTextForURL as it is responsible for extracting out search terms when on a search page
        if let text = locationText, let url = URL(string: text), let host = url.host, AppConstants.MOZ_PUNYCODE {
            locationText = url.absoluteString.replacingOccurrences(of: host, with: host.asciiHostToUTF8())
        }
        enterOverlayMode(locationText, pasted: false, search: isSearchQuery)
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
    
    func tabLocationViewDidTapPageOptions(_ tabLocationView: TabLocationView, from button: UIButton) {
        delegate?.urlBarDidPressPageOptions(self, from: tabLocationView.pageOptionsButton)
    }
    
    func tabLocationViewDidLongPressPageOptions(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidLongPressPageOptions(self, from: tabLocationView.pageOptionsButton)
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

    dynamic var cancelTintColor: UIColor? {
        get { return cancelButton.tintColor }
        set { return cancelButton.tintColor = newValue }
    }
    
    dynamic var showQRButtonTintColor: UIColor? {
        get { return showQRScannerButton.tintColor }
        set { return showQRScannerButton.tintColor = newValue }
    }

}

extension URLBarView: Themeable {
    
    func applyTheme(_ themeName: String) {
        locationView.applyTheme(themeName)
        locationTextField?.applyTheme(themeName)

        guard let theme = URLBarViewUX.Themes[themeName] else {
            fatalError("Theme not found")
        }
        
        let isPrivate = themeName == Theme.PrivateMode
        
        progressBar.setGradientColors(startColor: UIConstants.LoadingStartColor.color(isPBM: isPrivate), endColor: UIConstants.LoadingEndColor.color(isPBM: isPrivate))
        currentTheme = themeName
        locationBorderColor = theme.borderColor!
        locationActiveBorderColor = theme.activeBorderColor!
        cancelTintColor = theme.buttonTintColor
        showQRButtonTintColor = theme.buttonTintColor
        backgroundColor = theme.backgroundColor
        self.actionButtons.forEach { $0.applyTheme(themeName) }
        tabsButton.applyTheme(themeName)
        line.backgroundColor = UIConstants.URLBarDivider.color(isPBM: isPrivate)
        locationContainer.layer.shadowColor = self.locationBorderColor.cgColor
    }
}

// We need a subclass so we can setup the shadows correctly
// This subclass creates a strong shadow on the URLBar
class TabLocationContainerView: UIView {
    
    struct LocationContainerUX {
        static let CornerRadius: CGFloat = 4
        static let ShadowRadius: CGFloat = 2
        static let ShadowOpacity: Float = 1
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layer = self.layer
        layer.cornerRadius = LocationContainerUX.CornerRadius
        layer.shadowRadius = LocationContainerUX.ShadowRadius
        layer.shadowOpacity = LocationContainerUX.ShadowOpacity
        layer.masksToBounds = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let layer = self.layer
        
        layer.shadowOffset = CGSize(width: 0, height: 1)
        // the shadow appears 2px off from the view rect
        let shadowLength: CGFloat = 2
        let shadowPath = CGRect(x: shadowLength, y: shadowLength, width: layer.frame.width - (shadowLength * 2), height: layer.frame.height - (shadowLength * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: layer.cornerRadius).cgPath
        super.layoutSubviews()
    }
}

class ToolbarTextField: AutocompleteTextField {
    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.backgroundColor = UIColor(rgb: 0x636369)
        theme.textColor = UIColor.white
        theme.buttonTintColor = UIColor.white
        theme.highlightColor = UIConstants.PrivateModeInputHighlightColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.backgroundColor = .white
        theme.textColor = UIColor(rgb: 0x272727)
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
            fatalError("Theme not found")
        }

        backgroundColor = theme.backgroundColor
        textColor = theme.textColor
        clearButtonTintColor = theme.buttonTintColor
        highlightColor = theme.highlightColor!
    }
}
