// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary
import Redux

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
        static let iPadPadding = NSDirectionalEdgeInsets(
            top: 100,
            leading: 166,
            bottom: -16,
            trailing: -166
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

    private var commonContraintsList = [NSLayoutConstraint]()
    private var portraitContraintsList = [NSLayoutConstraint]()
    private var landscapeContraintsList = [NSLayoutConstraint]()

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
    var shouldUseHorizontalLayout: Bool {
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
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.overlayManager = overlayManager
        self.notificationCenter = notificationCenter
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
        store.dispatchLegacy(action)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return NativeErrorPageState(appState: appState, uuid: uuid)
            })
        })
    }

    nonisolated func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .nativeErrorPage)
        store.dispatchLegacy(action)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()

        store.dispatchLegacy(NativeErrorPageAction(windowUUID: windowUUID,
                                                   actionType: NativeErrorPageActionType.errorPageLoaded))
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
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
        NSLayoutConstraint.deactivate(portraitContraintsList + landscapeContraintsList + commonContraintsList)
        commonContraintsList = [
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
            )
        ]

        portraitContraintsList = [
            scrollContainer.topAnchor.constraint(
                equalTo: scrollView.topAnchor,
                constant: self.isLandscape ? UX.landscapePadding.top : UX.portraitPadding.top
            ),
            scrollContainer.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: self.isLandscape ? UX.landscapePadding.leading : UX.portraitPadding.leading
            ),
            scrollContainer.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: self.isLandscape ? UX.landscapePadding.trailing : UX.portraitPadding.trailing
            ),
            scrollContainer.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor,
                constant: self.isLandscape ? UX.landscapePadding.bottom : UX.portraitPadding.bottom
            ),
            foxImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidth)
        ]

        landscapeContraintsList = [
            scrollContainer.topAnchor.constraint(
                equalTo: scrollView.topAnchor,
                constant: UX.iPadPadding.top
            ),
            scrollContainer.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: UX.iPadPadding.leading
            ),
            scrollContainer.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: UX.iPadPadding.trailing
            ),
            scrollContainer.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor,
                constant: UX.iPadPadding.bottom
            ),
            foxImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidthiPad),
            reloadButton.widthAnchor.constraint(
                equalTo: contentStack.widthAnchor
            )
        ]

        NSLayoutConstraint.activate(commonContraintsList)

        if shouldUseiPadSetup() && !isLargeContentSizeCategory {
            NSLayoutConstraint.activate(landscapeContraintsList)
        } else {
            NSLayoutConstraint.activate(portraitContraintsList)
        }
    }

    private func showViewForCurrentOrientation() {
        scrollContainer.axis = self.shouldUseHorizontalLayout ? .horizontal : .vertical
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
        store.dispatchLegacy(
            GeneralBrowserAction(
                isNativeErrorPage: true,
                windowUUID: windowUUID,
                actionType: GeneralBrowserActionType.reloadWebsite
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
