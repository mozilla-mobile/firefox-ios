// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared
import Redux

class RemoteTabsPanel: UIViewController,
                       Themeable,
                       RemoteTabsClientAndTabsDataSourceDelegate,
                       RemotePanelDelegateProvider {
    private(set) var state: RemoteTabsPanelState
    var tableViewController: RemoteTabsTableViewController
    weak var remotePanelDelegate: RemotePanelDelegate?

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    init(state: RemoteTabsPanelState,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.state = state
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.tableViewController = RemoteTabsTableViewController(state: state)

        super.init(nibName: nil, bundle: nil)

        self.tableViewController.remoteTabsPanel = self

        observeNotifications()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func observeNotifications() {
        // TODO: State to be provided by forthcoming Redux updates. TBD.
        // For now, continue to observe notifications.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .FirefoxAccountChanged,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(notificationReceived),
                                       name: .ProfileDidFinishSyncing,
                                       object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupLayout()
        applyTheme()
    }

    private func setupLayout() {
        tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(tableViewController)
        view.addSubview(tableViewController.view)
        tableViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer4
        tableViewController.tableView.backgroundColor =  themeManager.currentTheme.colors.layer3
        tableViewController.tableView.separatorColor = themeManager.currentTheme.colors.borderPrimary
        tableViewController.tableView.reloadData()
        tableViewController.refreshTabs(state: state)
    }

    func forceRefreshTabs() {
        tableViewController.refreshTabs(state: state, updateCache: true)
    }

    @objc
    func notificationReceived(_ notification: Notification) {
        let name = notification.name
        if name == .FirefoxAccountChanged || name == .ProfileDidFinishSyncing {
            ensureMainThread {
                self.tableViewController.refreshTabs(state: self.state)
            }
        }
    }

    func remoteTabsClientAndTabsDataSourceDidSelectURL(_ url: URL, visitType: VisitType) {
        // Pass event along to our delegate
        remotePanelDelegate?.remotePanel(didSelectURL: url, visitType: VisitType.typed)
    }
}
