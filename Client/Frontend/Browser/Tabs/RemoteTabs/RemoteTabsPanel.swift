// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared
import Redux

/// Captures state needed to populate the Sync tab UI. Some aspects of how we
/// will handle management of state are still TBD as part of the Redux refactors.
struct RemoteTabsPanelState {
    let refreshState: RemoteTabsPanelRefreshState
    let clientAndTabs: [ClientAndTabs]
    let allowsRefresh: Bool // True if hasSyncableAccount
    let syncIsSupported: Bool // Reference: `prefs.boolForKey(PrefsKeys.TabSyncEnabled)`

    static func emptyState() -> RemoteTabsPanelState {
        return RemoteTabsPanelState(refreshState: .loaded,
                                    clientAndTabs: [],
                                    allowsRefresh: false,
                                    syncIsSupported: true)
    }
}

enum RemoteTabsPanelRefreshState {
    case loaded
    case refreshing
}

enum RemoteTabsPanelAction: Action {
    case refreshCachedTabs
    case refreshTabs
}

class RemoteTabsPanel: UIViewController,
                       StoreSubscriber,
                       Themeable,
                       RemoteTabsClientAndTabsDataSourceDelegate,
                       RemotePanelDelegateProvider {
    private(set) var state: RemoteTabsPanelState
    var tableViewController: RemoteTabsTableViewController
    var remotePanelDelegate: RemotePanelDelegate?

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

class RemoteTabsTableViewController: UITableViewController,
                                     Themeable,
                                     CollapsibleTableViewSection,
                                     LibraryPanelContextMenu {
    struct UX {
        static let rowHeight = SiteTableViewControllerUX.RowHeight
    }

    private(set) var state: RemoteTabsPanelState

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    weak var remoteTabsPanel: RemoteTabsPanel?
    var tableViewDelegate: RemoteTabsPanelDataSource? {
        didSet {
            tableView.dataSource = tableViewDelegate
            tableView.delegate = tableViewDelegate
        }
    }

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    init(state: RemoteTabsPanelState,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.state = state
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.register(SiteTableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: SiteTableViewHeader.cellIdentifier)
        tableView.register(TwoLineImageOverlayCell.self,
                           forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier)
        tableView.register(RemoteTabsErrorCell.self,
                           forCellReuseIdentifier: RemoteTabsErrorCell.cellIdentifier)

        tableView.rowHeight = UX.rowHeight
        tableView.separatorInset = .zero
        tableView.alwaysBounceVertical = false

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }

        tableView.delegate = nil
        tableView.dataSource = nil

        tableView.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.syncedTabs
        listenForThemeChange(view)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? ThemedNavigationController)?.applyTheme()

        // Add a refresh control if the user is logged in and the control was not added before.
        // If the user is not logged in, remove any existing control.
        if state.allowsRefresh && refreshControl == nil {
            addRefreshControl()
        }

        refreshTabs(state: state, updateCache: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if refreshControl != nil {
            removeRefreshControl()
        }
    }

    func applyTheme() {
        tableView.separatorColor = themeManager.currentTheme.colors.layerLightGrey30
        if let delegate = tableViewDelegate as? RemoteTabsErrorDataSource {
            delegate.applyTheme(theme: themeManager.currentTheme)
        }
    }

    // MARK: - Refreshing TableView

    func addRefreshControl() {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(onRefreshPulled), for: .valueChanged)
        refreshControl = control
        tableView.refreshControl = control
    }

    func removeRefreshControl() {
        tableView.refreshControl = nil
        refreshControl = nil
    }

    @objc
    func onRefreshPulled() {
        refreshControl?.beginRefreshing()
        refreshTabs(state: state, updateCache: true)
    }

    func endRefreshing() {
        // Always end refreshing, even if we failed!
        refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        if !state.allowsRefresh {
            removeRefreshControl()
        }
    }

    func updateDelegateClientAndTabData(_ clientAndTabs: [ClientAndTabs]) {
        guard let remoteTabsPanel = remoteTabsPanel else { return }

        guard !clientAndTabs.isEmpty else {
            showEmptyTabsViewWith(.noClients)
            return
        }

        let nonEmptyClientAndTabs = clientAndTabs.filter { !$0.tabs.isEmpty }
        guard !nonEmptyClientAndTabs.isEmpty else {
            showEmptyTabsViewWith(.noTabs)
            return
        }

        let tabsPanelDataSource = RemoteTabsClientAndTabsDataSource(actionDelegate: remoteTabsPanel,
                                                                    clientAndTabs: nonEmptyClientAndTabs,
                                                                    theme: themeManager.currentTheme)
        tabsPanelDataSource.collapsibleSectionDelegate = self
        tableViewDelegate = tabsPanelDataSource

        tableView.reloadData()
    }

    func refreshTabs(state: RemoteTabsPanelState, updateCache: Bool = false, completion: (() -> Void)? = nil) {
        ensureMainThread { [self] in
            self.state = state
            performRefresh(updateCache: updateCache, completion: completion)
        }
    }

    private func performRefresh(updateCache: Bool, completion: (() -> Void)?) {
        // Short circuit if the user is not logged in
        guard state.allowsRefresh else {
            endRefreshing()
            showEmptyTabsViewWith(.notLoggedIn)
            return
        }

        // TODO: Send Redux action to get cached clients & tabs, update once new state is received. Forthcoming.
        // store.dispatch(RemoteTabsPanelAction.refreshCachedTabs)
    }

    private func showEmptyTabsViewWith(_ error: RemoteTabsErrorDataSource.ErrorType) {
        guard let remoteTabsPanel = remoteTabsPanel else { return }
        var errorMessage = error

        if !state.syncIsSupported { errorMessage = .syncDisabledByUser }

        let remoteTabsErrorView = RemoteTabsErrorDataSource(remoteTabsDelegateProvider: remoteTabsPanel,
                                                            error: errorMessage,
                                                            theme: themeManager.currentTheme)
        tableViewDelegate = remoteTabsErrorView

        tableView.reloadData()
    }

    @objc
    private func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
    }

    func hideTableViewSection(_ section: Int) {
        guard let dataSource = tableViewDelegate as? RemoteTabsClientAndTabsDataSource else { return }

        if dataSource.hiddenSections.contains(section) {
            dataSource.hiddenSections.remove(section)
        } else {
            dataSource.hiddenSections.insert(section)
        }

        tableView.reloadData()
    }

    func presentContextMenu(for site: Site, with indexPath: IndexPath,
                            completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }

        present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let tab = (tableViewDelegate as? RemoteTabsClientAndTabsDataSource)?.tabAtIndexPath(indexPath) else {
            return nil
        }
        return Site(url: String(describing: tab.URL), title: tab.title)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        return getRemoteTabContextMenuActions(for: site, remotePanelDelegate: remoteTabsPanel?.remotePanelDelegate)
    }
}
