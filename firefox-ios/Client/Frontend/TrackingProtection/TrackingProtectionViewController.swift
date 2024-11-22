// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import Common
import ComponentLibrary
import SiteImageView
import Redux

struct TPMenuUX {
    struct UX {
        static let popoverTopDistance: CGFloat = 16
        static let horizontalMargin: CGFloat = 16
        static let viewCornerRadius: CGFloat = 8
        static let headerLabelDistance: CGFloat = 2.0
        static let iconSize: CGFloat = 24
        static let connectionDetailsHeaderMargins: CGFloat = 8
        static let faviconCornerRadius: CGFloat = 5
        static let clearDataButtonCornerRadius: CGFloat = 12
        static let clearDataButtonBorderWidth: CGFloat = 1
        static let settingsLinkButtonBottomSpacing: CGFloat = 32
        static let modalMenuCornerRadius: CGFloat = 12
        struct Line {
            static let height: CGFloat = 1
        }
    }
}

protocol TrackingProtectionMenuDelegate: AnyObject {
    func settingsOpenPage(settings: Route.SettingsSection)
    func didFinish()
}

class TrackingProtectionViewController: UIViewController,
                                        Themeable,
                                        Notifiable,
                                        StoreSubscriber,
                                        UIScrollViewDelegate {
    var themeManager: ThemeManager
    var profile: Profile?
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    weak var enhancedTrackingProtectionMenuDelegate: TrackingProtectionMenuDelegate?

    private var foxImageHeightConstraint: NSLayoutConstraint?

    private lazy var scrollView: UIScrollView = .build { scrollView in
        scrollView.showsVerticalScrollIndicator = false
    }

    private let baseView: UIView = .build()

    // MARK: UI components Header View
    private var headerContainer: HeaderView = .build()

    // MARK: Connection Details View
    private var connectionDetailsHeaderView: TrackingProtectionConnectionDetailsView = .build()

    // MARK: Blocked Trackers View
    private var trackersView: TrackingProtectionBlockedTrackersView = .build()
    private var trackersConnectionContainer: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fillProportionally
        stack.alignment = .leading
        stack.axis = .vertical
    }

    // MARK: Connection Status View
    private let connectionStatusView: TrackingProtectionConnectionStatusView = .build()
    private let connectionHorizontalLine: UIView = .build()

    // MARK: Toggle View
    private let toggleView: TrackingProtectionToggleView = .build()

    // MARK: Clear Cookies View
    private lazy var clearCookiesButton: TrackingProtectionButton = .build { button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.layer.cornerRadius = TPMenuUX.UX.clearDataButtonCornerRadius
        button.layer.borderWidth = TPMenuUX.UX.clearDataButtonBorderWidth
        button.addTarget(self, action: #selector(self.didTapClearCookiesAndSiteData), for: .touchUpInside)
    }

    // MARK: Protection setting view
    private lazy var settingsLinkButton: LinkButton = .build { button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.protectionSettingsTapped), for: .touchUpInside)
    }

    private var constraints = [NSLayoutConstraint]()

    // MARK: - Variables

    private var model: TrackingProtectionModel
    private var trackingProtectionState: TrackingProtectionState
    private var blockedTrackersVC: BlockedTrackersTableViewController?
    private var hasSetPointOrigin = false
    private var pointOrigin: CGPoint?
    var asPopover = false

    private var toggleContainerShouldBeHidden: Bool {
        return !model.globalETPIsEnabled
    }

    private var protectionViewTopConstraint: NSLayoutConstraint?

    // MARK: - View lifecycle

    init(viewModel: TrackingProtectionModel,
         profile: Profile,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.model = viewModel
        self.profile = profile
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        trackingProtectionState = TrackingProtectionState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)
        subscribeToRedux()
    }

    deinit {
        unsubscribeFromRedux()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if !asPopover {
            addGestureRecognizer()
        }
        setupView()
        listenForThemeChange(view)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        scrollView.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.invalidateIntrinsicContentSize() // Adjusts size based on content.
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
        applyTheme()
        getCertificates(for: model.url) { [weak self] certificates in
            if let certificates {
                ensureMainThread {
                    self?.model.certificates = certificates
                }
            }
        }
    }

    private func setupView() {
        constraints.removeAll()

        setupHeaderView()
        setupContentView()
        setupConnectionHeaderView()
        setupTrackersConnectionView()
        setupToggleView()
        setupClearCookiesButton()
        setupProtectionSettingsView()
        setupViewActions()

        NSLayoutConstraint.activate(constraints)
        setupAccessibilityIdentifiers()
    }

    // MARK: Redux
    func newState(state: TrackingProtectionState) {
        trackingProtectionState = state
        if let navigateTo = state.navigateTo {
            // TODO: FXIOS-10657 connect the ETP navigation with the BVC general navigation
        }
        if let displayView = state.displayView {
            switch displayView {
            case .blockedTrackersDetails:
                showBlockedTrackersController()
            case .trackingProtectionDetails:
                showTrackersDetailsController()
            case .certificatesDetails:
                break
            case .clearCookiesAlert:
                onTapClearCookiesAndSiteData()
            }
        }
        if trackingProtectionState.shouldClearCookies {
            clearCookies()
        } else if trackingProtectionState.shouldUpdateBlockedTrackerStats {
            updateBlockedTrackersCount()
        } else if trackingProtectionState.shouldUpdateConnectionStatus {
            updateConnectionStatus()
        }
    }

    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .trackingProtection)
        store.dispatch(action)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return TrackingProtectionState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .trackingProtection)
        store.dispatch(action)
    }

    // MARK: Content View
    private func setupContentView() {
        view.addSubview(scrollView)

        let scrollViewConstraints = [
            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]

        constraints.append(contentsOf: scrollViewConstraints)
        scrollView.addSubview(baseView)

        let baseViewConstraints = [
            baseView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            baseView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            baseView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            baseView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            baseView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ]

        constraints.append(contentsOf: baseViewConstraints)
    }

    // MARK: Header Setup
    private func setupHeaderView() {
        view.addSubview(headerContainer)
        let headerConstraints = [
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: asPopover ? TPMenuUX.UX.popoverTopDistance : 0
            )
        ]
        constraints.append(contentsOf: headerConstraints)
        headerContainer.closeButtonCallback = { [weak self] in
            self?.enhancedTrackingProtectionMenuDelegate?.didFinish()
        }
    }

    // MARK: Connection Status Header Setup
    private func setupConnectionHeaderView() {
        baseView.addSubviews(connectionDetailsHeaderView)
        let connectionHeaderConstraints = [
            connectionDetailsHeaderView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionDetailsHeaderView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            connectionDetailsHeaderView.topAnchor.constraint(
                equalTo: baseView.topAnchor,
                constant: TPMenuUX.UX.connectionDetailsHeaderMargins),
        ]
        constraints.append(contentsOf: connectionHeaderConstraints)
    }

    // MARK: Trackers Connection Setup
    private func setupTrackersConnectionView() {
        baseView.addSubview(trackersConnectionContainer)
        baseView.addSubview(connectionHorizontalLine)
        trackersConnectionContainer.addArrangedSubview(trackersView)
        trackersConnectionContainer.addArrangedSubview(connectionStatusView)
        let trackersConnectionConstraints = [
            trackersView.trailingAnchor.constraint(equalTo: trackersConnectionContainer.trailingAnchor),
            connectionStatusView.trailingAnchor.constraint(equalTo: trackersConnectionContainer.trailingAnchor),
            trackersConnectionContainer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            trackersConnectionContainer.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            trackersConnectionContainer.topAnchor.constraint(equalTo: connectionDetailsHeaderView.bottomAnchor),
            connectionHorizontalLine.topAnchor.constraint(equalTo: trackersConnectionContainer.bottomAnchor),
            connectionHorizontalLine.leadingAnchor.constraint(equalTo: trackersConnectionContainer.leadingAnchor),
            connectionHorizontalLine.trailingAnchor.constraint(equalTo: trackersConnectionContainer.trailingAnchor),
            connectionHorizontalLine.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
        ]
        constraints.append(contentsOf: trackersConnectionConstraints)
        trackersView.trackersButtonCallback = { [weak self] in
            guard let self else { return }
            store.dispatch(
                TrackingProtectionAction(windowUUID: windowUUID,
                                         actionType: TrackingProtectionActionType.tappedShowBlockedTrackers)
            )
        }
        connectionStatusView.connectionStatusButtonCallback = { [weak self] in
            guard let self, model.connectionSecure else { return }
            store.dispatch(
                TrackingProtectionAction(windowUUID: windowUUID,
                                         actionType: TrackingProtectionActionType.tappedShowTrackingProtectionDetails)
            )
        }
    }

    // MARK: Toggle View Setup
    private func setupToggleView() {
        baseView.addSubview(toggleView)
        let toggleConstraints = [
            toggleView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor,
                                                constant: TPMenuUX.UX.horizontalMargin),
            toggleView.trailingAnchor.constraint(equalTo: baseView.trailingAnchor,
                                                 constant: -TPMenuUX.UX.horizontalMargin),
            toggleView.topAnchor.constraint(
                equalTo: connectionHorizontalLine.bottomAnchor,
                constant: 0
            )
        ]
        constraints.append(contentsOf: toggleConstraints)
        toggleView.toggleSwitchedCallback = { [weak self] in
            // site is safelisted if site ETP is disabled
            self?.model.toggleSiteSafelistStatus()
            self?.updateProtectionViewStatus()
        }
    }

    // MARK: Clear Cookies Button Setup
    private func setupClearCookiesButton() {
        let clearCookiesViewModel = TrackingProtectionButtonModel(title: model.clearCookiesButtonTitle,
                                                                  a11yIdentifier: model.clearCookiesButtonA11yId)
        clearCookiesButton.configure(viewModel: clearCookiesViewModel)
        baseView.addSubview(clearCookiesButton)

        let clearCookiesButtonConstraints = [
            clearCookiesButton.leadingAnchor.constraint(
                equalTo: baseView.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            clearCookiesButton.trailingAnchor.constraint(
                equalTo: baseView.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            clearCookiesButton.topAnchor.constraint(
                equalTo: toggleView.bottomAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            )
        ]
        constraints.append(contentsOf: clearCookiesButtonConstraints)
    }

    // MARK: Settings View Setup
    private func configureProtectionSettingsView() {
        let settingsButtonViewModel = LinkButtonViewModel(title: model.settingsButtonTitle,
                                                          a11yIdentifier: model.settingsA11yId)
        settingsLinkButton.configure(viewModel: settingsButtonViewModel)
    }

    private func setupProtectionSettingsView() {
        configureProtectionSettingsView()
        baseView.addSubviews(settingsLinkButton)

        let protectionConstraints = [
            settingsLinkButton.leadingAnchor.constraint(equalTo: baseView.leadingAnchor),
            settingsLinkButton.trailingAnchor.constraint(equalTo: baseView.trailingAnchor),
            settingsLinkButton.topAnchor.constraint(equalTo: clearCookiesButton.bottomAnchor,
                                                    constant: TPMenuUX.UX.horizontalMargin),
            settingsLinkButton.bottomAnchor.constraint(
                equalTo: baseView.bottomAnchor,
                constant: -TPMenuUX.UX.settingsLinkButtonBottomSpacing
            ),
        ]

        constraints.append(contentsOf: protectionConstraints)
    }

    private func updateViewDetails() {
        let headerIcon = FaviconImageViewModel(siteURLString: model.url.absoluteString,
                                               faviconCornerRadius: TPMenuUX.UX.faviconCornerRadius)
        headerContainer.setupDetails(subtitle: model.websiteTitle,
                                     title: model.displayTitle,
                                     icon: headerIcon)

        updateBlockedTrackersCount()
        updateConnectionStatus()

        toggleView.setupDetails(isOn: !model.isURLSafelisted())
        model.isProtectionEnabled = toggleView.toggleIsOn
        updateProtectionViewStatus()
    }

    private func updateBlockedTrackersCount() {
        model.contentBlockerStats = model.selectedTab?.contentBlocker?.stats
        blockedTrackersVC?.model.contentBlockerStats = model.selectedTab?.contentBlocker?.stats
        blockedTrackersVC?.applySnapshot()
        trackersView.setupDetails(for: model.contentBlockerStats?.total)
        updateConnectionStatus()
    }

    private func updateConnectionStatus() {
        model.connectionSecure = model.selectedTab?.webView?.hasOnlySecureContent ?? false
        connectionStatusView.setConnectionStatus(image: model.getConnectionStatusImage(themeType: currentTheme().type),
                                                 text: model.connectionStatusString,
                                                 isConnectionSecure: model.connectionSecure,
                                                 theme: currentTheme())
        connectionDetailsHeaderView.setupDetails(title: model.connectionDetailsTitle,
                                                 status: model.connectionDetailsHeader,
                                                 image: model.connectionDetailsImage)
    }

    private func setupViewActions() {
        trackersView.setupActions()
        connectionStatusView.setupActions()
        toggleView.setupActions()
    }

    // MARK: Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.adjustLayout()
        }, completion: nil)
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        connectionDetailsHeaderView.setupAccessibilityIdentifiers(foxImageA11yId: model.foxImageA11yId)
        trackersView.setupAccessibilityIdentifiers(
            arrowImageA11yId: model.arrowImageA11yId,
            trackersBlockedLabelA11yId: model.trackersBlockedLabelA11yId,
            shieldImageA11yId: model.settingsA11yId)
        connectionStatusView.setupAccessibilityIdentifiers(
            arrowImageA11yId: model.arrowImageA11yId,
            securityStatusLabelA11yId: model.securityStatusLabelA11yId)
        toggleView.setupAccessibilityIdentifiers(
            toggleViewTitleLabelA11yId: model.toggleViewTitleLabelA11yId,
            toggleViewBodyLabelA11yId: model.toggleViewBodyLabelA11yId)
        headerContainer.setupAccessibility(closeButtonA11yLabel: model.closeButtonA11yLabel,
                                           closeButtonA11yId: model.closeButtonA11yId)
        clearCookiesButton.accessibilityIdentifier = model.clearCookiesButtonA11yId
        settingsLinkButton.accessibilityIdentifier = model.settingsA11yId
    }

    private func adjustLayout() {
        headerContainer.adjustLayout(isWebsiteIcon: true)
        trackersView.adjustLayout()
        connectionStatusView.adjustLayout()
        connectionDetailsHeaderView.adjustLayout()
        toggleView.adjustLayout()
        configureProtectionSettingsView()

        if #available(iOS 16.0, *), UIDevice.current.userInterfaceIdiom == .phone {
            headerContainer.layoutIfNeeded()
            scrollView.layoutIfNeeded()
            let contentHeight = headerContainer.frame.height + scrollView.contentSize.height
            let customDetent = UISheetPresentationController.Detent.custom { context in
                return contentHeight
            }
            self.sheetPresentationController?.detents = [customDetent]
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Button actions

    @objc
    func trackingProtectionToggleTapped() {
        // site is safelisted if site ETP is disabled
        model.toggleSiteSafelistStatus()
        updateProtectionViewStatus()
    }

    @objc
    private func didTapClearCookiesAndSiteData() {
        store.dispatch(
            TrackingProtectionAction(windowUUID: windowUUID,
                                     actionType: TrackingProtectionActionType.tappedShowClearCookiesAlert)
        )
    }

    @objc
    func protectionSettingsTapped() {
        store.dispatch(
            TrackingProtectionAction(windowUUID: windowUUID,
                                     actionType: TrackingProtectionActionType.tappedShowSettings)
        )
    }

    private func showBlockedTrackersController() {
        blockedTrackersVC = BlockedTrackersTableViewController(with: model.getBlockedTrackersModel(),
                                                               windowUUID: windowUUID)
        self.navigationController?.pushViewController(blockedTrackersVC ?? UIViewController(), animated: true)
    }

    private func showTrackersDetailsController() {
        let detailsVC = TrackingProtectionDetailsViewController(with: model.getDetailsModel(),
                                                                windowUUID: windowUUID)
        self.navigationController?.pushViewController(detailsVC, animated: true)
    }

    // MARK: Clear Cookies Alert
    func onTapClearCookiesAndSiteData() {
        model.onTapClearCookiesAndSiteData(controller: self)
    }

    func clearCookies() {}

    // MARK: - Gesture Recognizer
    private func addGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
    }

    @objc
    func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let originalYPosition = self.view.frame.origin.y
        let originalXPosition = self.view.frame.origin.x

        // Not allowing the user to drag the view upward
        guard translation.y >= 0 else { return }

        // Setting x based on window calculation because we don't want
        // users to move the frame side ways, only straight up or down
        view.frame.origin = CGPoint(x: originalXPosition,
                                    y: self.pointOrigin!.y + translation.y)

        if sender.state == .ended {
            let dragVelocity = sender.velocity(in: view)
            if dragVelocity.y >= 1300 {
                enhancedTrackingProtectionMenuDelegate?.didFinish()
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: originalXPosition, y: originalYPosition)
                }
            }
        }
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    // MARK: - Update Views
    private func updateProtectionViewStatus() {
        let isContentBlockingConfigEnabled = profile?.prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? true
        if toggleView.toggleIsOn, isContentBlockingConfigEnabled {
            toggleView.setStatusLabelText(with: .Menu.EnhancedTrackingProtection.switchOnText)
            trackersView.setVisibility(isHidden: false)
            model.isProtectionEnabled = true
        } else {
            toggleView.setStatusLabelText(with: .Menu.EnhancedTrackingProtection.switchOffText)
            trackersView.setVisibility(isHidden: true)
            model.isProtectionEnabled = false
        }
        toggleView.setToggleSwitchVisibility(with: !isContentBlockingConfigEnabled)
        connectionDetailsHeaderView.setupDetails(color: model.getConnectionDetailsBackgroundColor(theme: currentTheme()),
                                                 title: model.connectionDetailsTitle,
                                                 status: model.connectionDetailsHeader,
                                                 image: model.connectionDetailsImage)
        adjustLayout()
    }
}

// MARK: - Themable
extension TrackingProtectionViewController {
    func applyTheme() {
        let theme = currentTheme()
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor = theme.colors.layer3
        headerContainer.applyTheme(theme: theme)
        connectionDetailsHeaderView.applyTheme(theme: theme)
        trackersView.applyTheme(theme: theme)
        connectionStatusView.applyTheme(theme: theme)
        connectionHorizontalLine.backgroundColor = theme.colors.borderPrimary
        toggleView.applyTheme(theme: theme)
        clearCookiesButton.applyTheme(theme: theme)
        settingsLinkButton.applyTheme(theme: theme)
        setNeedsStatusBarAppearanceUpdate()
    }
}
