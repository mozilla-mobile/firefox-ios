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
                       RemotePanelDelegateProvider,
                       StoreSubscriber {
    typealias SubscriberStateType = RemoteTabsPanelState

    // MARK: - Properties

    private(set) var state: RemoteTabsPanelState
    var tableViewController: RemoteTabsTableViewController
    weak var remotePanelDelegate: RemotePanelDelegate?
    weak var navigationHandler: SyncedTabsNavigationHandler?

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    lazy var isReduxIntegrationEnabled: Bool = ReduxFlagManager.isReduxEnabled

    // MARK: - Initializer

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.state = RemoteTabsPanelState()
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.tableViewController = RemoteTabsTableViewController(state: state)

        super.init(nibName: nil, bundle: nil)

        self.tableViewController.remoteTabsPanel = self

        observeNotifications()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        unsubscribeFromRedux()
    }

    // MARK: - Actions

    func tableViewControllerDidPullToRefresh() {
        refreshTabs()
    }

    // MARK: - Internal Utilities

    private func refreshTabs() {
        // Ensure we do not already have a refresh in progress
        guard state.refreshState != .refreshing else { return }
        store.dispatch(RemoteTabsPanelAction.refreshTabs)
    }

    private func observeNotifications() {
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

    @objc
    func notificationReceived(_ notification: Notification) {
        let name = notification.name
        if name == .FirefoxAccountChanged || name == .ProfileDidFinishSyncing {
            refreshTabs()
        }
    }

    // MARK: - View & Layout

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupLayout()
        subscribeToRedux()
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTabs()
    }

    private func setupLayout() {
        navigationController?.setNavigationBarHidden(true, animated: false)
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
    }

    // MARK: - Redux

    func subscribeToRedux() {
        guard isReduxIntegrationEnabled else { return }
        store.dispatch(ActiveScreensStateAction.showScreen(.remoteTabsPanel))
        store.dispatch(RemoteTabsPanelAction.panelDidAppear)
        store.subscribe(self, transform: {
            return $0.select(RemoteTabsPanelState.init)
        })
    }

    func unsubscribeFromRedux() {
        if isReduxIntegrationEnabled {
            store.dispatch(ActiveScreensStateAction.closeScreen(.remoteTabsPanel))
            store.unsubscribe(self)
        }
    }

    func newState(state: RemoteTabsPanelState) {
        ensureMainThread { [weak self] in
            guard let self else { return }

            self.state = state
            tableViewController.newState(state: state)
        }
    }

    // MARK: - RemoteTabsClientAndTabsDataSourceDelegate

    func remoteTabsClientAndTabsDataSourceDidSelectURL(_ url: URL, visitType: VisitType) {
        // Pass event along to our delegate
        remotePanelDelegate?.remotePanel(didSelectURL: url, visitType: VisitType.typed)
    }
}
