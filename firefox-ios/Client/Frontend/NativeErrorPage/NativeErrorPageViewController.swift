// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared

final class NativeErrorPageViewController: UIViewController, ContentContainable, Themeable {
    private enum UX {
        static let illustrationContentOverlap: CGFloat = 5
        static let contentHorizontalPadding: CGFloat = 40
        static let contentBottomPadding: CGFloat = 15
        static let contentMaxWidth: CGFloat = 500
        static let contentStackSpacing: CGFloat = 32
        static let textStackSpacing: CGFloat = 6
        static let descriptionStackSpacing: CGFloat = 20
        static let actionsStackSpacing: CGFloat = 20
        static let backgroundGradientLocations: [NSNumber] = [0, 0.55, 1]
        static let backgroundGradientCenter = CGPoint(x: 0.2, y: 0)
        static let backgroundGradientEdge = CGPoint(x: 1.4, y: 0.7)
        static let backgroundGradientOrangeOpacity: CGFloat = 0.15
    }

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: UUID? { windowUUID }

    let contentType: ContentType = .nativeErrorPage
    let errorPage: NativeErrorPageURL

    private let windowUUID: WindowUUID
    private let tabManager: TabManager
    private let model: NativeErrorPageModel

    // MARK: - Views

    private let backgroundView: GradientView = .build { view in
        (view.layer as? CAGradientLayer)?.type = .radial
    }

    private let scrollView: UIScrollView = .build()

