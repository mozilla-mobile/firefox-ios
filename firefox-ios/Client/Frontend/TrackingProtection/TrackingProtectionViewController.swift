// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import Common
import ComponentLibrary
import SiteImageView

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
        struct TrackingDetails {
            static let baseDistance: CGFloat = 20
            static let imageMargins: CGFloat = 10
            static let bottomDistance: CGFloat = 350
            static let viewCertButtonTopDistance: CGFloat = 8.0
        }
        struct BlockedTrackers {
            static let headerDistance: CGFloat = 8
            static let textVerticalDistance: CGFloat = 11
            static let bottomDistance: CGFloat = 235
            static let estimatedRowHeight: CGFloat = 44
            static let headerPreferredHeight: CGFloat = 24
        }
    }
}

protocol TrackingProtectionMenuDelegate: AnyObject {
    func settingsOpenPage(settings: Route.SettingsSection)
    func didFinish()
}

class TrackingProtectionViewController: UIViewController, Themeable, Notifiable, UIScrollViewDelegate {
// TODO: FXIOS-9726 #21369 - Refactor/Split TrackingProtectionViewController UI into more custom views
class TrackingProtectionViewController: UIViewController,
                                        Themeable,
                                        Notifiable,
                                        BottomSheetChild,
                                        UIScrollViewDelegate {

    var themeManager: ThemeManager
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
    private var headerContainer: TrackingProtectionHeaderView = .build()

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

    private var viewModel: TrackingProtectionModel
    private var hasSetPointOrigin = false
    private var pointOrigin: CGPoint?
    var asPopover = false

    private var toggleContainerShouldBeHidden: Bool {
        return !viewModel.globalETPIsEnabled
    }

    private var protectionViewTopConstraint: NSLayoutConstraint?

    // MARK: - View lifecycle

    init(viewModel: TrackingProtectionModel,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
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
        updateProtectionViewStatus()
        applyTheme()
        getCertificates(for: viewModel.url) { [weak self] certificates in
            if let certs = certificates {
                self?.viewModel.certificates = certs
            }
        }
    }

    private func setupView() {
        constraints.removeAll()

        setupHeaderView()
        setupContentView()
        setupConnectionHeaderView()
        setupBlockedTrackersView()
        setupConnectionStatusView()
        setupToggleView()
        setupClearCookiesButton()
        setupProtectionSettingsView()
        setupViewActions()

        NSLayoutConstraint.activate(constraints)
        setupAccessibilityIdentifiers()
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

    // MARK: Blocked Trackers Setup
    private func setupBlockedTrackersView() {
        baseView.addSubview(trackersConnectionContainer)
        trackersConnectionContainer.addArrangedSubview(trackersView)
        let blockedTrackersConstraints = [
            trackersView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            trackersView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            trackersView.topAnchor.constraint(equalTo: connectionDetailsHeaderView.bottomAnchor),
        ]
        constraints.append(contentsOf: blockedTrackersConstraints)
        trackersView.trackersButtonCallback = {}
    }

    // MARK: Connection Status Setup
    private func setupConnectionStatusView() {
        trackersConnectionContainer.addArrangedSubview(connectionStatusView)
        connectionStatusView.addSubviews(connectionHorizontalLine)
        let connectionConstraints = [
            connectionStatusView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionStatusView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            connectionStatusView.topAnchor.constraint(equalTo: trackersView.bottomAnchor),
            connectionHorizontalLine.leadingAnchor.constraint(equalTo: connectionStatusView.leadingAnchor),
            connectionHorizontalLine.trailingAnchor.constraint(equalTo: connectionStatusView.trailingAnchor),
            connectionHorizontalLine.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
            connectionStatusView.bottomAnchor.constraint(equalTo: connectionHorizontalLine.bottomAnchor)
        ]
        constraints.append(contentsOf: connectionConstraints)
        connectionStatusView.connectionStatusButtonCallback = {
            // TODO: FXIOS-9198 #20366 Enhanced Tracking Protection Connection details screen
            //        let detailsVC = TrackingProtectionDetailsViewController(with: viewModel.getDetailsModel(),
            //                                                                windowUUID: windowUUID)
            //        detailsVC.modalPresentationStyle = .pageSheet
            //        self.present(detailsVC, animated: true)
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
                equalTo: connectionStatusView.bottomAnchor,
                constant: 0
            )
        ]
        constraints.append(contentsOf: toggleConstraints)
        toggleView.toggleSwitchedCallback = { [weak self] in
            // site is safelisted if site ETP is disabled
            self?.viewModel.toggleSiteSafelistStatus()
            self?.updateProtectionViewStatus()
        }
    }

    // MARK: Clear Cookies Button Setup
    private func setupClearCookiesButton() {
        let clearCookiesViewModel = TrackingProtectionButtonModel(title: viewModel.clearCookiesButtonTitle,
                                                                  a11yIdentifier: viewModel.clearCookiesButtonA11yId)
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
            ),
            clearCookiesButton.bottomAnchor.constraint(
                equalTo: settingsLinkButton.topAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
        ]
        constraints.append(contentsOf: clearCookiesButtonConstraints)
    }

