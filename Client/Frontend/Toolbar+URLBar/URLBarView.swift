// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import SnapKit
import UIKit

private struct URLBarViewUX {
    static let TextFieldBorderColor = UIColor.Photon.Grey40
    static let TextFieldActiveBorderColor = UIColor.Photon.Blue40

    static let LocationLeftPadding: CGFloat = 8
    static let Padding: CGFloat = 10
    static let LocationHeight: CGFloat = 40
    static let ButtonHeight: CGFloat = 44
    static let LocationContentOffset: CGFloat = 8
    static let TextFieldCornerRadius: CGFloat = 8
    static let TextFieldBorderWidth: CGFloat = 0
    static let TextFieldBorderWidthSelected: CGFloat = 4
    static let ProgressBarHeight: CGFloat = 3
    static let SearchIconImageWidth: CGFloat = 30
    static let TabsButtonRotationOffset: CGFloat = 1.5
    static let TabsButtonHeight: CGFloat = 18.0
    static let ToolbarButtonInsets = UIEdgeInsets(equalInset: Padding)
}

protocol URLBarDelegate: AnyObject {
    func urlBarDidPressTabs(_ urlBar: URLBarView)
    func urlBarDidPressReaderMode(_ urlBar: URLBarView)
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool
    func urlBarDidLongPressReload(_ urlBar: URLBarView, from button: UIButton)
    func urlBarDidPressStop(_ urlBar: URLBarView)
    func urlBarDidPressReload(_ urlBar: URLBarView)
    func urlBarDidEnterOverlayMode(_ urlBar: URLBarView)
    func urlBarDidLeaveOverlayMode(_ urlBar: URLBarView)
    func urlBarDidLongPressLocation(_ urlBar: URLBarView)
    func urlBarDidPressQRButton(_ urlBar: URLBarView)
    func urlBarDidTapShield(_ urlBar: URLBarView)
    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]?
    func urlBarDidPressScrollToTop(_ urlBar: URLBarView)
    func urlBar(_ urlBar: URLBarView, didRestoreText text: String)
    func urlBar(_ urlBar: URLBarView, didEnterText text: String)
    func urlBar(_ urlBar: URLBarView, didSubmitText text: String)
    // Returns either (search query, true) or (url, false).
    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool)
    func urlBarDidBeginDragInteraction(_ urlBar: URLBarView)
}

class URLBarView: UIView, AlphaDimmable, TopBottomInterchangeable {
    // Additional UIAppearance-configurable properties
    @objc dynamic var locationBorderColor: UIColor = URLBarViewUX.TextFieldBorderColor {
        didSet {
            if !inOverlayMode {
                locationContainer.layer.borderColor = locationBorderColor.cgColor
            }
        }
    }
    @objc dynamic var locationActiveBorderColor: UIColor = URLBarViewUX.TextFieldActiveBorderColor {
        didSet {
            if inOverlayMode {
                locationContainer.layer.borderColor = locationActiveBorderColor.cgColor
            }
        }
    }

    var parent: UIStackView?
    var searchEngines: SearchEngines?
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

    var toolbarIsShowing = false
    var topTabsIsShowing = false

    var locationTextField: ToolbarTextField?

    /// Overlay mode is the state where the lock/reader icons are hidden, the home panels are shown,
    /// and the Cancel button is visible (allowing the user to leave overlay mode). Overlay mode
    /// is *not* tied to the location text field's editing state; for instance, when selecting
    /// a panel, the first responder will be resigned, yet the overlay mode UI is still active.
    var inOverlayMode = false

    lazy var locationView: TabLocationView = {
        let locationView = TabLocationView()
        locationView.layer.cornerRadius = URLBarViewUX.TextFieldCornerRadius
        locationView.translatesAutoresizingMaskIntoConstraints = false
        locationView.delegate = self
        return locationView
    }()

    lazy var locationContainer: UIView = {
        let locationContainer = TabLocationContainerView()
        locationContainer.translatesAutoresizingMaskIntoConstraints = false
        locationContainer.backgroundColor = .clear
        return locationContainer
    }()

