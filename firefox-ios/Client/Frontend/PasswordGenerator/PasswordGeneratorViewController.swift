// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit
import Redux

class PasswordGeneratorViewController: UIViewController, StoreSubscriber, Themeable {
    private enum UX {
        static let containerPadding: CGFloat = 20
        static let containerElementsVerticalPadding: CGFloat = 16

        static let passwordFieldBorderWidth: CGFloat = 1
        static let passwordFieldCornerRadius: CGFloat = 4
        static let passwordFieldHorizontalPadding: CGFloat = 16
        static let passwordFieldVerticalPadding: CGFloat = 10
        static let passwordLabelAndButtonSpacing: CGFloat = 10
        static let passwordRefreshButtonHeight: CGFloat = 18

        static let headerIconLabelSpacing: CGFloat = 10
        static let headerVerticalPadding: CGFloat = 8
        static let headerTrailingPadding: CGFloat = 45
        static let headerImageHeight: CGFloat = 24
    }

    // MARK: - Redux
    typealias SubscriberState = PasswordGeneratorState
    private var passwordGeneratorState: PasswordGeneratorState

    // MARK: - Properties
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    private var contentViewHeightConstraint: NSLayoutConstraint!
    private let scaledRefreshButtonSize = UIFontMetrics.default.scaledValue(for: UX.passwordRefreshButtonHeight)
    private let scaledHeaderImageSize = UIFontMetrics.default.scaledValue(for: UX.headerImageHeight)

    // MARK: - Views

