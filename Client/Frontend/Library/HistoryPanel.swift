/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import XCGLogger
import WebKit

private struct HistoryPanelUX {
    static let WelcomeScreenItemTextColor = UIColor.Photon.Grey50
    static let WelcomeScreenItemWidth = 170
    static let IconSize = 23
    static let IconBorderColor = UIColor.Photon.Grey30
    static let IconBorderWidth: CGFloat = 0.5
    static let actionIconColor = UIColor.Photon.Grey40 // Works for light and dark theme.
}

private class FetchInProgressError: MaybeErrorType {
    internal var description: String {
        return "Fetch is already in-progress"
    }
}

@objcMembers
class HistoryPanel: SiteTableViewController, LibraryPanel {
    enum Section: Int {
        // Showing synced tabs, showing recently closed, and clearing recent history are action rows of this type.
        case additionalHistoryActions
        case today
        case yesterday
        case lastWeek
        case lastMonth

        static let count = 5

        var title: String? {
            switch self {
            case .today:
                return Strings.TableDateSectionTitleToday
            case .yesterday:
                return Strings.TableDateSectionTitleYesterday
            case .lastWeek:
                return Strings.TableDateSectionTitleLastWeek
            case .lastMonth:
                return Strings.TableDateSectionTitleLastMonth
            default:
                return nil
            }
        }
    }

    enum AdditionalHistoryActionRow: Int {
        case clearRecent
        case showRecentlyClosedTabs
        case showSyncTabs

        // Use to enable/disable the additional history action rows.
        static func setStyle(enabled: Bool, forCell cell: UITableViewCell) {
            if enabled {
                cell.textLabel?.alpha = 1.0
                cell.imageView?.alpha = 1.0
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
            } else {
                cell.textLabel?.alpha = 0.5
                cell.imageView?.alpha = 0.5
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
            }
        }
    }

    let QueryLimitPerFetch = 100

    var libraryPanelDelegate: LibraryPanelDelegate?

    var groupedSites = DateGroupedTableData<Site>()

    var refreshControl: UIRefreshControl?

    var syncDetailText = ""
    var currentSyncedDevicesCount = 0

    var currentFetchOffset = 0
    var isFetchInProgress = false

    var clearHistoryCell: UITableViewCell?

    var hasRecentlyClosed: Bool {
        return profile.recentlyClosedTabs.tabs.count > 0
    }

