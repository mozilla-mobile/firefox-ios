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
                                           StoreSubscriber,
                                           NativeErrorRegularContentViewDelegate,
                                           NativeErrorBadCertContentViewDelegate {
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
        static let badCertContentWidth: CGFloat = 311
        static let badCertContentGap: CGFloat = 16
        static let badCertImageSize: CGFloat = 160
        static let badCertGapBetweenImageAndContent: CGFloat = 40
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
        label.textAlignment = .left
        label.text = .NativeErrorPage.NoInternetConnection.TitleLabel
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.titleLabel
        label.accessibilityTraits = .header
    }

    private lazy var errorDescriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.text = .NativeErrorPage.NoInternetConnection.Description
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.errorDescriptionLabel
    }

    // MARK: Content Views

    private var currentActionView: UIView?

    private lazy var regularContentView: NativeErrorRegularContentView = {
        let view = NativeErrorRegularContentView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.configure()
        return view
    }()

    private lazy var badCertContentView: NativeErrorBadCertContentView = {
        let view = NativeErrorBadCertContentView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    // MARK: Constraints

    private var commonConstraintsList = [NSLayoutConstraint]()
    private var portraitConstraintsList = [NSLayoutConstraint]()
    private var landscapeConstraintsList = [NSLayoutConstraint]()
    private var contentStackWidthConstraint: NSLayoutConstraint?
    private var foxImageWidthConstraint: NSLayoutConstraint?
    private var foxImageHeightConstraint: NSLayoutConstraint?

    private var isLandscape: Bool {
        return UIDevice.current.isIphoneLandscape
    }

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
        tabManager: TabManager,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        overlayManager: OverlayModeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.overlayManager = overlayManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        nativeErrorPageState = NativeErrorPageState(windowUUID: windowUUID)

        super.init(
            nibName: nil,
            bundle: nil
        )

        subscribeToRedux()
        setupLayout()
        adjustConstraints()
        showViewForCurrentOrientation()
    }

    // MARK: Redux

    func newState(state: NativeErrorPageState) {
        nativeErrorPageState = state
        guard !state.title.isEmpty else { return }

        let isBadCert = state.advancedSection != nil && state.showGoBackButton
        if isBadCert {
            showBadCertUI()
        } else {
            showRegularUI()
        }
    }

    private func showRegularUI() {
        setActionView(regularContentView)
        scrollContainer.spacing = UX.mainStackSpacing
        contentStack.spacing = UX.textStackSpacing
        contentStackWidthConstraint?.isActive = false
        foxImageWidthConstraint?.constant = UX.logoSizeWidth
        foxImageHeightConstraint?.isActive = false

        titleLabel.text = nativeErrorPageState.title
        foxImage.image = UIImage(named: nativeErrorPageState.foxImage)
        if let validURL = nativeErrorPageState.url {
            errorDescriptionLabel.attributedText = getDescriptionWithHostName(
                errorURL: validURL,
                description: nativeErrorPageState.description
            )
        } else {
            errorDescriptionLabel.text = nativeErrorPageState.description
        }
        applyTheme()
    }

    private func showBadCertUI() {
        setActionView(badCertContentView)
        scrollContainer.spacing = UX.badCertGapBetweenImageAndContent
        contentStack.spacing = UX.badCertContentGap
        contentStack.setCustomSpacing(UX.badCertContentGap, after: errorDescriptionLabel)
        contentStackWidthConstraint?.constant = UX.badCertContentWidth
        contentStackWidthConstraint?.isActive = true
        foxImageWidthConstraint?.constant = UX.badCertImageSize
        foxImageHeightConstraint?.isActive = true

        foxImage.image = !nativeErrorPageState.foxImage.isEmpty
            ? UIImage(named: nativeErrorPageState.foxImage)
            : UIImage(named: ImageIdentifiers.NativeErrorPage.securityError)

        let titleString: String
        if let range = nativeErrorPageState.title.range(of: ". ") {
            titleString = nativeErrorPageState.title.replacingCharacters(in: range, with: ".\n")
        } else {
            titleString = nativeErrorPageState.title
        }
        titleLabel.text = titleString
        titleLabel.font = FXFontStyles.Bold.title2.scaledFont()
        errorDescriptionLabel.text = nativeErrorPageState.description
        errorDescriptionLabel.font = FXFontStyles.Regular.body.scaledFont()

        applyTheme()

        if let advancedSection = nativeErrorPageState.advancedSection {
            badCertContentView.configure(
                advancedSection: advancedSection,
                url: nativeErrorPageState.url,
                goBackTitle: String.NativeErrorPage.GoBackButton
            )
        }
    }

    private func setActionView(_ view: UIView) {
        currentActionView?.removeFromSuperview()
        currentActionView = view
        contentStack.addArrangedSubview(view)
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

        // TODO: Refactor to dispatch errorPageLoaded from middleware (or equivalent) per Redux best practices
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

    private func setupLayout() {
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(errorDescriptionLabel)
        contentStack.setCustomSpacing(UX.mainStackSpacing, after: errorDescriptionLabel)
        scrollContainer.addArrangedSubview(foxImage)
        scrollContainer.addArrangedSubview(contentStack)
        scrollView.addSubview(scrollContainer)
        view.addSubview(scrollView)

        contentStackWidthConstraint = contentStack.widthAnchor.constraint(
            equalToConstant: UX.badCertContentWidth
        )
        contentStackWidthConstraint?.isActive = false

        foxImageWidthConstraint = foxImage.widthAnchor.constraint(
            equalToConstant: UX.logoSizeWidth
        )
        foxImageWidthConstraint?.isActive = true

        foxImageHeightConstraint = foxImage.heightAnchor.constraint(
            equalToConstant: UX.badCertImageSize
        )
        foxImageHeightConstraint?.isActive = false
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

        landscapeConstraintsList = [
            foxImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidthiPad),
        ]

        NSLayoutConstraint.activate(commonConstraintsList)
        foxImageWidthConstraint?.isActive = !shouldUseHorizontalLayout

        if shouldUseHorizontalLayout {
            NSLayoutConstraint.activate(landscapeConstraintsList)
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
        (currentActionView as? ThemeApplicable)?.applyTheme(theme: theme)
    }

    private func dispatchBrowserAction(
        actionType: GeneralBrowserActionType,
        isNativeErrorPage: Bool = false
    ) {
        ensureMainThread {
            store.dispatch(
                GeneralBrowserAction(
                    isNativeErrorPage: isNativeErrorPage,
                    windowUUID: self.windowUUID,
                    actionType: actionType
                )
            )
        }
    }

    // MARK: - NativeErrorRegularContentViewDelegate

    func regularContentViewDidTapReload() {
        dispatchBrowserAction(actionType: .reloadWebsite, isNativeErrorPage: true)
    }

    // MARK: - NativeErrorBadCertContentViewDelegate

    func badCertContentViewDidTapGoBack() {
        dispatchBrowserAction(actionType: .navigateBack, isNativeErrorPage: true)
    }

    func badCertContentViewDidTapProceed() {
        store.dispatch(
            NativeErrorPageAction(
                windowUUID: windowUUID,
                actionType: NativeErrorPageActionType.bypassCertificateWarning
            )
        )
    }

    func badCertContentViewDidTapViewCertificate() {
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

    func badCertContentViewDidTapLearnMore() {
        guard let url = SupportUtils.URLForConnectionNotSecureLearnMore else {
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
            style: [.font: FXFontStyles.Regular.body.scaledFont()],
            highlightedText: validHostName,
            highlightedTextStyle: [.font: FXFontStyles.Bold.body.scaledFont()]
        )
        return attributedString
    }
}
