// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary
import Redux
import Shared

final class NativeErrorPageViewController: UIViewController,
                                           Themeable,
                                           ContentContainable,
                                           StoreSubscriber {
    typealias SubscriberStateType = NativeErrorPageState
    private let windowUUID: WindowUUID

    // MARK: Themeable Variables
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: UUID? {
        windowUUID
    }

    private var overlayManager: OverlayModeManager
    private let tabManager: TabManager
    private let logger: Logger
    var contentType: ContentType = .nativeErrorPage
    private var nativeErrorPageState: NativeErrorPageState

    // MARK: UI Elements
    private struct UX {
        static let logoSizeWidth: CGFloat = 221
        static let logoSizeWidthiPad: CGFloat = 240
        static let mainStackSpacing: CGFloat = 24
        static let textStackSpacing: CGFloat = 16
        static let portraitPadding = NSDirectionalEdgeInsets(
            top: 120,
            leading: 32,
            bottom: -16,
            trailing: -32
        )
        static let landscapePadding = NSDirectionalEdgeInsets(
            top: 60,
            leading: 64,
            bottom: -16,
            trailing: -64
        )
    }

    private lazy var scrollView: UIScrollView = .build()

    private lazy var scrollContainer: UIStackView = .build { stackView in
        stackView.spacing = UX.mainStackSpacing
    }

    private lazy var contentStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = UX.textStackSpacing
    }

    private lazy var foxImage: UIImageView = .build { imageView in
        imageView.image = UIImage(
            named: ImageIdentifiers.NativeErrorPage.noInternetConnection
        )
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.foxImage
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.title2.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = .NativeErrorPage.NoInternetConnection.TitleLabel
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.titleLabel
        label.accessibilityTraits = .header
    }

    private lazy var errorDescriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = .NativeErrorPage.NoInternetConnection.Description
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.errorDescriptionLabel
    }

    private lazy var reloadButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapReload), for: .touchUpInside)
        button.isEnabled = true
    }

    private var commonConstraintsList = [NSLayoutConstraint]()
    private var portraitConstraintsList = [NSLayoutConstraint]()
    private var landscapeConstraintsList = [NSLayoutConstraint]()

    private var isLandscape: Bool {
        return UIDevice.current.isIphoneLandscape
    }

    // Helper function to switch layout to 'portrait' is ContentSizeCategory is large or more
    private var isLargeContentSizeCategory: Bool {
        switch traitCollection.preferredContentSizeCategory {
        case .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }

    /// Determines whether the layout should use a horizontal axis based on
    /// the current device type, orientation, and Dynamic Type settings.
    /// - If the **content size category** is large, the layout always uses a **vertical** axis
    /// - Otherwise, if the device is an **iPad**, the layout uses a **horizontal** axis,
    ///   as there is sufficient screen space for side-by-side elements.
    /// - On **iPhone**, the layout is horizontal only when in **landscape** orientation.
    ///
    /// - Returns: `true` if a horizontal layout should be used; `false` if vertical.
    private var shouldUseHorizontalLayout: Bool {
        guard !isLargeContentSizeCategory else { return false }

        if shouldUseiPadSetup() {
            return true
        } else {
            return isLandscape
        }
    }

   init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        overlayManager: OverlayModeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        tabManager: TabManager,
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.overlayManager = overlayManager
        self.notificationCenter = notificationCenter
        self.tabManager = tabManager
        self.logger = logger
        nativeErrorPageState = NativeErrorPageState(windowUUID: windowUUID)

        super.init(
            nibName: nil,
            bundle: nil
        )

        subscribeToRedux()
        configureUI()
        setupLayout()
        adjustConstraints()
        showViewForCurrentOrientation()
    }

    // MARK: Redux
    func newState(state: NativeErrorPageState) {
        nativeErrorPageState = state

        if !state.title.isEmpty {
            titleLabel.text = state.title
            foxImage.image = UIImage(named: nativeErrorPageState.foxImage)

            if let validURL = state.url {
                let errorDescription = getDescriptionWithHostName(
                    errorURL: validURL,
                    description: state.description
                )
                errorDescriptionLabel.attributedText = errorDescription
            } else {
                errorDescriptionLabel.text = state.description
            }
        } else {
            return
        }
    }

    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .nativeErrorPage)
        store.dispatch(action)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return NativeErrorPageState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: self.windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .nativeErrorPage)
        store.dispatch(action)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            assertionFailure("AddressBarPanGestureHandler was not deallocated on the main thread. Observer was not removed")
            return
        }

        MainActor.assumeIsolated {
            unsubscribeFromRedux()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()

        store.dispatch(NativeErrorPageAction(windowUUID: windowUUID,
                                             actionType: NativeErrorPageActionType.errorPageLoaded))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.accessibilityViewIsModal = true
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(
            to: size,
            with: coordinator
        )
        adjustConstraints()
        showViewForCurrentOrientation()
    }

    private func configureUI() {
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .NativeErrorPage.ButtonLabel,
            a11yIdentifier: AccessibilityIdentifiers.NativeErrorPage.reloadButton
        )
        reloadButton.configure(
            viewModel: viewModel
        )
    }

    private func setupLayout() {
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(errorDescriptionLabel)
        contentStack.setCustomSpacing(UX.mainStackSpacing, after: errorDescriptionLabel)
        contentStack.addArrangedSubview(reloadButton)
        scrollContainer.addArrangedSubview(foxImage)
        scrollContainer.addArrangedSubview(contentStack)
        scrollView.addSubview(scrollContainer)
        view.addSubview(scrollView)
    }

    func adjustConstraints() {
        NSLayoutConstraint.deactivate(portraitConstraintsList + landscapeConstraintsList + commonConstraintsList)
        commonConstraintsList = [
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            scrollView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            scrollContainer.topAnchor.constraint(
                equalTo: scrollView.topAnchor,
                constant: isLandscape ? UX.landscapePadding.top : UX.portraitPadding.top
            ),
            scrollContainer.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: isLandscape ? UX.landscapePadding.leading : UX.portraitPadding.leading
            ),
            scrollContainer.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: isLandscape ? UX.landscapePadding.trailing : UX.portraitPadding.trailing
            ),
            scrollContainer.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor,
                constant: isLandscape ? UX.landscapePadding.bottom : UX.portraitPadding.bottom
            ),
        ]

        portraitConstraintsList = [
            foxImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidth)
        ]

        landscapeConstraintsList = [
            foxImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidthiPad),
            reloadButton.widthAnchor.constraint(
                equalTo: contentStack.widthAnchor
            )
        ]

        NSLayoutConstraint.activate(commonConstraintsList)

        if shouldUseHorizontalLayout {
            NSLayoutConstraint.activate(landscapeConstraintsList)
        } else {
            NSLayoutConstraint.activate(portraitConstraintsList)
        }
    }

    private func showViewForCurrentOrientation() {
        scrollContainer.axis = shouldUseHorizontalLayout ? .horizontal : .vertical
    }

    // MARK: ThemeApplicable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        errorDescriptionLabel.textColor = theme.colors.textPrimary
        reloadButton.applyTheme(theme: theme)
    }

    @objc
    private func didTapReload() {
        ensureMainThread {
            store.dispatch(
                GeneralBrowserAction(
                    isNativeErrorPage: true,
                    windowUUID: self.windowUUID,
                    actionType: GeneralBrowserActionType.reloadWebsite
                )
            )
        }
    }

    @objc
    private func didTapViewCertificate() {
        guard let selectedTab = tabManager.selectedTab,
              let errorURL = selectedTab.webView?.url,
              let internalURL = InternalURL(errorURL),
              internalURL.isErrorPage else { return }
        let originalURL = nativeErrorPageState.url ?? internalURL.originalURLFromErrorPage ?? errorURL
        guard !CertificateHelper.certificatesFromErrorURL(errorURL, logger: logger).isEmpty else { return }

        let destination = NavigationDestination(
            .certificatesFromErrorPage,
            url: originalURL,
            errorPageURL: errorURL,
            certificateTitle: nativeErrorPageState.title
        )
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: destination,
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnShowCertificatesFromErrorPage
            )
        )
    }

    @objc
    private func didTapLearnMore() {
        guard let url = SupportUtils.URLForTopic("what-does-your-connection-is-not-secure-mean") else {
            logger.log(
                "NativeErrorPage: Unable to create Learn More support URL",
                level: .warning,
                category: .lifecycle
            )
            return
        }

        let destination = NavigationDestination(.nativeErrorPageLearnMore, url: url)
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: destination,
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnNativeErrorPageLearnMore
            )
        )
    }

    func getDescriptionWithHostName(errorURL: URL, description: String) -> NSAttributedString? {
        guard let validHostName = errorURL.host else { return nil }

        let errDescription = String(format: description, validHostName)
        let attributedString = errDescription.attributedText(
            style: [.font: FXFontStyles.Regular.subheadline.scaledFont()],
            highlightedText: validHostName,
            highlightedTextStyle: [.font: FXFontStyles.Bold.body.scaledFont()]
        )
        return attributedString
    }
}
