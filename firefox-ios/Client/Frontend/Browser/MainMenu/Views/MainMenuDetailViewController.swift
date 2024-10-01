// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MenuKit
import Common
import UIKit
import ComponentLibrary

class MainMenuDetailViewController: UIViewController,
                                    MenuTableViewDataDelegate,
                                    Notifiable {
    // MARK: - UI/UX elements
    private lazy var submenuContent: MenuDetailView = .build()

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    weak var coordinator: MainMenuCoordinator?

    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    var submenuData: [MenuSection]
    var submenuTitle: String

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        with data: [MenuSection],
        title: String,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.submenuData = data
        self.submenuTitle = title
        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupTableView()
        submenuContent.setViews(with: submenuTitle, and: .KeyboardShortcuts.Back)
        submenuContent.detailHeaderView.backToMainMenuCallback = { [weak self] in
            self?.coordinator?.dismissDetailViewController()
        }
        submenuContent.detailHeaderView.dismissMenuCallback = { [weak self] in
            self?.coordinator?.dismissMenuModal(animated: true)
        }
        setupAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    // MARK: Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.adjustLayout()
        }, completion: nil)
    }

    // MARK: - UX related
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer3
        submenuContent.applyTheme(theme: theme)
    }

    private func setupView() {
        view.addSubview(submenuContent)

        NSLayoutConstraint.activate([
            submenuContent.topAnchor.constraint(equalTo: view.topAnchor),
            submenuContent.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            submenuContent.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            submenuContent.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupAccessibilityIdentifiers() {
        submenuContent.setupAccessibilityIdentifiers(
            closeButtonA11yLabel: .MainMenu.Account.AccessibilityLabels.CloseButton,
            closeButtonA11yId: AccessibilityIdentifiers.MainMenu.NavigationHeaderView.closeButton,
            backButtonA11yLabel: .MainMenu.Account.AccessibilityLabels.BackButton,
            backButtonA11yId: AccessibilityIdentifiers.MainMenu.NavigationHeaderView.backButton)
    }

    private func adjustLayout() {
        submenuContent.detailHeaderView.adjustLayout()
    }

    private func setupTableView() {
        reloadTableView(with: submenuData)
    }

    // MARK: - TableViewDelegates
    func reloadTableView(with data: [MenuSection]) {
        submenuContent.reloadTableView(with: data)
    }
}