    private let illustrationView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.foxImage
    }

    private let contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackSpacing
    }

    private let textStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.textStackSpacing
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.titleLabel
    }

    private let descriptionStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.descriptionStackSpacing
    }

    private let descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.title3.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.errorDescriptionLabel
    }

    private let errorCodeLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.errorCodeLabel
    }

    private let actionsStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.actionsStackSpacing
    }

    private let primaryButton: PrimaryRoundedButton = .build()

    private let advancedView: NativeErrorPageAdvancedView = .build { view in
        view.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.advancedSection
    }

    // MARK: - Init

    init(
        errorPage: NativeErrorPageURL,
        windowUUID: WindowUUID,
        tabManager: TabManager,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.errorPage = errorPage
        self.model = NativeErrorPageModel(errorPage: errorPage)
        self.windowUUID = windowUUID
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupButtons()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        updateContent()
    }

    // MARK: - Layout

    private func setupLayout() {
        setupStackViews()

        scrollView.addSubview(illustrationView)
        scrollView.addSubview(contentStackView)
        view.addSubview(backgroundView)
        view.addSubview(scrollView)

        setupConstraints()
    }

    // MARK: - Content

    private func updateContent() {
        updateLabels()
        updateAdvancedView()
        updatePrimaryButton()
        applyTheme()
    }

    // MARK: - Actions

    private func didTapPrimaryButton() {
        switch model.primaryButton {
        case .tryAgain: reload()
        case .goBack: goBack()
        }
    }

    // MARK: - Theme

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        applyBackground(theme: theme)
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textSecondary
        errorCodeLabel.textColor = theme.colors.textPrimary
        primaryButton.applyTheme(theme: theme)
        advancedView.applyTheme(theme: theme)
    }

    // MARK: - Helpers

    private func setupStackViews() {
        [descriptionLabel, errorCodeLabel].forEach(descriptionStackView.addArrangedSubview)
        [titleLabel, descriptionStackView].forEach(textStackView.addArrangedSubview)
        [primaryButton, advancedView].forEach(actionsStackView.addArrangedSubview)
        [textStackView, actionsStackView].forEach(contentStackView.addArrangedSubview)
    }

    private func setupConstraints() {
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        // Scroll content
        let contentMatchesScreenWidth = content.widthAnchor.constraint(equalTo: frame.widthAnchor)
        let contentFillsScreen = content.heightAnchor.constraint(equalTo: frame.heightAnchor)
        contentFillsScreen.priority = .defaultLow

        // Stack
        let stackFillsWidth = contentStackView.widthAnchor.constraint(equalTo: content.widthAnchor,
                                                                      constant: -UX.contentHorizontalPadding * 2)
        stackFillsWidth.priority = .required - 1
        let stackMaxWidth = contentStackView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.contentMaxWidth)
        let stackCenteredHorizontally = contentStackView.centerXAnchor.constraint(equalTo: content.centerXAnchor)

        let stackVerticalPosition: NSLayoutConstraint
        if shouldUseiPadSetup() {
            stackVerticalPosition = contentStackView.centerYAnchor.constraint(equalTo: content.centerYAnchor)
            stackVerticalPosition.priority = .defaultLow - 1
        } else {
            stackVerticalPosition = contentStackView.bottomAnchor.constraint(equalTo: content.bottomAnchor,
                                                                             constant: -UX.contentBottomPadding)
        }
        let stackStaysAboveBottom = contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor,
                                                                             constant: -UX.contentBottomPadding)

        // Illustration
        let illustrationAtLeadingEdge = illustrationView.leadingAnchor.constraint(equalTo: content.leadingAnchor)
        let illustrationOnStack = illustrationView.bottomAnchor.constraint(equalTo: contentStackView.topAnchor,
                                                                           constant: UX.illustrationContentOverlap)
        let illustrationBelowTop = illustrationView.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentMatchesScreenWidth,
            contentFillsScreen,

            stackFillsWidth,
            stackMaxWidth,
            stackCenteredHorizontally,
            stackVerticalPosition,
            stackStaysAboveBottom,

            illustrationAtLeadingEdge,
            illustrationOnStack,
            illustrationBelowTop,
        ])
    }

    private func setupButtons() {
        primaryButton.addAction(UIAction { [weak self] _ in self?.didTapPrimaryButton() }, for: .touchUpInside)
        advancedView.onProceed = { [weak self] in self?.proceedToSite() }
        advancedView.onViewCertificate = { [weak self] in self?.showCertificate() }
        advancedView.onLearnMore = { [weak self] in self?.showLearnMore() }
    }

    private func updateLabels() {
        illustrationView.image = UIImage(named: model.imageName)?.imageFlippedForRightToLeftLayoutDirection()
        titleLabel.text = model.title
        descriptionLabel.text = model.description

        errorCodeLabel.text = String(format: .NativeErrorPage.ErrorCodeLabel, String(model.errorCode))
        errorCodeLabel.isHidden = model.advanced != nil
    }

    private func updateAdvancedView() {
        if let advanced = model.advanced {
            advancedView.configure(with: advanced, errorCode: model.errorCode)
        }
        advancedView.isHidden = model.advanced == nil
    }

    private func updatePrimaryButton() {
        let isGoBack = model.primaryButton == .goBack
        primaryButton.configure(viewModel: PrimaryRoundedButtonViewModel(
            title: isGoBack ? .NativeErrorPage.GoBackButton : .NativeErrorPage.TryAgainButton,
            a11yIdentifier: isGoBack
                ? AccessibilityIdentifiers.NativeErrorPage.goBackButton
                : AccessibilityIdentifiers.NativeErrorPage.reloadButton
        ))
    }

    private func reload() {
        store.dispatch(GeneralBrowserAction(windowUUID: windowUUID, actionType: GeneralBrowserActionType.reloadWebsite))
    }

    private func goBack() {
        store.dispatch(GeneralBrowserAction(windowUUID: windowUUID, actionType: GeneralBrowserActionType.navigateBack))
    }

    private func proceedToSite() {
        guard let tab = tabManager.selectedTab,
              let certificateData = errorPage.certificateData,
              let certificate = SecCertificateCreateWithData(nil, certificateData as CFData),
              let host = errorPage.originalURL.host
        else { return }

        tab.profile.certStore.addCertificate(certificate, forOrigin: "\(host):\(errorPage.originalURL.port ?? 443)")

        tab.webView?.replaceLocation(with: errorPage.originalURL)
    }

    private func showCertificate() {
        store.dispatch(NavigationBrowserAction(
            navigationDestination: NavigationDestination(
                .certificatesFromErrorPage,
                url: errorPage.originalURL,
                errorPageURL: errorPage.url,
                certificateTitle: model.title
            ),
            windowUUID: windowUUID,
            actionType: NavigationBrowserActionType.tapOnShowCertificatesFromErrorPage
        ))
    }

    private func showLearnMore() {
        guard let url = SupportUtils.URLForConnectionNotSecureLearnMore else { return }

        store.dispatch(NavigationBrowserAction(
            navigationDestination: NavigationDestination(.nativeErrorPageLearnMore, url: url),
            windowUUID: windowUUID,
            actionType: NavigationBrowserActionType.tapOnNativeErrorPageLearnMore
        ))
    }

    private func applyBackground(theme: Theme) {
        backgroundView.backgroundColor = theme.colors.layer1

        guard theme.isNova else {
            backgroundView.configure(gradient: nil)
            return
        }

        let accent = theme.colors.gradientAccentSubtle.colors
        guard accent.count >= 2, let violet = accent.first, let orange = accent.last else {
            backgroundView.configure(gradient: nil)
            return
        }

        backgroundView.configure(
            gradient: Gradient(colors: [
                violet,
                theme.colors.layer1,
                orange.withAlphaComponent(UX.backgroundGradientOrangeOpacity)
            ]),
            startPoint: UX.backgroundGradientCenter,
            endPoint: UX.backgroundGradientEdge,
            locations: UX.backgroundGradientLocations
        )
    }
}
