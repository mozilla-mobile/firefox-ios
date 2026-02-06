// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary
import Redux
import Shared
import X509

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
    /// Layout-only constants (no-internet and bad cert). Typography and colors come from FXFontStyles + theme.
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
        // Advanced section (bad cert) – layout only; typography/colors from FXFontStyles + theme
        static let advancedSectionBorderWidth: CGFloat = 1
        static let advancedSectionCornerRadius: CGFloat = 12
        static let advancedSectionPadding: CGFloat = 11
        static let advancedSectionPaddingBottom: CGFloat = 10
        static let advancedSectionListItemPadding: CGFloat = 6.5
        static let advancedSectionListItemHorizontalPadding: CGFloat = 16
        static let advancedSectionHeaderHeight: CGFloat = 24
        static let advancedSectionChevronSize: CGFloat = 24
        static let advancedSectionLinkRowHeight: CGFloat = 44
        static let buttonCornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 45
        static let buttonPaddingVertical: CGFloat = 12
        static let buttonPaddingHorizontal: CGFloat = 16
        static let badCertContentWidth: CGFloat = 311
        static let badCertContentGap: CGFloat = 16
        static let badCertImageSize: CGFloat = 160
        static let badCertGapBetweenImageAndContent: CGFloat = 40
        // Proceed button container 
        static let badCertProceedContainerPadding: CGFloat = 8
        static let badCertProceedContainerGap: CGFloat = 10
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

    private lazy var reloadButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapReload), for: .touchUpInside)
        button.isEnabled = true
    }

    // Bad cert: advanced section + buttons 
    private var isAdvancedSectionExpanded = false
    private lazy var advancedSectionContainer: UIView = .build { view in
        view.layer.borderWidth = UX.advancedSectionBorderWidth
        view.layer.cornerRadius = UX.advancedSectionCornerRadius
        view.clipsToBounds = true
    }

    private lazy var advancedSectionStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
    }

    private lazy var advancedSectionHeader: UIView = .build()
    private lazy var advancedSectionHeaderButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(self.toggleAdvancedSection), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.advancedSectionHeader
    }

    private lazy var advancedSectionTitleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
    }

    private lazy var advancedSectionChevron: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var advancedSectionContent: UIView = .build()
    private lazy var advancedSectionContentStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
    }

    private lazy var goBackButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapGoBack), for: .touchUpInside)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.font = FXFontStyles.Bold.callout.scaledFont()
        button.titleLabel?.textAlignment = .center
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(
            top: UX.buttonPaddingVertical,
            leading: UX.buttonPaddingHorizontal,
            bottom: UX.buttonPaddingVertical,
            trailing: UX.buttonPaddingHorizontal
        )
        button.configuration = config
        button.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.goBackButton
    }

    private lazy var proceedButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapProceed), for: .touchUpInside)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.font = FXFontStyles.Bold.callout.scaledFont()
        button.titleLabel?.textAlignment = .center
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(
            top: UX.buttonPaddingVertical,
            leading: UX.buttonPaddingHorizontal,
            bottom: UX.buttonPaddingVertical,
            trailing: UX.buttonPaddingHorizontal
        )
        button.configuration = config
        button.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.proceedButton
    }

    private var commonConstraintsList = [NSLayoutConstraint]()
    private var portraitConstraintsList = [NSLayoutConstraint]()
    private var landscapeConstraintsList = [NSLayoutConstraint]()
    private var contentStackWidthConstraint: NSLayoutConstraint?
    private var foxImageWidthConstraint: NSLayoutConstraint?
    private var foxImageHeightConstraint: NSLayoutConstraint?

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

        if state.title.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                store.dispatch(NativeErrorPageAction(windowUUID: self.windowUUID,
                                                     actionType: NativeErrorPageActionType.errorPageLoaded))
            }
            return
        }

        let isBadCert = state.advancedSection != nil && state.showGoBackButton
        if isBadCert {
            setupBadCertDomainUI()
            updateBadCertDomainContent()
        } else {
            setupRegularErrorPageUI()
            titleLabel.text = state.title
            foxImage.image = UIImage(named: nativeErrorPageState.foxImage)
            if let validURL = state.url {
                errorDescriptionLabel.attributedText = getDescriptionWithHostName(
                    errorURL: validURL,
                    description: state.description
                )
            } else {
                errorDescriptionLabel.text = state.description
            }
        }
    }

    private func setupRegularErrorPageUI() {
        reloadButton.isHidden = false
        advancedSectionContainer.isHidden = true
        goBackButton.isHidden = true
        scrollContainer.spacing = UX.mainStackSpacing
        contentStack.spacing = UX.textStackSpacing
        contentStackWidthConstraint?.isActive = false
        foxImageWidthConstraint?.constant = UX.logoSizeWidth
        foxImageHeightConstraint?.isActive = false
        applyTheme()
    }

    private func setupBadCertDomainUI() {
        reloadButton.isHidden = true
        advancedSectionContainer.isHidden = false
        goBackButton.isHidden = false
        scrollContainer.spacing = UX.badCertGapBetweenImageAndContent
        contentStack.spacing = UX.badCertContentGap
        contentStackWidthConstraint?.constant = UX.badCertContentWidth
        contentStackWidthConstraint?.isActive = true
        foxImageWidthConstraint?.constant = UX.badCertImageSize
        foxImageHeightConstraint?.isActive = true
        applyTheme()
    }

    private func updateBadCertDomainContent() {
        guard let state = nativeErrorPageState.advancedSection else { return }

        foxImage.image = !nativeErrorPageState.foxImage.isEmpty
            ? UIImage(named: nativeErrorPageState.foxImage)
            : UIImage(named: ImageIdentifiers.NativeErrorPage.securityError)
        // Title on two lines (e.g. "Be careful." / "Something doesn't look right.")
        let titleString: String
        if let range = nativeErrorPageState.title.range(of: ". ") {
            titleString = nativeErrorPageState.title.replacingCharacters(in: range, with: ".\n")
        } else {
            titleString = nativeErrorPageState.title
        }
        titleLabel.text = titleString
        titleLabel.font = FXFontStyles.Bold.title2.scaledFont()
        errorDescriptionLabel.text = nativeErrorPageState.description
        errorDescriptionLabel.font = FXFontStyles.Regular.subheadline.scaledFont()

        updateAdvancedSection(state: state)
        goBackButton.setTitle(String.NativeErrorPage.GoBackButton, for: .normal)
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

        // Dispatch errorPageLoaded to trigger initialization
        // Use a small delay to ensure receivedError has been processed first
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            store.dispatch(NativeErrorPageAction(windowUUID: self.windowUUID,
                                                 actionType: NativeErrorPageActionType.errorPageLoaded))
        }
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
        // Single content area for both no internet and bad cert (same format: image, title, description, then action)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(errorDescriptionLabel)
        contentStack.setCustomSpacing(UX.mainStackSpacing, after: errorDescriptionLabel)
        contentStack.addArrangedSubview(reloadButton)
        contentStack.addArrangedSubview(advancedSectionContainer)
        contentStack.addArrangedSubview(goBackButton)
        scrollContainer.addArrangedSubview(foxImage)
        scrollContainer.addArrangedSubview(contentStack)
        scrollView.addSubview(scrollContainer)
        view.addSubview(scrollView)

        setupAdvancedSectionLayout()
        contentStackWidthConstraint = contentStack.widthAnchor.constraint(equalToConstant: UX.badCertContentWidth)
        contentStackWidthConstraint?.isActive = false
        foxImageWidthConstraint = foxImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidth)
        foxImageWidthConstraint?.isActive = true
        foxImageHeightConstraint = foxImage.heightAnchor.constraint(equalToConstant: UX.badCertImageSize)
        foxImageHeightConstraint?.isActive = false
        advancedSectionContainer.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        goBackButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight).isActive = true

        advancedSectionContainer.isHidden = true
        goBackButton.isHidden = true
    }

    private func setupAdvancedSectionLayout() {
        advancedSectionContainer.addSubview(advancedSectionStack)
        advancedSectionStack.translatesAutoresizingMaskIntoConstraints = false

        advancedSectionHeader.addSubview(advancedSectionHeaderButton)
        advancedSectionHeaderButton.translatesAutoresizingMaskIntoConstraints = false
        advancedSectionHeaderButton.addSubview(advancedSectionTitleLabel)
        advancedSectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        advancedSectionHeaderButton.addSubview(advancedSectionChevron)
        advancedSectionChevron.translatesAutoresizingMaskIntoConstraints = false
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: UX.advancedSectionChevronSize, weight: .regular)
        advancedSectionChevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)

        advancedSectionContent.addSubview(advancedSectionContentStack)
        advancedSectionContentStack.translatesAutoresizingMaskIntoConstraints = false
        advancedSectionStack.addArrangedSubview(advancedSectionHeader)
        advancedSectionStack.addArrangedSubview(advancedSectionContent)

        let padding = UX.advancedSectionPadding
        let listPadding = UX.advancedSectionListItemHorizontalPadding
        NSLayoutConstraint.activate([
            advancedSectionStack.topAnchor.constraint(
                equalTo: advancedSectionContainer.topAnchor, constant: padding),
            advancedSectionStack.leadingAnchor.constraint(
                equalTo: advancedSectionContainer.leadingAnchor),
            advancedSectionStack.trailingAnchor.constraint(
                equalTo: advancedSectionContainer.trailingAnchor),
            advancedSectionStack.bottomAnchor.constraint(
                equalTo: advancedSectionContainer.bottomAnchor,
                constant: -UX.advancedSectionPaddingBottom),
            advancedSectionHeaderButton.topAnchor.constraint(
                equalTo: advancedSectionHeader.topAnchor),
            advancedSectionHeaderButton.leadingAnchor.constraint(
                equalTo: advancedSectionHeader.leadingAnchor),
            advancedSectionHeaderButton.trailingAnchor.constraint(
                equalTo: advancedSectionHeader.trailingAnchor),
            advancedSectionHeaderButton.bottomAnchor.constraint(
                equalTo: advancedSectionHeader.bottomAnchor),
            advancedSectionHeaderButton.heightAnchor.constraint(
                equalToConstant: UX.advancedSectionHeaderHeight),
            advancedSectionTitleLabel.leadingAnchor.constraint(
                equalTo: advancedSectionHeaderButton.leadingAnchor, constant: listPadding),
            advancedSectionTitleLabel.centerYAnchor.constraint(
                equalTo: advancedSectionHeaderButton.centerYAnchor),
            advancedSectionChevron.trailingAnchor.constraint(
                equalTo: advancedSectionHeaderButton.trailingAnchor, constant: -listPadding),
            advancedSectionChevron.centerYAnchor.constraint(
                equalTo: advancedSectionHeaderButton.centerYAnchor),
            advancedSectionChevron.widthAnchor.constraint(
                equalToConstant: UX.advancedSectionChevronSize),
            advancedSectionChevron.heightAnchor.constraint(
                equalToConstant: UX.advancedSectionChevronSize),
            advancedSectionContentStack.topAnchor.constraint(
                equalTo: advancedSectionContent.topAnchor),
            advancedSectionContentStack.leadingAnchor.constraint(
                equalTo: advancedSectionContent.leadingAnchor),
            advancedSectionContentStack.trailingAnchor.constraint(
                equalTo: advancedSectionContent.trailingAnchor),
            advancedSectionContentStack.bottomAnchor.constraint(
                equalTo: advancedSectionContent.bottomAnchor)
        ])
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
            goBackButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ]

        landscapeConstraintsList = [
            foxImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidthiPad),
            reloadButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            goBackButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ]

        NSLayoutConstraint.activate(commonConstraintsList)
        foxImageWidthConstraint?.isActive = !shouldUseHorizontalLayout

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
        goBackButton.backgroundColor = theme.colors.actionPrimary
        goBackButton.setTitleColor(theme.colors.textInverted, for: .normal)
        proceedButton.backgroundColor = theme.colors.actionSecondary
        proceedButton.setTitleColor(theme.colors.textPrimary, for: .normal)
        advancedSectionContainer.backgroundColor = theme.colors.layer2
        advancedSectionContainer.layer.borderColor = theme.colors.borderPrimary.cgColor
        advancedSectionTitleLabel.textColor = theme.colors.textPrimary
        advancedSectionChevron.tintColor = theme.colors.actionPrimary
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
