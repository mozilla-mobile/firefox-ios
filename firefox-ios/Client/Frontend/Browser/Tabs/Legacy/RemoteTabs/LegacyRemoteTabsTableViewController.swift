// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared

protocol RemoteTabsPanelDataSource: UITableViewDataSource, UITableViewDelegate {
}

protocol CollapsibleTableViewSection: AnyObject {
    func hideTableViewSection(_ section: Int)
}

// MARK: - RemoteTabsTableViewController
class LegacyRemoteTabsTableViewController: UITableViewController, Themeable {
    struct UX {
        static let rowHeight = SiteTableViewControllerUX.RowHeight
    }

    weak var remoteTabsPanel: LegacyRemoteTabsPanel?
    private var profile: Profile!
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var tableViewDelegate: RemoteTabsPanelDataSource? {
        didSet {
            tableView.dataSource = tableViewDelegate
            tableView.delegate = tableViewDelegate
        }
    }

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    var isTabSyncEnabled: Bool {
        guard let isEnabled = profile.prefs.boolForKey(PrefsKeys.TabSyncEnabled) else {
            return false
        }

        return isEnabled
    }

    init(profile: Profile,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.register(SiteTableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: SiteTableViewHeader.cellIdentifier)
        tableView.register(TwoLineImageOverlayCell.self,
                           forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier)
        tableView.register(LegacyRemoteTabsErrorCell.self,
                           forCellReuseIdentifier: LegacyRemoteTabsErrorCell.cellIdentifier)

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

        // Add a refresh control if the user is logged in and the control was not added before. If the user is not
        // logged in, remove any existing control.
        if profile.hasSyncableAccount() && refreshControl == nil {
            addRefreshControl()
        }

        refreshTabs(updateCache: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if refreshControl != nil {
            removeRefreshControl()
        }
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        if let delegate = tableViewDelegate as? LegacyRemoteTabsErrorDataSource {
            delegate.applyTheme(theme: currentTheme())
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
        refreshTabs(updateCache: true)
    }

    func endRefreshing() {
        // Always end refreshing, even if we failed!
        refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        if !profile.hasSyncableAccount() {
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
                                                                    theme: currentTheme())
        tabsPanelDataSource.collapsibleSectionDelegate = self
        tableViewDelegate = tabsPanelDataSource

        tableView.reloadData()
    }

    func refreshTabs(updateCache: Bool = false, completion: (() -> Void)? = nil) {
        ensureMainThread { [self] in
            // Short circuit if the user is not logged in
            guard profile.hasSyncableAccount() else {
                endRefreshing()
                showEmptyTabsViewWith(.notLoggedIn)
                return
            }

            // Get cached tabs.
            profile.getCachedClientsAndTabs().uponQueue(.main) { [weak self] result in
                guard let clientAndTabs = result.successValue else {
                    self?.endRefreshing()
                    self?.showEmptyTabsViewWith(.failedToSync)
                    return
                }

                // Update UI with cached data.
                self?.updateDelegateClientAndTabData(clientAndTabs)

                if updateCache {
                    // Fetch updated tabs.
                    self?.profile.getClientsAndTabs().uponQueue(.main) { result in
                        if let clientAndTabs = result.successValue {
                            // Update UI with updated tabs.
                            self?.updateDelegateClientAndTabData(clientAndTabs)
                        }

                        self?.endRefreshing()
                        completion?()
                    }
                } else {
                    self?.endRefreshing()
                    completion?()
                }
            }
        }
    }

    private func showEmptyTabsViewWith(_ error: LegacyRemoteTabsErrorDataSource.ErrorType) {
        guard let remoteTabsPanel = remoteTabsPanel else { return }
        var errorMessage = error

        if !isTabSyncEnabled { errorMessage = .syncDisabledByUser }

        let remoteTabsErrorView = LegacyRemoteTabsErrorDataSource(remoteTabsDelegateProvider: remoteTabsPanel,
                                                                  error: errorMessage,
                                                                  theme: currentTheme())
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
}

extension LegacyRemoteTabsTableViewController: CollapsibleTableViewSection {
    func hideTableViewSection(_ section: Int) {
        guard let dataSource = tableViewDelegate as? RemoteTabsClientAndTabsDataSource else { return }

        if dataSource.hiddenSections.contains(section) {
            dataSource.hiddenSections.remove(section)
        } else {
            dataSource.hiddenSections.insert(section)
        }

        tableView.reloadData()
    }
}

// MARK: LibraryPanelContextMenu
extension LegacyRemoteTabsTableViewController: LibraryPanelContextMenu {
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
