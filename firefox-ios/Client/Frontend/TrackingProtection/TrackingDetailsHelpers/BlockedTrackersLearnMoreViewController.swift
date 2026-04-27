// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ComponentLibrary
import Shared
import Common

final class BlockedTrackersLearnMoreViewController: UIViewController, Themeable {
    private struct UX {
        static let closeButtonSize: CGFloat = 20
    }

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
    }

    private func setNavigationViewDetails() {
        self.title = url.baseDomain ?? ""
    }

    // MARK: Container View Setup
    private func setupContainerView() {
        setupCloseButton()

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

    private func setupCloseButton() {
        let closeButtonSize = CGSize(width: UX.closeButtonSize, height: UX.closeButtonSize)

        let rawImage = UIImage(named: StandardImageIdentifiers.Large.cross)
        let resizedImage = UIGraphicsImageRenderer(size: closeButtonSize).image { _ in
            rawImage?.draw(in: CGRect(origin: .zero, size: closeButtonSize))
        }.withRenderingMode(.alwaysTemplate)

        let closeBarButtonItem = UIBarButtonItem(
            image: resizedImage,
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )

        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackersLearnMore
        closeBarButtonItem.accessibilityIdentifier = A11y.closeButton
        closeBarButtonItem.accessibilityLabel = .Menu.EnhancedTrackingProtection.AccessibilityLabels.CloseButton

        closeBarButtonItem.tintColor = currentTheme().colors.iconPrimary
        navigationItem.rightBarButtonItem = closeBarButtonItem
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
    @objc
    private func dismissVC() {
        navigationController?.dismissVC()
    }

    // MARK: - Themable
    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let theme = currentTheme()
        view.backgroundColor = theme.colors.layer3
    }
}