    lazy var emptyStateOverlayView: UIView = createEmptyStateOverlayView()

    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGestureRecognized))
    }()

    // MARK: - Lifecycle
    override init(profile: Profile) {
        super.init(profile: profile)

        [ Notification.Name.FirefoxAccountChanged,
          Notification.Name.PrivateDataClearedHistory,
          Notification.Name.DynamicFontChanged,
          Notification.Name.DatabaseWasReopened ].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(onNotificationReceived), name: $0, object: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.accessibilityIdentifier = "History List"
        tableView.prefetchDataSource = self
        updateSyncedDevicesCount().uponQueue(.main) { result in
            self.updateNumberOfSyncedDevices(self.currentSyncedDevicesCount)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done) { _ in
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Add a refresh control if the user is logged in and the control was not added before. If the user is not
        // logged in, remove any existing control.
        if profile.hasSyncableAccount() && refreshControl == nil {
            addRefreshControl()
        } else if !profile.hasSyncableAccount() && refreshControl != nil {
            removeRefreshControl()
        }

        if profile.hasSyncableAccount() {
            syncDetailText = " "
            updateSyncedDevicesCount().uponQueue(.main) { result in
                self.updateNumberOfSyncedDevices(self.currentSyncedDevicesCount)
            }
        } else {
            syncDetailText = ""
        }
        reloadData()
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

    func endRefreshing() {
        // Always end refreshing, even if we failed!
        refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        if !profile.hasSyncableAccount() {
            removeRefreshControl()
        }
    }

    // MARK: - Loading data

    override func reloadData() {
        guard !isFetchInProgress else { return }
        groupedSites = DateGroupedTableData<Site>()

        currentFetchOffset = 0
        fetchData().uponQueue(.main) { result in
            if let sites = result.successValue {
                for site in sites {
                    if let site = site, let latestVisit = site.latestVisit {
                        self.groupedSites.add(site, timestamp: TimeInterval.fromMicrosecondTimestamp(latestVisit.date))
                    }
                }

                self.tableView.reloadData()
                self.updateEmptyPanelState()

                if let cell = self.clearHistoryCell {
                    AdditionalHistoryActionRow.setStyle(enabled: !self.groupedSites.isEmpty, forCell: cell)
                }

            }
        }
    }

    func fetchData() -> Deferred<Maybe<Cursor<Site>>> {
        guard !isFetchInProgress else {
            return deferMaybe(FetchInProgressError())
        }

        isFetchInProgress = true

        return profile.history.getSitesByLastVisit(limit: QueryLimitPerFetch, offset: currentFetchOffset) >>== { result in
            // Force 100ms delay between resolution of the last batch of results
            // and the next time `fetchData()` can be called.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.currentFetchOffset += self.QueryLimitPerFetch
                self.isFetchInProgress = false
            }

            return deferMaybe(result)
        }
    }

    func resyncHistory() {
        profile.syncManager.syncHistory().uponQueue(.main) { syncResult in
            self.updateSyncedDevicesCount().uponQueue(.main) { result in
                self.endRefreshing()

                self.updateNumberOfSyncedDevices(self.currentSyncedDevicesCount)

                if syncResult.isSuccess {
                    self.reloadData()
                }
            }
        }
    }

    func updateNumberOfSyncedDevices(_ count: Int) {
        if count > 0 {
            syncDetailText = String.localizedStringWithFormat(Strings.SyncedTabsTableViewCellDescription, count)
        } else {
            syncDetailText = ""
        }

        tableView.reloadData()
    }

    func updateSyncedDevicesCount() -> Success {
        guard profile.hasSyncableAccount() else {
            currentSyncedDevicesCount = 0
            return succeed()
        }

        return chainDeferred(profile.getCachedClientsAndTabs()) { tabsAndClients in
            self.currentSyncedDevicesCount = tabsAndClients.count
            return succeed()
        }
    }

    // MARK: - Actions

    func removeHistoryForURLAtIndexPath(indexPath: IndexPath) {
        guard let site = siteForIndexPath(indexPath) else {
            return
        }

        profile.history.removeHistoryForURL(site.url).uponQueue(.main) { result in
            self.tableView.beginUpdates()
            self.groupedSites.remove(site)
            self.tableView.deleteRows(at: [indexPath], with: .right)
            self.tableView.endUpdates()
            self.updateEmptyPanelState()

            if let cell = self.clearHistoryCell {
                AdditionalHistoryActionRow.setStyle(enabled: !self.groupedSites.isEmpty, forCell: cell)
            }
        }
    }

    func pinToTopSites(_ site: Site) {
        _ = profile.history.addPinnedTopSite(site).value
    }

    func navigateToSyncedTabs() {
        let nextController = RemoteTabsPanel(profile: profile)
        nextController.title = Strings.SyncedTabsTableViewCellTitle
        nextController.libraryPanelDelegate = libraryPanelDelegate
        refreshControl?.endRefreshing()
        navigationController?.pushViewController(nextController, animated: true)
    }

    func navigateToRecentlyClosed() {
        guard hasRecentlyClosed else {
            return
        }

        let nextController = RecentlyClosedTabsPanel(profile: profile)
        nextController.title = Strings.RecentlyClosedTabsButtonTitle
        nextController.libraryPanelDelegate = libraryPanelDelegate
        refreshControl?.endRefreshing()
        navigationController?.pushViewController(nextController, animated: true)
    }

    func showClearRecentHistory() {
        func remove(hoursAgo: Int) {
            if let date = Calendar.current.date(byAdding: .hour, value: -hoursAgo, to: Date()) {
                let types = WKWebsiteDataStore.allWebsiteDataTypes()
                WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: date, completionHandler: {})

                self.profile.history.removeHistoryFromDate(date).uponQueue(.main) { _ in
                    self.reloadData()
                }
            }
        }

        let alert = UIAlertController(title: Strings.ClearHistoryMenuTitle, message: nil, preferredStyle: .actionSheet)

        [(Strings.ClearHistoryMenuOptionTheLastHour, 1),
         (Strings.ClearHistoryMenuOptionToday, 24),
         (Strings.ClearHistoryMenuOptionTodayAndYesterday, 48)].forEach {
            (name, time) in
            let action = UIAlertAction(title: name, style: .destructive) { _ in
                remove(hoursAgo: time)
            }
            alert.addAction(action)
        }

        let cancelAction = UIAlertAction(title: Strings.CancelString, style: .cancel)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    // MARK: - Cell configuration

    func siteForIndexPath(_ indexPath: IndexPath) -> Site? {
        // First section is reserved for Sync.
        guard indexPath.section > Section.additionalHistoryActions.rawValue else {
            return nil
        }

        let sitesInSection = groupedSites.itemsForSection(indexPath.section - 1)
        return sitesInSection[safe: indexPath.row]
    }

    func configureClearHistory(_ cell: UITableViewCell, for indexPath: IndexPath) -> UITableViewCell {
        clearHistoryCell = cell
        cell.textLabel?.text = Strings.HistoryPanelClearHistoryButtonTitle
        cell.detailTextLabel?.text = ""
        cell.imageView?.image = UIImage.templateImageNamed("forget")
        cell.imageView?.tintColor = HistoryPanelUX.actionIconColor
        cell.imageView?.backgroundColor = UIColor.theme.homePanel.historyHeaderIconsBackground
        cell.accessibilityIdentifier = "HistoryPanel.clearHistory"

        var isEmpty = true
        for i in Section.today.rawValue..<tableView.numberOfSections {
            if tableView.numberOfRows(inSection: i) > 0 {
                isEmpty = false
            }
        }
        AdditionalHistoryActionRow.setStyle(enabled: !isEmpty, forCell: cell)

        return cell
    }

    func configureRecentlyClosed(_ cell: UITableViewCell, for indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = Strings.RecentlyClosedTabsButtonTitle
        cell.detailTextLabel?.text = ""
        cell.imageView?.image = UIImage.templateImageNamed("recently_closed")
        cell.imageView?.tintColor = HistoryPanelUX.actionIconColor
        cell.imageView?.backgroundColor = UIColor.theme.homePanel.historyHeaderIconsBackground
        AdditionalHistoryActionRow.setStyle(enabled: hasRecentlyClosed, forCell: cell)
        cell.accessibilityIdentifier = "HistoryPanel.recentlyClosedCell"
        return cell
    }

    func configureSyncedTabs(_ cell: UITableViewCell, for indexPath: IndexPath) -> UITableViewCell {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = Strings.SyncedTabsTableViewCellTitle
        cell.detailTextLabel?.text = syncDetailText
        cell.imageView?.image = UIImage.templateImageNamed("synced_devices")
        cell.imageView?.tintColor = HistoryPanelUX.actionIconColor
        cell.imageView?.backgroundColor = UIColor.theme.homePanel.historyHeaderIconsBackground

        cell.imageView?.backgroundColor = UIColor.theme.homePanel.historyHeaderIconsBackground
        cell.accessibilityIdentifier = "HistoryPanel.syncedDevicesCell"
        removeTableSeparator(for: cell)
        return cell
    }

    func configureSite(_ cell: UITableViewCell, for indexPath: IndexPath) -> UITableViewCell {
        if let site = siteForIndexPath(indexPath), let cell = cell as? TwoLineTableViewCell {
            cell.setLines(site.title, detailText: site.url)

            cell.imageView?.layer.borderColor = HistoryPanelUX.IconBorderColor.cgColor
            cell.imageView?.layer.borderWidth = HistoryPanelUX.IconBorderWidth
            cell.imageView?.setIcon(site.icon, forURL: site.tileURL, completed: { (color, url) in
                if site.tileURL == url {
                    cell.imageView?.image = cell.imageView?.image?.createScaled(CGSize(width: HistoryPanelUX.IconSize, height: HistoryPanelUX.IconSize))
                    cell.imageView?.backgroundColor = color
                    cell.imageView?.contentMode = .center
                }
            })
        }
        return cell
    }
    
    func removeTableSeparator(for lastCell: UITableViewCell) {
        lastCell.subviews.forEach { view in
            if !(view is UIButton) && !(view == lastCell.contentView) {
                view.removeFromSuperview()
            }
        }
    }

    // MARK: - Selector callbacks

    @objc func onNotificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .PrivateDataClearedHistory:
            reloadData()

            if profile.hasSyncableAccount() {
                resyncHistory()
            }
            break
        case .DynamicFontChanged:
            reloadData()

            if emptyStateOverlayView.superview != nil {
                emptyStateOverlayView.removeFromSuperview()
            }
            emptyStateOverlayView = createEmptyStateOverlayView()
            resyncHistory()
            break
        case .DatabaseWasReopened:
            if let dbName = notification.object as? String, dbName == "browser.db" {
                reloadData()
            }
        default:
            // no need to do anything at all
            print("Error: Received unexpected notification \(notification.name)")
            break
        }
    }

    @objc func onLongPressGestureRecognized(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }

        if indexPath.section != Section.additionalHistoryActions.rawValue {
            presentContextMenu(for: indexPath)
        }
    }

    @objc func onRefreshPulled() {
        refreshControl?.beginRefreshing()
        resyncHistory()
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // First section is for Sync/recently closed and always has 2 rows.
        guard section > Section.additionalHistoryActions.rawValue else {
            return 3
        }

        return groupedSites.numberOfItemsForSection(section - 1)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // First section is for Sync/recently closed and has no title.
        guard section > Section.additionalHistoryActions.rawValue else {
            return nil
        }

        // Ensure there are rows in this section.
        guard groupedSites.numberOfItemsForSection(section - 1) > 0 else {
            return nil
        }

        return Section(rawValue: section)?.title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.accessoryType = .none

        // First section is reserved for Sync/recently closed.
        guard indexPath.section > Section.additionalHistoryActions.rawValue else {
            cell.imageView?.layer.borderWidth = 0

            guard let row = AdditionalHistoryActionRow(rawValue: indexPath.row) else {
                assertionFailure("Bad row number")
                return cell
            }

            switch row {
            case .clearRecent:
                return configureClearHistory(cell, for: indexPath)
            case .showRecentlyClosedTabs:
                return configureRecentlyClosed(cell, for: indexPath)
            case .showSyncTabs:
                return configureSyncedTabs(cell, for: indexPath)
            }
        }

        return configureSite(cell, for: indexPath)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // First section is reserved for Sync/recently closed.
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        guard indexPath.section > Section.additionalHistoryActions.rawValue else {
            switch indexPath.row {
            case 0:
                showClearRecentHistory()
            case 1:
                navigateToRecentlyClosed()
            default:
                navigateToSyncedTabs()
            }
            return
        }

        if let site = siteForIndexPath(indexPath), let url = URL(string: site.url) {
            if let libraryPanelDelegate = libraryPanelDelegate {
                libraryPanelDelegate.libraryPanel(didSelectURL: url, visitType: VisitType.typed)
            }
            return
        }
        print("Error: No site or no URL when selecting row.")
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor.theme.tableView.headerTextDark
            header.contentView.backgroundColor = UIColor.theme.tableView.headerBackground
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // First section is for Sync/recently closed and its header has no view.
        guard section > Section.additionalHistoryActions.rawValue else {
            return nil
        }

        // Ensure there are rows in this section.
        guard groupedSites.numberOfItemsForSection(section - 1) > 0 else {
            return nil
        }

        return super.tableView(tableView, viewForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // First section is for Sync/recently closed and its header has no height.
        guard section > Section.additionalHistoryActions.rawValue else {
            return 0
        }

        // Ensure there are rows in this section.
        guard groupedSites.numberOfItemsForSection(section - 1) > 0 else {
            return 0
        }

        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == Section.additionalHistoryActions.rawValue {
            return []
        }
        let title = NSLocalizedString("Delete", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the history panel.")

        let delete = UITableViewRowAction(style: .default, title: title, handler: { (action, indexPath) in
            self.removeHistoryForURLAtIndexPath(indexPath: indexPath)
        })
        return [delete]
    }

    // MARK: - Empty State
    func updateEmptyPanelState() {
        if groupedSites.isEmpty {
            if emptyStateOverlayView.superview == nil {
                tableView.addSubview(emptyStateOverlayView)
                emptyStateOverlayView.snp.makeConstraints { make -> Void in
                    make.left.right.bottom.equalTo(self.view)
                    make.top.equalTo(self.view).offset(132)
                }
            }
        } else {
            tableView.alwaysBounceVertical = true
            emptyStateOverlayView.removeFromSuperview()
        }
    }

    func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.theme.homePanel.panelBackground

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = Strings.HistoryPanelEmptyStateTitle
        welcomeLabel.textAlignment = .center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.textColor = HistoryPanelUX.WelcomeScreenItemTextColor
        welcomeLabel.numberOfLines = 0
        welcomeLabel.adjustsFontSizeToFitWidth = true

        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(LibraryPanelUX.EmptyTabContentOffset).priority(100)
            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
            make.width.equalTo(HistoryPanelUX.WelcomeScreenItemWidth)
        }
        return overlayView
    }

    override func applyTheme() {
        emptyStateOverlayView.removeFromSuperview()
        emptyStateOverlayView = createEmptyStateOverlayView()
        updateEmptyPanelState()

        super.applyTheme()
    }
}

