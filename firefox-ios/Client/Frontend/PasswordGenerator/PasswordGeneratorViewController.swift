// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit

class PasswordGeneratorViewController: UIViewController, Themeable {
    private enum UX {
        static let containerPadding: CGFloat = 20
        static let containerElementsVerticalPadding: CGFloat = 16

        static let passwordFieldBorderWidth: CGFloat = 1
        static let passwordFieldCornerRadius: CGFloat = 4
        static let passwordFieldHorizontalPadding: CGFloat = 16
        static let passwordLabelAndButtonSpacing: CGFloat = 10
        static let passwordFieldVerticalPadding: CGFloat = 10

        static let headerIconLabelSpacing: CGFloat = 10
        static let headerVerticalPadding: CGFloat = 8
    }
    // MARK: - Properties

    private lazy var contentView: UIView = .build()
    private lazy var headerLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.text = .PasswordGenerator.UseStrongPassword
        label.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.bottomSheetHeader
        label.accessibilityTraits = .header
    }
    private lazy var headerImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.login)?.withRenderingMode(.alwaysTemplate)
    }
    private lazy var captionLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.text = .PasswordGenerator.PasswordGeneratorInformation
    }

    private lazy var header: UIView = .build()

    private lazy var passwordField: UIView = .build { field in
        field.layer.borderWidth = UX.passwordFieldBorderWidth
        field.layer.cornerRadius = UX.passwordFieldCornerRadius

        field.isUserInteractionEnabled = true

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        field.addGestureRecognizer(longPressGesture)
    }

    private lazy var passwordLabel: UILabel = .build()

    private lazy var passwordRefreshButton: UIButton = .build { button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.arrowClockwise)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.accessibilityLabel = .PasswordGenerator.refreshStrongPasswordButtonA11yLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.bottomSheetRefreshStrongPasswordButton
    }

    private lazy var usePasswordButton: PrimaryRoundedButton = .build()

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    private var generatedPassword: String
    private var fillPasswordField: ((String) -> Void)?
    private var contentViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Initializers

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         generatedPassword: String,
         fillPasswordField: @escaping (String) -> Void ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.generatedPassword = generatedPassword
        self.fillPasswordField = fillPasswordField

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        buildPasswordLabel()
        buildUsePasswordButton()
        setupView()
        applyTheme()
        UIAccessibility.post(notification: .screenChanged, argument: String.PasswordGenerator.PasswordGenerator)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    private func setupView() {
        // Adding Subviews
        view.addSubview(contentView)
        contentView.addSubviews(header, captionLabel, passwordField, usePasswordButton)
        header.addSubviews(headerImageView, headerLabel)
        passwordField.addSubviews(passwordLabel, passwordRefreshButton)

        // Content View Constraints
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: UX.containerPadding),
            contentView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -UX.containerPadding),
            contentView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: UX.containerPadding),
            contentView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -UX.containerPadding),
        ])

        // Header elements layout
        NSLayoutConstraint.activate([
            headerImageView.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            headerImageView.topAnchor.constraint(
                greaterThanOrEqualTo: header.topAnchor,
                constant: UX.headerVerticalPadding),
            headerLabel.topAnchor.constraint(
                equalTo: header.topAnchor,
                constant: UX.headerVerticalPadding),
            headerLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            headerLabel.leadingAnchor.constraint(
                equalTo: headerImageView.trailingAnchor,
                constant: UX.headerIconLabelSpacing),
            headerLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor)
        ])

        // Password Field Elements Layout
        NSLayoutConstraint.activate([
            passwordLabel.topAnchor.constraint(
                equalTo: passwordField.topAnchor,
                constant: UX.passwordFieldVerticalPadding),
            passwordLabel.leadingAnchor.constraint(
                equalTo: passwordField.leadingAnchor,
                constant: UX.passwordFieldHorizontalPadding),
            passwordLabel.bottomAnchor.constraint(
                equalTo: passwordField.bottomAnchor,
                constant: -UX.passwordFieldVerticalPadding),
            passwordRefreshButton.topAnchor.constraint(
                equalTo: passwordField.topAnchor,
                constant: UX.passwordFieldVerticalPadding),
            passwordRefreshButton.leadingAnchor.constraint(
                greaterThanOrEqualTo: passwordLabel.trailingAnchor,
                constant: UX.passwordLabelAndButtonSpacing),
            passwordRefreshButton.trailingAnchor.constraint(
                equalTo: passwordField.trailingAnchor,
                constant: -UX.passwordFieldHorizontalPadding),
            passwordRefreshButton.bottomAnchor.constraint(
                equalTo: passwordField.bottomAnchor,
                constant: -UX.passwordFieldVerticalPadding)
        ])

        // Content View Elements Layout
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -45),
            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            captionLabel.topAnchor.constraint(
                equalTo: header.bottomAnchor,
                constant: UX.containerElementsVerticalPadding),
            passwordField.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: captionLabel.trailingAnchor),
            passwordField.topAnchor.constraint(
                equalTo: captionLabel.bottomAnchor,
                constant: UX.containerElementsVerticalPadding),
            usePasswordButton.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor),
            usePasswordButton.trailingAnchor.constraint(
                equalTo: passwordField.trailingAnchor),
            usePasswordButton.topAnchor.constraint(
                equalTo: passwordField.bottomAnchor,
                constant: UX.containerElementsVerticalPadding),
            usePasswordButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        headerImageView.tintColor = theme.colors.iconPrimary
        headerLabel.textColor = theme.colors.textPrimary
        captionLabel.textColor = theme.colors.textSecondary
        passwordField.backgroundColor = theme.colors.layer2
        passwordField.layer.borderColor = theme.colors.borderPrimary.cgColor
        passwordLabel.textColor = theme.colors.textPrimary
        passwordRefreshButton.tintColor = theme.colors.iconPrimary
        usePasswordButton.applyTheme(theme: theme)
    }

    @objc
    func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let menuController = UIMenuController.shared
        let copyItem = UIMenuItem(title: .PasswordGenerator.copyStrongPassword, action: #selector(copyText(_:)))
        menuController.menuItems = [copyItem]
        menuController.showMenu(from: passwordLabel, rect: passwordLabel.bounds)
    }

    @objc
    func copyText(_ sender: Any?) {
        UIPasteboard.general.string = generatedPassword
    }

    @objc
    func useButtonOnClick() {
        fillPasswordField?(generatedPassword)
        dismiss(animated: true)
    }

    private func buildPasswordLabel() {
        passwordLabel.numberOfLines = 0
        passwordLabel.font = FXFontStyles.Regular.body.scaledFont()
        let text = NSMutableAttributedString(string: .PasswordGenerator.passwordReadoutPrefaceA11y)
        passwordLabel.text = generatedPassword
        text.append(NSMutableAttributedString(string: passwordLabel.text!, attributes: [.accessibilitySpeechSpellOut: true]))
        passwordLabel.accessibilityAttributedLabel = text
    }

    private func buildUsePasswordButton() {
        let usePasswordButtonVM = PrimaryRoundedButtonViewModel(
            title: .PasswordGenerator.UsePassword,
            a11yIdentifier: AccessibilityIdentifiers.PasswordGenerator.bottomSheetUsePasswordButton)
        usePasswordButton.configure(viewModel: usePasswordButtonVM)
        usePasswordButton.addTarget(self, action: #selector(useButtonOnClick), for: .touchUpInside)
    }
}

extension PasswordGeneratorViewController: BottomSheetChild {
    func willDismiss() { }
}
