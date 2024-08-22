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
    var currentWindowUUID: UUID? { windowUUID }

    // MARK: Contraints Variables
    private var commonViewContraints = [NSLayoutConstraint]()
    private var portraitViewContraints = [NSLayoutConstraint]()
    private var landscapeViewContraints = [NSLayoutConstraint]()

    private var overlayManager: OverlayModeManager
    var contentType: ContentType = .nativeErrorPage

    // MARK: UI Elements
    private struct UX {
        static let logoSizeWidth: CGFloat = 221
        static let logoSizeHeight: CGFloat = 181
        static let mainStackSpacing: CGFloat = 24
        static let errorDetailStackSpacing: CGFloat = 16
        static let buttonHeight: CGFloat = 45
        static let buttonWidth: CGFloat = 343
        static let portraitPadding = NSDirectionalEdgeInsets(
            top: 75,
            leading: 16,
            bottom: -16,
            trailing: -16
        )
        static let landscapePadding = NSDirectionalEdgeInsets(
            top: 30,
            leading: 32,
            bottom: -32,
            trailing: -30
        )
    }

    private lazy var scrollView: UIScrollView = .build()

    private lazy var scrollContainer: UIStackView = .build { stackView in
        stackView.axis = .vertical
    }

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.NativeErrorPage.noInternetConnection)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title2.scaledFont()
        label.numberOfLines = 0
        label.text = .NativeErrorPage.NoInternetConnection.TitleLabel
    }

    private lazy var errorDescriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.text = .NativeErrorPage.NoInternetConnection.Description
    }

    private lazy var reloadButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapSubmit), for: .touchUpInside)
        button.isEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(model: ErrorPageModel, windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         overlayManager: OverlayModeManager,
         notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.model = model
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.overlayManager = overlayManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        configureUI()
        setupLayout()
        setUpContraints()
        applyConstraintsAndTextAlignment()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        applyConstraintsAndTextAlignment()
    }

    private func configureUI() {
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .NativeErrorPage.ButtonLabel, a11yIdentifier: ""
        )
        reloadButton.configure(viewModel: viewModel)
    }

    private func setupLayout() {
        scrollContainer.addArrangedSubview(titleLabel)
        scrollContainer.setCustomSpacing(UX.errorDetailStackSpacing, after: titleLabel)
        scrollContainer.addArrangedSubview(errorDescriptionLabel)
        scrollContainer.setCustomSpacing(UX.mainStackSpacing, after: errorDescriptionLabel)
        scrollContainer.addArrangedSubview(reloadButton)
        scrollView.addSubview(logoImage)
        scrollView.addSubview(scrollContainer)
        view.addSubviews(scrollView)
    }

    private func applyConstraintsAndTextAlignment() {
        NSLayoutConstraint.deactivate(portraitViewContraints)
        NSLayoutConstraint.deactivate(landscapeViewContraints)
        NSLayoutConstraint.deactivate(commonViewContraints)

        var isLandscape: Bool {
            if UIDevice.current.orientation == .unknown {
                if let orientation = (UIApplication.shared.connectedScenes.first as?
                                      UIWindowScene)?.windows.first?.windowScene?.interfaceOrientation {
                    if orientation == .landscapeLeft || orientation == .landscapeRight {
                        return true
                    }
                }
            }
            return UIDevice.current.orientation.isLandscape
        }

        NSLayoutConstraint.activate(commonViewContraints)

        if isLandscape {
            titleLabel.textAlignment = .left
            errorDescriptionLabel.textAlignment = .left
            scrollContainer.alignment = .leading
            NSLayoutConstraint.activate(landscapeViewContraints)
        } else {
            titleLabel.textAlignment = .center
            errorDescriptionLabel.textAlignment = .center
            scrollContainer.alignment = .center
            NSLayoutConstraint.activate(portraitViewContraints)
        }
    }

    private func setUpContraints() {
        commonViewContraints = [
            logoImage.widthAnchor.constraint(equalToConstant: UX.logoSizeWidth),
            logoImage.heightAnchor.constraint(equalToConstant: UX.logoSizeHeight),
            // ReloadButton constraints
            reloadButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            reloadButton.widthAnchor.constraint(equalToConstant: UX.buttonWidth)
        ]

        landscapeViewContraints = [
            // ScrollView constraints
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: UX.landscapePadding.top),
            scrollView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: UX.landscapePadding.leading),
            scrollView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: UX.landscapePadding.trailing),
            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: UX.landscapePadding.bottom),

            // LogoImage constraints
            logoImage.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            logoImage.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),

            // MainScrollContainer constraints
            scrollContainer.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            scrollContainer.leadingAnchor.constraint(
                equalTo: logoImage.trailingAnchor, constant: UX.mainStackSpacing),
            scrollContainer.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            scrollContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ]

        portraitViewContraints = [
            // ScrollView constraints
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: UX.portraitPadding.top),
            scrollView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: UX.portraitPadding.leading),
            scrollView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: UX.portraitPadding.trailing),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: UX.portraitPadding.bottom),

            // LogoImage constraints
            logoImage.topAnchor.constraint(equalTo: scrollView.topAnchor),
            logoImage.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),

            // MainScrollContainer constraints
            scrollContainer.topAnchor.constraint(equalTo: logoImage.bottomAnchor, constant: UX.mainStackSpacing),
            scrollContainer.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: UX.portraitPadding.leading),
            scrollContainer.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: UX.portraitPadding.trailing),
            scrollContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ]
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
    private func didTapSubmit() {
    }
}