    // MARK: Settings View Setup
    private func setupProtectionSettingsView() {
        let settingsButtonViewModel = LinkButtonViewModel(title: viewModel.settingsButtonTitle,
                                                          a11yIdentifier: viewModel.settingsA11yId)
        settingsLinkButton.configure(viewModel: settingsButtonViewModel)
        baseView.addSubviews(settingsLinkButton)

        let protectionConstraints = [
            settingsLinkButton.leadingAnchor.constraint(equalTo: baseView.leadingAnchor),
            settingsLinkButton.trailingAnchor.constraint(equalTo: baseView.trailingAnchor),
            settingsLinkButton.bottomAnchor.constraint(
                equalTo: baseView.bottomAnchor,
                constant: -TPMenuUX.UX.settingsLinkButtonBottomSpacing
            ),
        ]

        constraints.append(contentsOf: protectionConstraints)
    }

    private func updateViewDetails() {
        let headerIcon = FaviconImageViewModel(siteURLString: viewModel.url.absoluteString,
                                               faviconCornerRadius: TPMenuUX.UX.faviconCornerRadius)
        headerContainer.setupDetails(website: viewModel.websiteTitle,
                                     display: viewModel.displayTitle,
                                     icon: headerIcon)

        connectionDetailsHeaderView.setupDetails(title: viewModel.connectionDetailsTitle,
                                                 status: viewModel.connectionDetailsHeader,
                                                 image: viewModel.connectionDetailsImage)

        trackersView.setupDetails(for: viewModel.contentBlockerStats?.total)
        connectionStatusView.setupDetails(image: viewModel.getConnectionStatusImage(themeType: currentTheme().type),
                                          text: viewModel.connectionStatusString)

        toggleView.setupDetails(isOn: viewModel.isSiteETPEnabled)
        viewModel.isProtectionEnabled = toggleView.toggleIsOn
    }

    private func setupViewActions() {
        headerContainer.setupActions()
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
        connectionDetailsHeaderView.setupAccessibilityIdentifiers(foxImageA11yId: viewModel.foxImageA11yId)
        trackersView.setupAccessibilityIdentifiers(
            arrowImageA11yId: viewModel.arrowImageA11yId,
            trackersBlockedLabelA11yId: viewModel.trackersBlockedLabelA11yId,
            shieldImageA11yId: viewModel.settingsA11yId)
        connectionStatusView.setupAccessibilityIdentifiers(
            arrowImageA11yId: viewModel.arrowImageA11yId,
            securityStatusLabelA11yId: viewModel.securityStatusLabelA11yId)
        toggleView.setupAccessibilityIdentifiers(
            toggleViewTitleLabelA11yId: viewModel.toggleViewTitleLabelA11yId,
            toggleViewBodyLabelA11yId: viewModel.toggleViewBodyLabelA11yId)
        clearCookiesButton.accessibilityIdentifier = viewModel.clearCookiesButtonA11yId
        settingsLinkButton.accessibilityIdentifier = viewModel.settingsA11yId
    }

    private func adjustLayout() {
        headerContainer.adjustLayout()
        trackersView.adjustLayout()
        connectionStatusView.adjustLayout()

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
    private func didTapClearCookiesAndSiteData() {
        viewModel.onTapClearCookiesAndSiteData(controller: self)
    }

    @objc
    func protectionSettingsTapped() {
        enhancedTrackingProtectionMenuDelegate?.settingsOpenPage(settings: .contentBlocker)
    }

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
        if toggleView.toggleIsOn {
            toggleView.setStatusLabelText(with: .Menu.EnhancedTrackingProtection.switchOnText)
            trackersView.setVisibility(isHidden: false)
            viewModel.isProtectionEnabled = true
        } else {
            toggleView.setStatusLabelText(with: .Menu.EnhancedTrackingProtection.switchOffText)
            trackersView.setVisibility(isHidden: true)
            viewModel.isProtectionEnabled = false
        }
        connectionDetailsHeaderView.setupDetails(color: viewModel.getConnectionDetailsBackgroundColor(theme: currentTheme()),
                                                 title: viewModel.connectionDetailsTitle,
                                                 status: viewModel.connectionDetailsHeader,
                                                 image: viewModel.connectionDetailsImage)
    }
}

// MARK: - Themable
extension TrackingProtectionViewController {
    func applyTheme() {
        let theme = currentTheme()
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor = theme.colors.layer1
        headerContainer.applyTheme(theme: theme)
        connectionDetailsHeaderView.backgroundColor = theme.colors.layer2
        trackersView.applyTheme(theme: theme)
        connectionStatusView.applyTheme(theme: theme)
        connectionStatusView.setConnectionStatusImage(image: viewModel.getConnectionStatusImage(themeType: theme.type),
                                                      isConnectionSecure: viewModel.connectionSecure,
                                                      theme: theme)
        connectionHorizontalLine.backgroundColor = theme.colors.borderPrimary
        toggleView.applyTheme(theme: theme)
        clearCookiesButton.applyTheme(theme: theme)
        clearCookiesButton.layer.borderColor = theme.colors.borderPrimary.cgColor
        settingsLinkButton.applyTheme(theme: theme)
        setNeedsStatusBarAppearanceUpdate()
    }
}