    private lazy var contentView: UIView = .build { view in
        view.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.content
    }
    private lazy var headerLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.text = .PasswordGenerator.Title
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.headerLabel
        label.accessibilityTraits = .header
    }
    private lazy var headerImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.login)?.withRenderingMode(.alwaysTemplate)
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.headerImage
    }
    private lazy var descriptionLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.text = .PasswordGenerator.Description
        label.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.descriptionLabel
    }

    private lazy var header: UIView = .build { view in
        view.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.header
    }

    private lazy var passwordField: UIView = .build { field in
        field.layer.borderWidth = UX.passwordFieldBorderWidth
        field.layer.cornerRadius = UX.passwordFieldCornerRadius
        field.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.passwordField
    }

    private lazy var passwordLabel: UILabel = .build { label in
        label.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.passwordlabel
    }

    private lazy var passwordRefreshButton: UIButton = .build { button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.arrowClockwise)?.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.accessibilityLabel = .PasswordGenerator.RefreshPasswordButtonA11yLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.passwordRefreshButton
    }

    private lazy var usePasswordButton: PrimaryRoundedButton = .build()

    // MARK: - Initializers

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         currentTab: Tab) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.passwordGeneratorState = PasswordGeneratorState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)
        self.subscribeToRedux()
    }

    deinit {
        unsubscribeFromRedux()
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIAccessibility.post(notification: .screenChanged, argument: self.headerLabel)
        }
    }

    private func setupView() {
        // Adding Subviews
        view.addSubview(contentView)
        contentView.addSubviews(header, descriptionLabel, passwordField, usePasswordButton)
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

        // Content View Elements Layout
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -UX.headerTrailingPadding),
            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            descriptionLabel.topAnchor.constraint(
                equalTo: header.bottomAnchor,
                constant: UX.containerElementsVerticalPadding),
            passwordField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            passwordField.topAnchor.constraint(
                equalTo: descriptionLabel.bottomAnchor,
                constant: UX.containerElementsVerticalPadding),
            usePasswordButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            usePasswordButton.trailingAnchor.constraint(
                equalTo: passwordField.trailingAnchor),
            usePasswordButton.topAnchor.constraint(
                equalTo: passwordField.bottomAnchor,
                constant: UX.containerElementsVerticalPadding),
            usePasswordButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Header elements layout
        NSLayoutConstraint.activate([
            headerImageView.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            headerImageView.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            headerImageView.widthAnchor.constraint(equalToConstant: scaledHeaderImageSize),
            headerImageView.heightAnchor.constraint(equalToConstant: scaledHeaderImageSize),
            headerLabel.leadingAnchor.constraint(
                equalTo: headerImageView.trailingAnchor,
                constant: UX.headerIconLabelSpacing),
            headerLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            headerLabel.topAnchor.constraint(
                equalTo: header.topAnchor,
                constant: UX.headerVerticalPadding),
            headerLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor)
        ])

        // Password Field Elements Layout
        NSLayoutConstraint.activate([
            passwordLabel.leadingAnchor.constraint(
                equalTo: passwordField.leadingAnchor,
                constant: UX.passwordFieldHorizontalPadding),
            passwordLabel.topAnchor.constraint(
                equalTo: passwordField.topAnchor,
                constant: UX.passwordFieldVerticalPadding),
            passwordLabel.bottomAnchor.constraint(
                equalTo: passwordField.bottomAnchor,
                constant: -UX.passwordFieldVerticalPadding),
            passwordRefreshButton.leadingAnchor.constraint(
                greaterThanOrEqualTo: passwordLabel.trailingAnchor,
                constant: UX.passwordLabelAndButtonSpacing),
            passwordRefreshButton.trailingAnchor.constraint(
                equalTo: passwordField.trailingAnchor,
                constant: -UX.passwordFieldHorizontalPadding),
            passwordRefreshButton.centerYAnchor.constraint(
                equalTo: passwordField.centerYAnchor),
            passwordRefreshButton.widthAnchor.constraint(equalToConstant: scaledRefreshButtonSize),
            passwordRefreshButton.heightAnchor.constraint(equalToConstant: scaledRefreshButtonSize),
        ])
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        headerImageView.tintColor = theme.colors.iconPrimary
        headerLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textSecondary
        passwordField.backgroundColor = theme.colors.layer2
        passwordField.layer.borderColor = theme.colors.borderPrimary.cgColor
        passwordLabel.textColor = theme.colors.textPrimary
        passwordRefreshButton.tintColor = theme.colors.iconPrimary
        usePasswordButton.applyTheme(theme: theme)
    }

    private func buildPasswordLabel() {
        passwordLabel.numberOfLines = 0
        passwordLabel.font = FXFontStyles.Regular.body.scaledFont()
        passwordLabel.text = passwordGeneratorState.password
        passwordLabel.accessibilityAttributedLabel = generateAccessibilityAttributedLabel()
    }

    private func buildUsePasswordButton() {
        let usePasswordButtonVM = PrimaryRoundedButtonViewModel(
            title: .PasswordGenerator.UsePasswordButtonLabel,
            a11yIdentifier: AccessibilityIdentifiers.PasswordGenerator.usePasswordButton)
        usePasswordButton.configure(viewModel: usePasswordButtonVM)
    }

    // MARK: - Redux
    func subscribeToRedux() {
        store.dispatch(
            ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.showScreen,
                screen: .passwordGenerator
            )
        )

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return PasswordGeneratorState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(
            ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.closeScreen,
                screen: .passwordGenerator
            )
        )
    }

    func newState(state: PasswordGeneratorState) {
        passwordGeneratorState = state
        passwordLabel.text = passwordGeneratorState.password
        passwordLabel.accessibilityAttributedLabel = generateAccessibilityAttributedLabel()
    }

    private func generateAccessibilityAttributedLabel() -> NSMutableAttributedString {
        let fullString = String(format: .PasswordGenerator.PasswordReadoutPrefaceA11y, passwordGeneratorState.password)
        let attributedString = NSMutableAttributedString(string: fullString)
        let rangeOfPassword = (attributedString.string as NSString).range(of: passwordGeneratorState.password)
        attributedString.addAttributes([.accessibilitySpeechSpellOut: true], range: rangeOfPassword)
        return attributedString
    }
}

extension PasswordGeneratorViewController: BottomSheetChild {
    func willDismiss() { }
}
