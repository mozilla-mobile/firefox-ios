// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ComponentLibrary
import Shared
import Common

final class BlockedTrackersLearnMoreViewController: UIViewController, Themeable {
    private let url: URL

    public let themeManager: any ThemeManager
    public var themeListenerCancellable: Any?
    public var notificationCenter: any NotificationProtocol
    let windowUUID: WindowUUID

    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: Navigation View
    private let navigationView: NavigationHeaderView = .build { header in
        typealias A11yIds = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackersLearnMore
        header.accessibilityIdentifier = A11yIds.headerView
    }

    private let containerView: UIView = .build { view in
        typealias A11yIds = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackersLearnMore
        view.accessibilityIdentifier = A11yIds.containerView
    }

    init(windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         url: URL
    ) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        listenForThemeChanges(withNotificationCenter: notificationCenter)

        setNavigationViewDetails()
        applyTheme()
    }

    private func setupLayout() {
        setupNavigationView()
        setupContainerView()
        embedChild()
        setupAccessibilityIdentifiers()
        setupHeaderViewActions()
    }

    // MARK: Header View Setup
    private func setupNavigationView() {
        view.addSubview(navigationView)
        NSLayoutConstraint.activate([
            navigationView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: TPMenuUX.UX.popoverTopDistance
            ),
            navigationView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            navigationView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            )
        ])
    }

    private func setNavigationViewDetails() {
        navigationView.setViews(with: url.baseDomain ?? "", and: .KeyboardShortcuts.Back)
        navigationView.adjustLayout()
    }

    // MARK: Container View Setup
    private func setupContainerView() {
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(
                equalTo: navigationView.bottomAnchor
            ),
            containerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            containerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            containerView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
    }

    private func embedChild() {
        let settingsContentViewController = SettingsContentViewController(windowUUID: windowUUID)
        settingsContentViewController.url = self.url

        addChild(settingsContentViewController)
        containerView.addSubview(settingsContentViewController.view)
        settingsContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            settingsContentViewController.view.topAnchor.constraint(
                equalTo: containerView.topAnchor
            ),
            settingsContentViewController.view.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor
            ),
            settingsContentViewController.view.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor
            ),
            settingsContentViewController.view.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor
            )
        ])

        settingsContentViewController.didMove(toParent: self)
    }

    // MARK: Header Actions
    private func setupHeaderViewActions() {
        navigationView.backToMainMenuCallback = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        navigationView.dismissMenuCallback = { [weak self] in
            self?.navigationController?.dismissVC()
        }
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        navigationView.setupAccessibility(
            closeButtonA11yLabel: .Menu.EnhancedTrackingProtection.AccessibilityLabels.CloseButton,
            closeButtonA11yId: AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackersLearnMore.closeButton,
            titleA11yId: AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackersLearnMore.titleLabel,
            backButtonA11yLabel: .Menu.EnhancedTrackingProtection.AccessibilityLabels.BackButton,
            backButtonA11yId: AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackersLearnMore.backButton
        )
    }

    // MARK: - Themable
    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let theme = currentTheme()
        navigationView.applyTheme(theme: theme)
        view.backgroundColor = theme.colors.layer3
    }
}
