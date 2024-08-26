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
        static let textStackSpacing: CGFloat = 16
        static let buttonHeight: CGFloat = 45
        static let buttonWidth: CGFloat = 343
        static let portraitPadding = NSDirectionalEdgeInsets(
            top: 16,
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

    private lazy var verticalStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = UX.mainStackSpacing
    }

    private lazy var horizontalStack: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = UX.mainStackSpacing
    }

    private lazy var textStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.textStackSpacing
        stackView.alignment = .center
    }

    private lazy var commonContainer: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.mainStackSpacing
        stackView.alignment = .center
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
        label.textAlignment = .center
    }

    private lazy var errorDescriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.text = .NativeErrorPage.NoInternetConnection.Description
        label.textAlignment = .center
    }

    private lazy var reloadButton: PrimaryRoundedButton = .build { button in
        button.addTarget(
            self,
            action: #selector(
                self.didTapSubmit
            ),
            for: .touchUpInside
        )
        button.isEnabled = true
    }

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
        showViewBasedOnOrientation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(
            view
        )
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
        showViewBasedOnOrientation()
    }

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
        textStack.addArrangedSubview(
            titleLabel
        )
        textStack.addArrangedSubview(
            errorDescriptionLabel
        )
        commonContainer.addArrangedSubview(
            textStack
        )
        commonContainer.addArrangedSubview(
            reloadButton
        )
        horizontalStack.addArrangedSubview(
            logoImage
        )
        horizontalStack.addArrangedSubview(
            commonContainer
        )
        verticalStack.addArrangedSubview(
            logoImage
        )
        verticalStack.addArrangedSubview(
            commonContainer
        )
        scrollView.addSubview(
             verticalStack
        )
        scrollView.addSubview(
            horizontalStack
        )
        view.addSubview(
            scrollView
        )

        verticalStack.isHidden = true
        horizontalStack.isHidden = true

        NSLayoutConstraint.activate(
            [scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: UX.portraitPadding.top
            ),
             scrollView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: UX.portraitPadding.leading
             ),
             scrollView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: UX.portraitPadding.trailing
             ),
             scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: UX.portraitPadding.bottom
             ),
             // MainScrollContainer constraints
             verticalStack.centerXAnchor.constraint(
                equalTo: scrollView.centerXAnchor
             ),
             verticalStack.centerYAnchor.constraint(
                equalTo: scrollView.centerYAnchor
             ),
             verticalStack.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor
             ),
             verticalStack.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor
             ),
             horizontalStack.centerXAnchor.constraint(
                equalTo: scrollView.centerXAnchor
             ),
             horizontalStack.centerYAnchor.constraint(
                equalTo: scrollView.centerYAnchor
             ),
             horizontalStack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: UX.portraitPadding.leading
             )]
        )
    }

    private var isLandscape: Bool {
        return UIDevice.current.isIphoneLandscape
    }

    private func showViewBasedOnOrientation() {
        if isLandscape {
            verticalStack.isHidden = true
            horizontalStack.isHidden = false
            commonContainer.alignment = .leading
            textStack.alignment = .leading
            titleLabel.textAlignment = .left
            errorDescriptionLabel.textAlignment = .left
        } else {
            verticalStack.isHidden = false
            horizontalStack.isHidden = true
            commonContainer.alignment = .center
            textStack.alignment = .center
            titleLabel.textAlignment = .center
            errorDescriptionLabel.textAlignment = .center
        }
    }

    // MARK: ThemeApplicable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(
            for: windowUUID
        )
        view.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        errorDescriptionLabel.textColor = theme.colors.textPrimary
        reloadButton.applyTheme(
            theme: theme
        )
    }

    @objc
    private func didTapSubmit() {
    }
}