    let line = UIView()

    lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.accessibilityIdentifier = "URLBarView.tabsButton"
        tabsButton.inTopTabs = false
        return tabsButton
    }()

    fileprivate lazy var progressBar: GradientProgressBar = {
        let progressBar = GradientProgressBar()
        progressBar.clipsToBounds = false
        return progressBar
    }()

    fileprivate lazy var cancelButton: UIButton = {
        let cancelButton = InsetButton()
        cancelButton.setImage(UIImage.templateImageNamed("goBack")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        cancelButton.accessibilityIdentifier = "urlBar-cancel"
        cancelButton.accessibilityLabel = AccessibilityIdentifiers.GeneralizedIdentifiers.back
        cancelButton.addTarget(self, action: #selector(didClickCancel), for: .touchUpInside)
        cancelButton.alpha = 0
        return cancelButton
    }()

    fileprivate lazy var showQRScannerButton: InsetButton = {
        let button = InsetButton()
        button.setImage(UIImage.templateImageNamed("menu-ScanQRCode"), for: .normal)
        button.accessibilityIdentifier = "urlBar-scanQRCode"
        button.accessibilityLabel = .ScanQRCodeViewTitle
        button.clipsToBounds = false
        button.addTarget(self, action: #selector(showQRScanner), for: .touchUpInside)
        button.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        button.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        return button
    }()

    fileprivate lazy var scrollToTopButton: UIButton = {
        let button = UIButton()
        // This button interferes with accessibility of the URL bar as it partially overlays it, and keeps getting the VoiceOver focus instead of the URL bar.
        // @TODO: figure out if there is an iOS standard way to do this that works with accessibility.
        button.isAccessibilityElement = false
        button.addTarget(self, action: #selector(tappedScrollToTopArea), for: .touchUpInside)
        return button
    }()

    fileprivate lazy var searchIconImageView: UIImageView = {
        let searchIconImageView = UIImageView()
        searchIconImageView.isAccessibilityElement = true
        searchIconImageView.contentMode = .scaleAspectFit
        searchIconImageView.layer.cornerRadius = 5
        searchIconImageView.clipsToBounds = true
        return searchIconImageView
    }()

    var appMenuButton = ToolbarButton()
    var bookmarksButton = ToolbarButton()
    var homeButton = ToolbarButton()
    var addNewTabButton = ToolbarButton()
    var forwardButton = ToolbarButton()
    var multiStateButton = ToolbarButton()

    var backButton: ToolbarButton = {
        let backButton = ToolbarButton()
        backButton.accessibilityIdentifier = "URLBarView.backButton"
        return backButton
    }()

    lazy var actionButtons: [NotificationThemeable & UIButton] = [
        self.tabsButton,
        self.homeButton,
        self.bookmarksButton,
        self.appMenuButton,
        self.addNewTabButton,
        self.forwardButton,
        self.backButton,
        self.multiStateButton]

    var currentURL: URL? {
        get {
            return locationView.url as URL?
        }

        set(newURL) {
            locationView.url = newURL
            if let url = newURL, InternalURL(url)?.isAboutHomeURL ?? false {
                line.isHidden = true
            } else {
                line.isHidden = false
            }
        }
    }

    var profile: Profile

    fileprivate let privateModeBadge = BadgeWithBackdrop(imageName: "privateModeBadge", backdropCircleColor: UIColor.Defaults.MobilePrivatePurple)
    fileprivate let appMenuBadge = BadgeWithBackdrop(imageName: "menuBadge")
    fileprivate let warningMenuBadge = BadgeWithBackdrop(imageName: "menuWarning", imageMask: "warning-mask")

    init(profile: Profile) {
        self.profile = profile
        self.searchEngines = SearchEngines(prefs: profile.prefs, files: profile.files)
        super.init(frame: CGRect())
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSearchEngineImage() {
        self.searchIconImageView.image = profile.searchEngines.defaultEngine.image
    }

    private func isBottomSearchBar() -> Bool {
        guard SearchBarSettingsViewModel.isEnabled else { return false }
        return SearchBarSettingsViewModel(prefs: profile.prefs).searchBarPosition == .bottom
    }

    fileprivate func commonInit() {
        locationContainer.addSubview(locationView)

        [scrollToTopButton, line, tabsButton, progressBar, cancelButton, showQRScannerButton,
         homeButton, bookmarksButton, appMenuButton, addNewTabButton, forwardButton, backButton,
         multiStateButton, locationContainer, searchIconImageView].forEach {
            addSubview($0)
        }

        updateSearchEngineImage()

        privateModeBadge.add(toParent: self)
        appMenuBadge.add(toParent: self)
        warningMenuBadge.add(toParent: self)

        helper = TabToolbarHelper(toolbar: self)
        setupConstraints()

        // Make sure we hide any views that shouldn't be showing in non-overlay mode.
        updateViewsForOverlayModeAndToolbarChanges()
    }

    fileprivate func setupConstraints() {

        scrollToTopButton.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.right.equalTo(locationContainer)
        }

        locationView.snp.makeConstraints { make in
            make.edges.equalTo(self.locationContainer)
        }

        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(self.safeArea.leading)
            make.centerY.equalTo(self.locationContainer)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        backButton.snp.makeConstraints { make in
            make.leading.equalTo(self.safeArea.leading).offset(URLBarViewUX.Padding)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        forwardButton.snp.makeConstraints { make in
            make.leading.equalTo(self.backButton.snp.trailing)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        searchIconImageView.snp.remakeConstraints { make in
            let heightMin = URLBarViewUX.LocationHeight + (URLBarViewUX.TextFieldBorderWidthSelected * 2)
            make.height.greaterThanOrEqualTo(heightMin)
            make.centerY.equalTo(self)
            make.leading.equalTo(self.cancelButton.snp.trailing).offset(URLBarViewUX.LocationLeftPadding)
            make.width.equalTo(URLBarViewUX.SearchIconImageWidth)
        }

        multiStateButton.snp.makeConstraints { make in
            make.leading.equalTo(self.forwardButton.snp.trailing)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        homeButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.bookmarksButton.snp.leading)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        bookmarksButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.appMenuButton.snp.leading)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        appMenuButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.safeArea.trailing).offset(-URLBarViewUX.Padding)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        addNewTabButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.tabsButton.snp.leading)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        tabsButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.appMenuButton.snp.leading)
            make.centerY.equalTo(self)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        showQRScannerButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.safeArea.trailing)
            make.centerY.equalTo(self.locationContainer)
            make.size.equalTo(URLBarViewUX.ButtonHeight)
        }

        privateModeBadge.layout(onButton: tabsButton)
        appMenuBadge.layout(onButton: appMenuButton)
        warningMenuBadge.layout(onButton: appMenuButton)
    }

    override func updateConstraints() {
        super.updateConstraints()

        line.snp.remakeConstraints { make in
            if isBottomSearchBar() {
                make.top.equalTo(self).offset(0)
            } else {
                make.bottom.equalTo(self)
            }

            make.leading.trailing.equalTo(self)
            make.height.equalTo(1)
        }

        progressBar.snp.remakeConstraints { make in
            if isBottomSearchBar() {
                make.bottom.equalTo(snp.top).inset(URLBarViewUX.ProgressBarHeight / 2)
            } else {
                make.top.equalTo(snp.bottom).inset(URLBarViewUX.ProgressBarHeight / 2)
            }

            make.height.equalTo(URLBarViewUX.ProgressBarHeight)
            make.left.right.equalTo(self)
        }

        if inOverlayMode {
            searchIconImageView.alpha = 1
            // In overlay mode, we always show the location view full width
            self.locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidthSelected
            self.locationContainer.snp.remakeConstraints { make in
                let heightMin = URLBarViewUX.LocationHeight + (URLBarViewUX.TextFieldBorderWidthSelected * 2)
                make.height.greaterThanOrEqualTo(heightMin)
                make.trailing.equalTo(self.showQRScannerButton.snp.leading)
                make.leading.equalTo(self.cancelButton.snp.trailing)
                make.centerY.equalTo(self)
            }
            self.locationView.snp.remakeConstraints { make in
                make.top.bottom.trailing.equalTo(self.locationContainer).inset(UIEdgeInsets(equalInset: URLBarViewUX.TextFieldBorderWidthSelected))
                make.leading.equalTo(self.searchIconImageView.snp.trailing)
            }
            self.locationTextField?.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationView).inset(UIEdgeInsets(top: 0, left: URLBarViewUX.LocationLeftPadding, bottom: 0, right: URLBarViewUX.LocationLeftPadding))
            }
        } else {
            searchIconImageView.alpha = 0
            self.locationContainer.snp.remakeConstraints { make in
                if self.toolbarIsShowing {
                    // If we are showing a toolbar, show the text field next to the forward button
                    make.leading.equalTo(self.multiStateButton.snp.trailing).offset(URLBarViewUX.Padding)
                    if self.topTabsIsShowing {
                        make.trailing.equalTo(self.homeButton.snp.leading).offset(-URLBarViewUX.Padding)
                    } else {
                        make.trailing.equalTo(self.addNewTabButton.snp.leading).offset(-URLBarViewUX.Padding)
                    }
                } else {
                    // Otherwise, left align the location view
                    make.leading.trailing.equalTo(self).inset(UIEdgeInsets(top: 0, left: URLBarViewUX.LocationLeftPadding-1, bottom: 0, right: URLBarViewUX.LocationLeftPadding-1))
                }
                make.height.greaterThanOrEqualTo(URLBarViewUX.LocationHeight+2)
                make.centerY.equalTo(self)
            }
            self.locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidth
            self.locationView.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationContainer).inset(UIEdgeInsets(equalInset: URLBarViewUX.TextFieldBorderWidth))
            }
        }

    }

    @objc func showQRScanner() {
        self.delegate?.urlBarDidPressQRButton(self)
    }

    func createLocationTextField() {
        guard locationTextField == nil else { return }

        locationTextField = ToolbarTextField()

        guard let locationTextField = locationTextField else { return }

        locationTextField.font = UIFont.preferredFont(forTextStyle: .body)
        locationTextField.adjustsFontForContentSizeCategory = true
        locationTextField.clipsToBounds = true
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        locationTextField.autocompleteDelegate = self
        locationTextField.keyboardType = .webSearch
        locationTextField.autocorrectionType = .no
        locationTextField.autocapitalizationType = .none
        locationTextField.returnKeyType = .go
        locationTextField.clearButtonMode = .whileEditing
        locationTextField.textAlignment = .left
        locationTextField.accessibilityIdentifier = "address"
        locationTextField.accessibilityLabel = .URLBarLocationAccessibilityLabel
        locationTextField.attributedPlaceholder = self.locationView.placeholder
        locationContainer.addSubview(locationTextField)
        // Disable dragging urls on iPhones because it conflicts with editing the text
        if UIDevice.current.userInterfaceIdiom != .pad {
            locationTextField.textDragInteraction?.isEnabled = false
        }

        locationTextField.applyTheme()
        locationTextField.backgroundColor = UIColor.theme.textField.backgroundInOverlay
    }

    override func becomeFirstResponder() -> Bool {
        return self.locationTextField?.becomeFirstResponder() ?? false
    }

    func removeLocationTextField() {
        locationTextField?.removeFromSuperview()
        locationTextField = nil
    }

    /// Ideally we'd split this implementation in two, one URLBarView with a toolbar and one without
    /// However, switching views dynamically at runtime is a difficult. For now, we just use one view
    /// that can show in either mode. For the reload button, we hide it on iPad (apart from multitasking mode)
    func setShowToolbar(_ shouldShow: Bool, hideReloadButton: Bool) {
        toolbarIsShowing = shouldShow
        setNeedsUpdateConstraints()
        // when we transition from portrait to landscape, calling this here causes
        // the constraints to be calculated too early and there are constraint errors
        if !toolbarIsShowing {
            updateConstraintsIfNeeded()
        }
        locationView.reloadButton.isHidden = hideReloadButton
        updateViewsForOverlayModeAndToolbarChanges()
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        locationContainer.alpha = alpha
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

    /// We hide reload button on iPad, but not in multitasking mode
    func updateReaderModeState(_ state: ReaderModeState, hideReloadButton: Bool) {
        locationView.readerModeState = state
        locationView.reloadButton.isHidden = hideReloadButton
    }

    /// We hide reload button on iPad, but not in multitasking mode
    func shouldHideReloadButton(_ isHidden: Bool) {
        locationView.reloadButton.isHidden = isHidden
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        locationTextField?.setAutocompleteSuggestion(suggestion)
    }

    func setLocation(_ location: String?, search: Bool) {
        guard let text = location, !text.isEmpty else {
            locationTextField?.text = location
            return
        }
        if search {
            locationTextField?.text = text
            // Not notifying when empty agrees with AutocompleteTextField.textDidChange.
            delegate?.urlBar(self, didRestoreText: text)
        } else {
            locationTextField?.setTextWithoutSearching(text)
        }
    }

    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        createLocationTextField()

        // Show the overlay mode UI, which includes hiding the locationView and replacing it
        // with the editable locationTextField.
        animateToOverlayState(overlayMode: true)

        delegate?.urlBarDidEnterOverlayMode(self)

        applyTheme()

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
            DispatchQueue.main.async {
                self.locationTextField?.becomeFirstResponder()
                // Need to set location again so text could be immediately selected.
                self.setLocation(locationText, search: search)
                self.locationTextField?.selectAll(nil)
            }
        }
    }

    func leaveOverlayMode(didCancel cancel: Bool = false) {
        locationTextField?.resignFirstResponder()
        animateToOverlayState(overlayMode: false, didCancel: cancel)
        delegate?.urlBarDidLeaveOverlayMode(self)
        applyTheme()
    }

    func prepareOverlayAnimation() {
        // Make sure everything is showing during the transition (we'll hide it afterwards).
        bringSubviewToFront(self.locationContainer)
        bringSubviewToFront(self.searchIconImageView)
        cancelButton.isHidden = false
        showQRScannerButton.isHidden = false
        progressBar.isHidden = false
        addNewTabButton.isHidden = !toolbarIsShowing || topTabsIsShowing
        appMenuButton.isHidden = !toolbarIsShowing
        homeButton.isHidden = !toolbarIsShowing || !topTabsIsShowing
        bookmarksButton.isHidden = !toolbarIsShowing || !topTabsIsShowing
        forwardButton.isHidden = !toolbarIsShowing
        backButton.isHidden = !toolbarIsShowing
        tabsButton.isHidden = !toolbarIsShowing || topTabsIsShowing
        multiStateButton.isHidden = !toolbarIsShowing
    }

    func transitionToOverlay(_ didCancel: Bool = false) {
        locationView.contentView.alpha = inOverlayMode ? 0 : 1
        cancelButton.alpha = inOverlayMode ? 1 : 0
        showQRScannerButton.alpha = inOverlayMode ? 1 : 0
        progressBar.alpha = inOverlayMode || didCancel ? 0 : 1
        tabsButton.alpha = inOverlayMode ? 0 : 1
        appMenuButton.alpha = inOverlayMode ? 0 : 1
        homeButton.alpha = inOverlayMode ? 0 : 1
        bookmarksButton.alpha = inOverlayMode ? 0 : 1
        addNewTabButton.alpha = inOverlayMode ? 0 : 1
        forwardButton.alpha = inOverlayMode ? 0 : 1
        backButton.alpha = inOverlayMode ? 0 : 1
        multiStateButton.alpha = inOverlayMode ? 0 : 1

        let borderColor = inOverlayMode ? locationActiveBorderColor : locationBorderColor
        locationContainer.layer.borderColor = borderColor.cgColor

        if inOverlayMode {
            line.isHidden = inOverlayMode
            // Make the editable text field span the entire URL bar, covering the lock and reader icons.
            locationTextField?.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationView)
            }
        } else {
            // Shrink the editable text field back to the size of the location view before hiding it.
            locationTextField?.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationView.urlTextField)
            }
        }
    }

    func updateViewsForOverlayModeAndToolbarChanges() {
        // This ensures these can't be selected as an accessibility element when in the overlay mode.
        locationView.overrideAccessibility(enabled: !inOverlayMode)

        cancelButton.isHidden = !inOverlayMode
        showQRScannerButton.isHidden = !inOverlayMode
        progressBar.isHidden = inOverlayMode
        addNewTabButton.isHidden = !toolbarIsShowing || topTabsIsShowing || inOverlayMode
        appMenuButton.isHidden = !toolbarIsShowing || inOverlayMode
        homeButton.isHidden = !toolbarIsShowing || inOverlayMode || !topTabsIsShowing
        bookmarksButton.isHidden = !toolbarIsShowing || inOverlayMode || !topTabsIsShowing
        forwardButton.isHidden = !toolbarIsShowing || inOverlayMode
        backButton.isHidden = !toolbarIsShowing || inOverlayMode
        tabsButton.isHidden = !toolbarIsShowing || inOverlayMode || topTabsIsShowing
        multiStateButton.isHidden = !toolbarIsShowing || inOverlayMode

        // badge isHidden is tied to private mode on/off, use alpha to hide in this case
        [privateModeBadge, appMenuBadge, warningMenuBadge].forEach {
            $0.badge.alpha = (!toolbarIsShowing || inOverlayMode) ? 0 : 1
            $0.backdrop.alpha = (!toolbarIsShowing || inOverlayMode) ? 0 : BadgeWithBackdrop.backdropAlpha
        }

    }

    func animateToOverlayState(overlayMode overlay: Bool, didCancel cancel: Bool = false) {
        prepareOverlayAnimation()
        layoutIfNeeded()

        inOverlayMode = overlay

        if !overlay {
            removeLocationTextField()
        }

        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: [], animations: {
            self.transitionToOverlay(cancel)
            self.setNeedsUpdateConstraints()
            self.layoutIfNeeded()
        }, completion: { _ in
            self.updateViewsForOverlayModeAndToolbarChanges()
        })
    }

    func didClickAddTab() {
        delegate?.urlBarDidPressTabs(self)
    }

    @objc func didClickCancel() {
        leaveOverlayMode(didCancel: true)
    }

    @objc func tappedScrollToTopArea() {
        delegate?.urlBarDidPressScrollToTop(self)
    }
}

