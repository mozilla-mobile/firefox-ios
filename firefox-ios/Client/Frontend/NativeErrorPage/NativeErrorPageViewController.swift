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
                                           ContentContainable {
    private let model: ErrorPageModel
    private let windowUUID: WindowUUID

    // MARK: Themable Variables
    var themeManager: Common.ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: Common.NotificationProtocol
    var currentWindowUUID: UUID? {
        windowUUID
    }

    private var overlayManager: OverlayModeManager
    var contentType: ContentType = .nativeErrorPage

    // MARK: UI Elements
    private struct UX {
        static let logoSizeWidth: CGFloat = 221
        static let mainStackSpacing: CGFloat = 24
        static let textStackSpacing: CGFloat = 16
        static let portraitPadding = NSDirectionalEdgeInsets(
            top: 76,
            leading: 16,
            bottom: -16,
            trailing: -16
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

    private lazy var textStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.textStackSpacing
    }

    private lazy var commonContainer: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.mainStackSpacing
        stackView.distribution = .fill
    }

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(
            named: ImageIdentifiers.NativeErrorPage.noInternetConnection
        )
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.title2.scaledFont()
        label.numberOfLines = 0
        label.text = .NativeErrorPage.NoInternetConnection.TitleLabel
    }

    private lazy var errorDescriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.text = .NativeErrorPage.NoInternetConnection.Description
    }

    private lazy var reloadButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapReload), for: .touchUpInside)
        button.isEnabled = true
    }

    private var contraintsList = [NSLayoutConstraint]()

    required init?(
        coder aDecoder: NSCoder
    ) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    init(
        model: ErrorPageModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        overlayManager: OverlayModeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.model = model
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.overlayManager = overlayManager
        self.notificationCenter = notificationCenter
        super.init(
            nibName: nil,
            bundle: nil
        )

        configureUI()
        setupLayout()
        adjustConstraints()
        showViewForCurrentOrientation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        applyTheme()
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

    // TODO: FXIOS-9639 #21237 [a11y] Verify accessibility for Voice Over, Dynamic text
    private func configureUI() {
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .NativeErrorPage.ButtonLabel,
            a11yIdentifier: ""
        )
        reloadButton.configure(
            viewModel: viewModel
        )
    }

    private func setupLayout() {
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(errorDescriptionLabel)
        commonContainer.addArrangedSubview(textStack)
        commonContainer.addArrangedSubview(reloadButton)
        scrollContainer.addArrangedSubview(logoImage)
        scrollContainer.addArrangedSubview(commonContainer)
        scrollView.addSubview(scrollContainer)
        view.addSubview(scrollView)
    }

    func adjustConstraints() {
        NSLayoutConstraint.deactivate(contraintsList)
        contraintsList = [
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
            logoImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidth)
        ]
        NSLayoutConstraint.activate(contraintsList)
    }

    private var isLandscape: Bool {
        return UIDevice.current.isIphoneLandscape
    }

    private func showViewForCurrentOrientation() {
        if isLandscape {
            scrollContainer.axis = .horizontal
            titleLabel.textAlignment = .left
            errorDescriptionLabel.textAlignment = .left
        } else {
            scrollContainer.axis = .vertical
            titleLabel.textAlignment = .center
            errorDescriptionLabel.textAlignment = .center
        }
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
        store.dispatch(
            GeneralBrowserAction(
                isNativeErrorPage: true,
                windowUUID: windowUUID,
                actionType: GeneralBrowserActionType.reloadWebsite
            )
        )
    }
}
