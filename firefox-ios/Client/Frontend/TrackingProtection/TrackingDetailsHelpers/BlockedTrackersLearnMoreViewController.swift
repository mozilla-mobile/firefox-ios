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

    private let containerView: UIView = .build { view in
        typealias A11yIds = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackersLearnMore
        view.accessibilityIdentifier = A11yIds.containerView
    }

    private lazy var closeButton: UIButton = .build {
        $0.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        $0.addAction(UIAction(handler: { [weak self] _ in
            self?.dismissVC()
        }), for: .touchUpInside)
        $0.showsLargeContentViewer = true
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
        setupContainerView()
        embedChild()
        setupAccessibilityIdentifiers()
    }

    private func setNavigationViewDetails() {
        self.title = url.baseDomain ?? ""
    }

    // MARK: Container View Setup
    private func setupContainerView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)

        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
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
    private func dismissVC() {
        navigationController?.dismissVC()
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackersLearnMore
        closeButton.accessibilityIdentifier = A11y.closeButton
        closeButton.accessibilityLabel = .Menu.EnhancedTrackingProtection.AccessibilityLabels.CloseButton
    }

    // MARK: - Themable
    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let theme = currentTheme()
        closeButton.tintColor = theme.colors.iconPrimary
        view.backgroundColor = theme.colors.layer3
    }
}