extension URLBarView: TabToolbarProtocol {
    func privateModeBadge(visible: Bool) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            privateModeBadge.show(visible)
        }
    }

    func appMenuBadge(setVisible: Bool) {
        // Warning badges should take priority over the standard badge
        guard warningMenuBadge.badge.isHidden else { return }

        appMenuBadge.show(setVisible)
    }

    func warningMenuBadge(setVisible: Bool) {
        // Disable other menu badges before showing the warning.
        if !appMenuBadge.badge.isHidden { appMenuBadge.show(false) }
        warningMenuBadge.show(setVisible)
    }

    func updateBackStatus(_ canGoBack: Bool) {
        backButton.isEnabled = canGoBack
    }

    func updateForwardStatus(_ canGoForward: Bool) {
        forwardButton.isEnabled = canGoForward
    }

    func updateTabCount(_ count: Int, animated: Bool = true) {
        tabsButton.updateTabCount(count, animated: animated)
    }

    func updateMiddleButtonState(_ state: MiddleButtonState) {
        helper?.setMiddleButtonState(state)
    }

    func updatePageStatus(_ isWebPage: Bool) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            multiStateButton.isEnabled = isWebPage
        }
    }

    var access: [Any]? {
        get {
            if inOverlayMode {
                guard let locationTextField = locationTextField else { return nil }
                return [locationTextField, cancelButton]
            } else {
                if toolbarIsShowing {
                    return [backButton, forwardButton, multiStateButton, locationView, tabsButton, homeButton, bookmarksButton, appMenuButton, addNewTabButton, progressBar]
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

    func tabLocationViewDidLongPressReload(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidLongPressReload(self, from: tabLocationView.reloadButton)
    }

    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView) {
        guard let (locationText, isSearchQuery) = delegate?.urlBarDisplayTextForURL(locationView.url as URL?) else { return }

        var overlayText = locationText
        // Make sure to use the result from urlBarDisplayTextForURL as it is responsible for extracting out search terms when on a search page
        if let text = locationText, let url = URL(string: text), let host = url.host, AppConstants.MOZ_PUNYCODE {
            overlayText = url.absoluteString.replacingOccurrences(of: host, with: host.asciiHostToUTF8())
        }
        enterOverlayMode(overlayText, pasted: false, search: isSearchQuery)
    }

    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidLongPressLocation(self)
    }

    func tabLocationViewDidTapReload(_ tabLocationView: TabLocationView) {
        let state = locationView.reloadButton.isHidden ? .reload : locationView.reloadButton.reloadButtonState

        switch state {
        case .reload:
            delegate?.urlBarDidPressReload(self)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .reloadFromUrlBar)
        case .stop:
            delegate?.urlBarDidPressStop(self)
        case .disabled:
            // do nothing
            break
        }
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

    func tabLocationViewDidBeginDragInteraction(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidBeginDragInteraction(self)
    }

    func tabLocationViewDidTapShield(_ tabLocationView: TabLocationView) {
        delegate?.urlBarDidTapShield(self)
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

    func autocompleteTextFieldShouldClear(_ autocompleteTextField: AutocompleteTextField) -> Bool {
        delegate?.urlBar(self, didEnterText: "")
        return true
    }

    func autocompleteTextFieldDidCancel(_ autocompleteTextField: AutocompleteTextField) {
        leaveOverlayMode(didCancel: true)
    }

    func autocompletePasteAndGo(_ autocompleteTextField: AutocompleteTextField) {
        if let pasteboardContents = UIPasteboard.general.string {
            self.delegate?.urlBar(self, didSubmitText: pasteboardContents)
        }
    }
}

// MARK: UIAppearance
extension URLBarView {

    @objc dynamic var cancelTintColor: UIColor? {
        get { return cancelButton.tintColor }
        set { return cancelButton.tintColor = newValue }
    }

    @objc dynamic var showQRButtonTintColor: UIColor? {
        get { return showQRScannerButton.tintColor }
        set { return showQRScannerButton.tintColor = newValue }
    }

}

// MARK: - NotificationThemeable
extension URLBarView: NotificationThemeable {
    func applyTheme() {
        locationView.applyTheme()
        locationTextField?.applyTheme()

        actionButtons.forEach { $0.applyTheme() }
        tabsButton.applyTheme()
        addNewTabButton.applyTheme()

        cancelTintColor = UIColor.theme.browser.tint
        showQRButtonTintColor = UIColor.theme.browser.tint
        backgroundColor = UIColor.theme.browser.background
        line.backgroundColor = UIColor.theme.browser.urlBarDivider

        locationBorderColor = UIColor.theme.urlbar.border
        locationView.backgroundColor = inOverlayMode ? UIColor.theme.textField.backgroundInOverlay : UIColor.theme.textField.background
        locationContainer.backgroundColor = UIColor.theme.textField.background

        privateModeBadge.badge.tintBackground(color: UIColor.theme.browser.background)
        appMenuBadge.badge.tintBackground(color: UIColor.theme.browser.background)
        warningMenuBadge.badge.tintBackground(color: UIColor.theme.browser.background)
    }
}

// MARK: - PrivateModeUI
extension URLBarView: PrivateModeUI {
    func applyUIMode(isPrivate: Bool) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            privateModeBadge.show(isPrivate)
        }

        locationActiveBorderColor = UIColor.theme.urlbar.activeBorder(isPrivate)
        progressBar.setGradientColors(startColor: UIColor.theme.loadingBar.start(isPrivate),
                                      middleColor: UIColor.theme.loadingBar.middle(isPrivate),
                                      endColor: UIColor.theme.loadingBar.end(isPrivate))
        ToolbarTextField.applyUIMode(isPrivate: isPrivate)

        applyTheme()
    }
}
