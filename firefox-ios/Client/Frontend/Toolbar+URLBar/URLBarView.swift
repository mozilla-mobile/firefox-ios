// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SnapKit
import UIKit

private struct URLBarViewUX {
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
    static let urlBarLineHeight = 0.5
}

/// Describes the reason for leaving overlay mode.
enum URLBarLeaveOverlayModeReason {
    /// The user committed their edits.
    case finished

    /// The user aborted their edits.
    case cancelled
}

protocol URLBarDelegate: AnyObject {
    func urlBarDidPressTabs(_ urlBar: URLBarView)
    func urlBarDidPressReaderMode(_ urlBar: URLBarView)
    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions
    ///            for even starting handling long-press were not satisfied
    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool
    func urlBarDidLongPressReload(_ urlBar: URLBarView, from button: UIButton)
    func urlBarDidPressStop(_ urlBar: URLBarView)
    func urlBarDidPressReload(_ urlBar: URLBarView)
    func urlBarDidEnterOverlayMode(_ urlBar: URLBarView)
    func urlBar(_ urlBar: URLBarView, didLeaveOverlayModeForReason: URLBarLeaveOverlayModeReason)
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
    func urlBarPresentCFR(at sourceView: UIView)
}

protocol URLBarViewProtocol {
    var inOverlayMode: Bool { get }
    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool)
    func leaveOverlayMode(reason: URLBarLeaveOverlayModeReason, shouldCancelLoading cancel: Bool)
}

