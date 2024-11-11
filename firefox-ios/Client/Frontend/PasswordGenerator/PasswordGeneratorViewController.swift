// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit
import Redux
import WebKit

class PasswordGeneratorViewController: UIViewController, StoreSubscriber, Themeable, Notifiable {
    private enum UX {
        static let containerPadding: CGFloat = 20
        static let containerElementsVerticalPadding: CGFloat = 16
        static let headerTrailingPadding: CGFloat = 45
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
    private var currentTab: Tab
    private var currentFrame: WKFrameInfo

    // MARK: - Views

    private lazy var contentView: UIView = .build { view in
        view.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.content
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.text = .PasswordGenerator.Description
        label.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.descriptionLabel
    }

    private lazy var header: PasswordGeneratorHeaderView = .build()

    private lazy var passwordField: PasswordGeneratorPasswordFieldView = .build { [weak self] view in
        view.refreshPasswordButtonOnClick = {
            guard let self else {return}
            store.dispatch(PasswordGeneratorAction(
                windowUUID: self.windowUUID,
                actionType: PasswordGeneratorActionType.userTappedRefreshPassword,
                currentFrame: self.currentFrame)
            )
        }
    }

    private lazy var usePasswordButton: PrimaryRoundedButton = .build()

    // MARK: - Initializers

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         currentTab: Tab,
         currentFrame: WKFrameInfo) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.passwordGeneratorState = PasswordGeneratorState(windowUUID: windowUUID)
        self.currentTab = currentTab
        self.currentFrame = currentFrame
        super.init(nibName: nil, bundle: nil)
        self.subscribeToRedux()
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
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
        configureUsePasswordButton()
        setupView()
        applyTheme()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIAccessibility.post(notification: .screenChanged, argument: self.header)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    private func setupView() {
        // Adding Subviews
        view.addSubview(contentView)
        contentView.addSubviews(header, descriptionLabel, passwordField, usePasswordButton)

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
    }
    // MARK: - Interaction Handlers
    @objc
    func useButtonOnClick() {
        store.dispatch(PasswordGeneratorAction(windowUUID: windowUUID,
                                               actionType: PasswordGeneratorActionType.userTappedUsePassword,
                                               currentFrame: currentFrame))
        dismiss(animated: true)
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        descriptionLabel.textColor = theme.colors.textSecondary
        usePasswordButton.applyTheme(theme: theme)
        passwordField.applyTheme(theme: theme)
        header.applyTheme(theme: theme)
    }

    private func configureUsePasswordButton() {
        let usePasswordButtonVM = PrimaryRoundedButtonViewModel(
            title: .PasswordGenerator.UsePasswordButtonLabel,
            a11yIdentifier: AccessibilityIdentifiers.PasswordGenerator.usePasswordButton)
        usePasswordButton.configure(viewModel: usePasswordButtonVM)
        usePasswordButton.addTarget(self, action: #selector(useButtonOnClick), for: .touchUpInside)
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
        passwordField.configure(password: passwordGeneratorState.password)
    }

    // MARK: - Notifiable
    private func applyDynamicFontChange() {
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            applyDynamicFontChange()
        default: break
        }
    }
}

extension PasswordGeneratorViewController: BottomSheetChild {
    func willDismiss() { currentTab.webView?.accessoryView.reloadViewFor(.standard)}
}
