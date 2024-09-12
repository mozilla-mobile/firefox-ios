// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MenuKit
import Common
import UIKit

class MainMenuDetailViewController: UIViewController,
                                    UITableViewDelegate,
                                    UITableViewDataSource,
                                    MainMenuDetailNavigationHandler,
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

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        with data: [MenuSection],
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.submenuData = data
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
        submenuContent.setupHeaderNavigation(from: self)
    }

    private func setupView() {
        view.backgroundColor = .systemMint
        view.addSubview(submenuContent)

        NSLayoutConstraint.activate([
            submenuContent.topAnchor.constraint(equalTo: view.topAnchor),
            submenuContent.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            submenuContent.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            submenuContent.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupTableView() {
        submenuContent.setDelegate(to: self)
        submenuContent.setDataSource(to: self)
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return submenuData.count
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return submenuData[section].options.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MenuCell.cellIdentifier,
            for: indexPath
        ) as! MenuCell

        cell.configureCellWith(model: submenuData[indexPath.section].options[indexPath.row])

        return cell
    }

    // MARK: - UITableViewDelegate Methods
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard let action = submenuData[indexPath.section].options[indexPath.row].action else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        action()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - MainMenuDetailNavigationHandler
    func backToMainView() {
        coordinator?.dismissDetailViewController()
    }

    // MARK: - Notifications
    func handleNotifications(_ notification: Notification) { }
}