class URLBarView: UIView,
                  URLBarViewProtocol,
                  AlphaDimmable,
                  TopBottomInterchangeable,
                  SearchEngineDelegate,
                  SearchBarLocationProvider,
                  Autocompletable {
    // Additional UIAppearance-configurable properties
    @objc dynamic lazy var locationBorderColor: UIColor = .clear {
        didSet {
            if !inOverlayMode {
                locationContainer.layer.borderColor = locationBorderColor.cgColor
            }
        }
    }
    @objc dynamic lazy var locationActiveBorderColor: UIColor = .clear {
        didSet {
            if inOverlayMode {
                locationContainer.layer.borderColor = locationActiveBorderColor.cgColor
            }
        }
    }

    var parent: UIStackView?
    var searchEnginesManager: SearchEnginesManager?
    weak var delegate: URLBarDelegate?
    weak var tabToolbarDelegate: TabToolbarDelegate?
    var helper: TabToolbarHelper?
    var isTransitioning = false {
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
    var isMicrosurveyShown = false

    var locationTextField: ToolbarTextField?
    private var isActivatingLocationTextField = false

    /// Overlay mode is the state where the lock/reader icons are hidden, the home panels are shown,
    /// and the Cancel button is visible (allowing the user to leave overlay mode).
    var inOverlayMode = false

    lazy var locationView: TabLocationView = {
        let locationView = TabLocationView(windowUUID: windowUUID)
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

    private let line: UIView = .build { view in
        view.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.urlBarBorder
    }

    lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton()
        tabsButton.accessibilityLabel = .TabTrayButtonShowTabsAccessibilityLabel
        tabsButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.tabsButton
        return tabsButton
    }()

    fileprivate lazy var progressBar: GradientProgressBar = {
        let progressBar = GradientProgressBar()
        progressBar.clipsToBounds = false
        return progressBar
    }()

    fileprivate lazy var cancelButton: UIButton = {
        let cancelButton = InsetButton()
        let flippedChevron = UIImage.templateImageNamed(StandardImageIdentifiers.Large.chevronLeft)?
            .imageFlippedForRightToLeftLayoutDirection()

        cancelButton.setImage(flippedChevron, for: .normal)
        cancelButton.accessibilityIdentifier = AccessibilityIdentifiers.Browser.UrlBar.cancelButton
        cancelButton.accessibilityLabel = AccessibilityIdentifiers.GeneralizedIdentifiers.back
        cancelButton.addTarget(self, action: #selector(didClickCancel), for: .touchUpInside)
        cancelButton.alpha = 0
        cancelButton.showsLargeContentViewer = true
        cancelButton.largeContentTitle = AccessibilityIdentifiers.GeneralizedIdentifiers.back
        cancelButton.largeContentImage = flippedChevron
        return cancelButton
    }()

    fileprivate lazy var showQRScannerButton: InsetButton = {
        let button = InsetButton()
        let qrCodeImage = UIImage.templateImageNamed(StandardImageIdentifiers.Large.qrCode)
        button.setImage(qrCodeImage, for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Browser.UrlBar.scanQRCodeButton
        button.accessibilityLabel = .ScanQRCodeViewTitle
        button.showsLargeContentViewer = true
        button.largeContentTitle = .ScanQRCodeViewTitle
        button.largeContentImage = qrCodeImage
        button.clipsToBounds = false
        button.addTarget(self, action: #selector(showQRScanner), for: .touchUpInside)
        button.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        button.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        return button
    }()

    fileprivate lazy var scrollToTopButton: UIButton = {
        let button = UIButton()
        // This button interferes with accessibility of the URL bar as it partially overlays it, and keeps
        // getting the VoiceOver focus instead of the URL bar.
        // TODO: figure out if there is an iOS standard way to do this that works with accessibility.
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
        searchIconImageView.showsLargeContentViewer = true
        return searchIconImageView
    }()

    var appMenuButton = ToolbarButton()
    var bookmarksButton = ToolbarButton()
    var addNewTabButton = ToolbarButton()
    var forwardButton = ToolbarButton()
    var multiStateButton = ToolbarButton()

    var backButton: ToolbarButton = {
        let backButton = ToolbarButton()
        backButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.backButton
        return backButton
    }()

    lazy var actionButtons: [ThemeApplicable & UIButton] = [
        self.tabsButton,
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
        }
    }

    var profile: Profile
    let windowUUID: WindowUUID

    fileprivate lazy var privateModeBadge = BadgeWithBackdrop(
        imageName: StandardImageIdentifiers.Medium.privateModeCircleFillPurple,
        isPrivateBadge: true
    )

    fileprivate let warningMenuBadge = BadgeWithBackdrop(
        imageName: StandardImageIdentifiers.Large.warningFill,
        imageMask: ImageIdentifiers.menuWarningMask
    )

    init(profile: Profile, windowUUID: WindowUUID) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.searchEnginesManager = SearchEnginesManager(prefs: profile.prefs, files: profile.files)
        super.init(frame: CGRect())
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func searchEnginesDidUpdate() {
        let engineID = profile.searchEnginesManager.defaultEngine?.engineID ?? "custom"
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .change,
            object: .defaultSearchEngine,
            value: nil,
            extras: [TelemetryWrapper.EventExtraKey.recordSearchEngineID.rawValue: engineID]
        )

        self.searchIconImageView.image = profile.searchEnginesManager.defaultEngine?.image
        self.searchIconImageView.largeContentTitle = profile.searchEnginesManager.defaultEngine?.shortName
        self.searchIconImageView.largeContentImage = nil

        guard let name = profile.searchEnginesManager.defaultEngine?.shortName else { return }
        self.searchIconImageView.accessibilityLabel = String(format: .AddressToolbar.SearchEngineA11yLabel, name)
    }

    fileprivate func commonInit() {
        locationContainer.addSubview(locationView)

        [
            scrollToTopButton,
            line,
            tabsButton,
            progressBar,
            cancelButton,
            showQRScannerButton,
            bookmarksButton,
            appMenuButton,
            addNewTabButton,
            forwardButton,
            backButton,
            multiStateButton,
            locationContainer,
            searchIconImageView
        ].forEach {
            addSubview($0)
        }

        profile.searchEnginesManager.delegate = self

        privateModeBadge.add(toParent: self)
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
        warningMenuBadge.layout(onButton: appMenuButton)
    }

    override func updateConstraints() {
        line.snp.remakeConstraints { make in
            if isBottomSearchBar {
                make.top.equalTo(self)
            } else {
                make.bottom.equalTo(self).offset(URLBarViewUX.urlBarLineHeight)
            }

            make.leading.trailing.equalTo(self)
            make.height.equalTo(URLBarViewUX.urlBarLineHeight)
        }

        progressBar.snp.remakeConstraints { make in
            if isBottomSearchBar {
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
                make.top.bottom.trailing.equalTo(self.locationContainer).inset(
                    UIEdgeInsets(
                        equalInset: URLBarViewUX.TextFieldBorderWidthSelected
                    )
                )
                make.leading.equalTo(self.searchIconImageView.snp.trailing)
            }
            self.locationTextField?.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationView).inset(
                    UIEdgeInsets(
                        top: 0,
                        left: URLBarViewUX.LocationLeftPadding,
                        bottom: 0,
                        right: URLBarViewUX.LocationLeftPadding
                    )
                )
            }
        } else {
            searchIconImageView.alpha = 0
            self.locationContainer.snp.remakeConstraints { make in
                if self.toolbarIsShowing {
                    // If we are showing a toolbar, show the text field next to the forward button
                    make.leading.equalTo(self.multiStateButton.snp.trailing).offset(URLBarViewUX.Padding)
                    if self.topTabsIsShowing {
                        make.trailing.equalTo(self.bookmarksButton.snp.leading).offset(-URLBarViewUX.Padding)
                    } else {
                        make.trailing.equalTo(self.addNewTabButton.snp.leading).offset(-URLBarViewUX.Padding)
                    }
                } else {
                    // Otherwise, left align the location view
                    make.leading.trailing.equalTo(self).inset(
                        UIEdgeInsets(
                            top: 0,
                            left: URLBarViewUX.LocationLeftPadding-1,
                            bottom: 0,
                            right: URLBarViewUX.LocationLeftPadding-1
                        )
                    )
                }
                make.height.greaterThanOrEqualTo(URLBarViewUX.LocationHeight+2)
                make.centerY.equalTo(self)
            }
            self.locationContainer.layer.borderWidth = URLBarViewUX.TextFieldBorderWidth
            self.locationView.snp.remakeConstraints { make in
                make.edges.equalTo(self.locationContainer).inset(
                    UIEdgeInsets(
                        equalInset: URLBarViewUX.TextFieldBorderWidth
                    )
                )
            }
        }
        super.updateConstraints()
    }

    @objc
    func showQRScanner() {
        self.delegate?.urlBarDidPressQRButton(self)
    }

    func createLocationTextField() {
        guard locationTextField == nil else { return }

        locationTextField = ToolbarTextField()
        guard let locationTextField = locationTextField else { return }

        locationTextField.autocompleteDelegate = self
        locationTextField.accessibilityIdentifier = AccessibilityIdentifiers.Browser.UrlBar.searchTextField
        locationTextField.accessibilityLabel = .URLBarLocationAccessibilityLabel
        locationContainer.addSubview(locationTextField)

        // Disable dragging urls on iPhones because it conflicts with editing the text
        if UIDevice.current.userInterfaceIdiom != .pad {
            locationTextField.textDragInteraction?.isEnabled = false
        }
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
    /// that can show in either mode.
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

    func updateTopBorderDisplay() {
        line.isHidden = isBottomSearchBar && isMicrosurveyShown
    }

    func updateReaderModeState(_ state: ReaderModeState) {
        locationView.readerModeState = state
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

        // Bug 1193755 Workaround - Calling becomeFirstResponder before the animation happens
        // won't take the initial frame of the label into consideration, which makes the label
        // look squished at the start of the animation and expand to be correct. As a workaround,
        // we becomeFirstResponder as the next event on UI thread, so the animation starts before we
        // set a first responder.
        if pasted {
            // Clear any existing text, focus the field, then set the actual pasted text.
            // This avoids highlighting all of the text.
            self.locationTextField?.text = ""
            self.isActivatingLocationTextField = true
            DispatchQueue.main.async {
                self.locationTextField?.becomeFirstResponder()
                self.setLocation(locationText, search: search)
                self.isActivatingLocationTextField = false
            }
        } else {
            self.isActivatingLocationTextField = true
            DispatchQueue.main.async {
                self.locationTextField?.becomeFirstResponder()
                // Need to set location again so text could be immediately selected.
                self.setLocation(locationText, search: search)
                self.locationTextField?.selectAll(nil)
                self.isActivatingLocationTextField = false
            }
        }
    }

    func leaveOverlayMode(reason: URLBarLeaveOverlayModeReason, shouldCancelLoading cancel: Bool) {
        // This check is a bandaid to prevent conflicts between code that might cancel overlay mode
        // incorrectly while we are still waiting to activate the location field in the next run
        // loop iteration (because the becomeFirstResponder call is dispatched). If we know that we
        // are expecting the location field to be activated, skip this and return early. [FXIOS-8421]
        guard !isActivatingLocationTextField else { return }

        locationTextField?.resignFirstResponder()
        animateToOverlayState(overlayMode: false, didCancel: cancel)
        delegate?.urlBar(self, didLeaveOverlayModeForReason: reason)
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
        bookmarksButton.alpha = inOverlayMode ? 0 : 1
        addNewTabButton.alpha = inOverlayMode ? 0 : 1
        forwardButton.alpha = inOverlayMode ? 0 : 1
        backButton.alpha = inOverlayMode ? 0 : 1
        multiStateButton.alpha = inOverlayMode ? 0 : 1

        let borderColor = inOverlayMode ? locationActiveBorderColor : locationBorderColor
        locationContainer.layer.borderColor = borderColor.cgColor

        if inOverlayMode {
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
        bookmarksButton.isHidden = !toolbarIsShowing || inOverlayMode || !topTabsIsShowing
        forwardButton.isHidden = !toolbarIsShowing || inOverlayMode
        backButton.isHidden = !toolbarIsShowing || inOverlayMode
        tabsButton.isHidden = !toolbarIsShowing || inOverlayMode || topTabsIsShowing
        multiStateButton.isHidden = !toolbarIsShowing || inOverlayMode

        // badge isHidden is tied to private mode on/off, use alpha to hide in this case
        [privateModeBadge, warningMenuBadge].forEach {
            $0.badge.alpha = (!toolbarIsShowing || inOverlayMode) ? 0 : 1
            $0.backdrop.alpha = (!toolbarIsShowing || inOverlayMode) ? 0 : BadgeWithBackdrop.UX.backdropAlpha
        }
    }

    private func animateToOverlayState(overlayMode overlay: Bool, didCancel cancel: Bool = false) {
        prepareOverlayAnimation()
        layoutIfNeeded()

        inOverlayMode = overlay

        if !overlay {
            removeLocationTextField()
        }

        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.0,
            options: [],
            animations: {
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

    @objc
    private func didClickCancel() {
        leaveOverlayMode(reason: .cancelled, shouldCancelLoading: true)
    }

    @objc
    func tappedScrollToTopArea() {
        delegate?.urlBarDidPressScrollToTop(self)
    }
}

extension URLBarView: TabToolbarProtocol {
    func privateModeBadge(visible: Bool) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            privateModeBadge.show(visible)
        }
    }

    func warningMenuBadge(setVisible: Bool) {
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
            // the button should be always enabled so that the search button is enabled on the homepage
            multiStateButton.isEnabled = true
        }
    }

    var access: [Any]? {
        get {
            if inOverlayMode {
                guard let locationTextField = locationTextField else { return nil }
                return [locationTextField, cancelButton]
            } else {
                if toolbarIsShowing {
                    return [
                        backButton,
                        forwardButton,
                        multiStateButton,
                        locationView,
                        tabsButton,
                        bookmarksButton,
                        appMenuButton,
                        addNewTabButton,
                        progressBar
                    ]
                } else {
                    return [locationView, progressBar]
                }
            }
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    func addUILargeContentViewInteraction(
        interaction: UILargeContentViewerInteraction
    ) {
        addInteraction(interaction)
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
        guard let (locationText, isSearchQuery) = delegate?.urlBarDisplayTextForURL(
            locationView.url as URL?
        ) else { return }

        var overlayText = locationText
        // Make sure to use the result from urlBarDisplayTextForURL as it is responsible
        // for extracting out search terms when on a search page
        if let text = locationText,
            let url = URL(string: text, invalidCharacters: false),
            let host = url.host,
            AppConstants.punyCode {
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
            locationView.reloadButton.reloadButtonState = .reload
            updateProgressBar(0.0)
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

    func tabLocationViewPresentCFR(at sourceView: UIView) {
        delegate?.urlBarPresentCFR(at: sourceView)
    }

    func tabLocationViewLocationAccessibilityActions(
        _ tabLocationView: TabLocationView
    ) -> [UIAccessibilityCustomAction]? {
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
        leaveOverlayMode(reason: .cancelled, shouldCancelLoading: true)
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

// MARK: ThemeApplicable
extension URLBarView: ThemeApplicable {
    func applyTheme(theme: Theme) {
        locationView.applyTheme(theme: theme)
        locationTextField?.applyTheme(theme: theme)

        actionButtons.forEach { $0.applyTheme(theme: theme) }
        tabsButton.applyTheme(theme: theme)
        addNewTabButton.applyTheme(theme: theme)

        cancelTintColor = theme.colors.textPrimary
        showQRButtonTintColor = theme.colors.textPrimary
        backgroundColor = theme.colors.layer1
        line.backgroundColor = theme.colors.borderPrimary

        locationBorderColor = theme.colors.borderPrimary
        locationView.backgroundColor = theme.colors.layer3
        locationContainer.backgroundColor = theme.colors.layer3

        privateModeBadge.badge.tintBackground(color: theme.colors.layer1)
        warningMenuBadge.badge.tintBackground(color: theme.colors.layer1)
    }
}

// MARK: - PrivateModeUI
extension URLBarView: PrivateModeUI {
    func applyUIMode(isPrivate: Bool, theme: Theme) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            privateModeBadge.show(isPrivate)
        }

        let gradientStartColor = isPrivate ? theme.colors.borderAccentPrivate : theme.colors.borderAccent
        let gradientMiddleColor = isPrivate ? nil : theme.colors.iconAccentPink
        let gradientEndColor = isPrivate ? theme.colors.borderAccentPrivate : theme.colors.iconAccentYellow
        locationActiveBorderColor = isPrivate ? theme.colors.layerAccentPrivateNonOpaque : theme.colors.layerAccentNonOpaque
        progressBar.setGradientColors(
            startColor: gradientStartColor,
            middleColor: gradientMiddleColor,
            endColor: gradientEndColor
        )
        locationTextField?.applyUIMode(isPrivate: isPrivate, theme: theme)
        locationTextField?.applyTheme(theme: theme)
        applyTheme(theme: theme)
    }
}