extension HistoryPanel: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard !isFetchInProgress, indexPaths.contains(where: shouldLoadRow) else {
            return
        }

        fetchData().uponQueue(.main) { result in
            if let sites = result.successValue {
                let indexPaths: [IndexPath] = sites.compactMap({ site in
                    guard let site = site, let latestVisit = site.latestVisit else {
                        return nil
                    }

                    let indexPath = self.groupedSites.add(site, timestamp: TimeInterval.fromMicrosecondTimestamp(latestVisit.date))
                    return IndexPath(row: indexPath.row, section: indexPath.section + 1)
                })

                self.tableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
    }

    func shouldLoadRow(for indexPath: IndexPath) -> Bool {
        guard indexPath.section > Section.additionalHistoryActions.rawValue else {
            return false
        }

        return indexPath.row >= groupedSites.numberOfItemsForSection(indexPath.section - 1) - 1
    }
}

extension HistoryPanel: LibraryPanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }
        present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        return siteForIndexPath(indexPath)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard var actions = getDefaultContextMenuActions(for: site, libraryPanelDelegate: libraryPanelDelegate) else { return nil }

        let removeAction = PhotonActionSheetItem(title: Strings.DeleteFromHistoryContextMenuTitle, iconString: "action_delete", handler: { action in
            self.removeHistoryForURLAtIndexPath(indexPath: indexPath)
        })

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { action in
            self.pinToTopSites(site)
        })
        actions.append(pinTopSite)
        actions.append(removeAction)
        return actions
    }
}
