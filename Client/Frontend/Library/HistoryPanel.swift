/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import XCGLogger
import WebKit

private struct HistoryPanelUX {
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
    private lazy var emptyHeader = EmptyHeader(icon: "libraryHistory", title: .localized(.noHistory), subtitle: .localized(.websitesYouHave))
    
    enum Section: Int {
        // Showing showing recently closed, and clearing recent history are action rows of this type.
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

        // Use to enable/disable the additional history action rows.
        static func setStyle(enabled: Bool, forCell cell: OneLineTableViewCell) {
            if enabled {
                cell.titleLabel.alpha = 1.0
                cell.leftImageView.alpha = 1.0
                cell.accessoryView?.tintColor.map({ cell.accessoryView?.tintColor = $0.withAlphaComponent(1.0) })
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
            } else {
                cell.titleLabel.alpha = 0.5
                cell.leftImageView.alpha = 0.5
                cell.accessoryView?.tintColor.map({ cell.accessoryView?.tintColor = $0.withAlphaComponent(0.5) })
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
            }
        }
    }

    let QueryLimitPerFetch = 100

    var libraryPanelDelegate: LibraryPanelDelegate?
    var recentlyClosedTabsDelegate: RecentlyClosedPanelDelegate?

    var groupedSites = DateGroupedTableData<Site>()

    var refreshControl: UIRefreshControl?

    var currentFetchOffset = 0
    var isFetchInProgress = false

    var clearHistoryCell: OneLineTableViewCell?

    var hasRecentlyClosed: Bool {
        return profile.recentlyClosedTabs.tabs.count > 0
    }

    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGestureRecognized))
    }()

    // MARK: - Lifecycle
    init(profile: Profile) {
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
        tableView.backgroundColor = UIColor.theme.homePanel.panelBackground
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
        
        (navigationController as? ThemedNavigationController)?.applyTheme()
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
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        if profile.isShutdown { return }
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

                if let cell = self.clearHistoryCell {
                    AdditionalHistoryActionRow.setStyle(enabled: !self.groupedSites.isEmpty, forCell: cell)
                }
                
                if self.groupedSites.isEmpty {
                    self.tableView.tableFooterView = self.emptyHeader
                    self.emptyHeader.applyTheme()
                } else {
                    self.tableView.tableFooterView = nil
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
            self.endRefreshing()

            if syncResult.isSuccess {
                self.reloadData()
            }
        }
    }

    // MARK: - Actions

    func removeHistoryForURLAtIndexPath(indexPath: IndexPath) {
        guard let site = siteForIndexPath(indexPath) else {
            return
        }

        profile.history.removeHistoryForURL(site.url).uponQueue(.main) { result in
            guard site == self.siteForIndexPath(indexPath) else {
                self.reloadData()
                return
            }

            self.groupedSites.remove(site)

            // Ecosia: Crashfix, reload whole table if last item in section is deleted
            if self.groupedSites.numberOfItemsForSection(indexPath.section - 1) > 0 {
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [indexPath], with: .right)
                self.tableView.endUpdates()
            } else {
                self.reloadData()
            }

            Analytics.shared.browser(.delete, label: .history)
            
            if let cell = self.clearHistoryCell {
                AdditionalHistoryActionRow.setStyle(enabled: !self.groupedSites.isEmpty, forCell: cell)
            }
        }
    }

    func pinToTopSites(_ site: Site) {
        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            if result.isSuccess {
                SimpleToast().showAlertWithText(Strings.AppMenuAddPinToShortcutsConfirmMessage, image: "action_pin", bottomContainer: self.view)
            }
        }
    }

    func navigateToRecentlyClosed() {
        guard hasRecentlyClosed else {
            return
        }

        let nextController = RecentlyClosedTabsPanel(profile: profile)
        nextController.title = Strings.RecentlyClosedTabsButtonTitle
        nextController.libraryPanelDelegate = libraryPanelDelegate
        nextController.recentlyClosedTabsDelegate = BrowserViewController.foregroundBVC()
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

        // This will run on the iPad-only, and sets the alert to be centered with no arrow.
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        [(Strings.ClearHistoryMenuOptionTheLastHour, 1),
         (Strings.ClearHistoryMenuOptionToday, 24),
         (Strings.ClearHistoryMenuOptionTodayAndYesterday, 48)].forEach {
            (name, time) in
            let action = UIAlertAction(title: name, style: .destructive) { _ in
                Analytics.shared.browser(.delete_all, label: .history)
                remove(hoursAgo: time)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: Strings.ClearHistoryMenuOptionEverything, style: .destructive, handler: { _ in
            let types = WKWebsiteDataStore.allWebsiteDataTypes()
            WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast, completionHandler: {})
            self.profile.history.clearHistory().uponQueue(.main) { _ in
                self.reloadData()
            }
            self.profile.recentlyClosedTabs.clearTabs()
        }))
        let cancelAction = UIAlertAction(title: Strings.CancelString, style: .cancel)
        alert.addAction(cancelAction)
        alert.view.tintColor = UIColor.theme.ecosia.information
        present(alert, animated: true)
    }

    // MARK: - Cell configuration

    func siteForIndexPath(_ indexPath: IndexPath) -> Site? {
        // First section is reserved for recently closed.
        guard indexPath.section > Section.additionalHistoryActions.rawValue else {
            return nil
        }

        let sitesInSection = groupedSites.itemsForSection(indexPath.section - 1)
        return sitesInSection[safe: indexPath.row]
    }

    func configureClearHistory(_ cell: OneLineTableViewCell, for indexPath: IndexPath) -> OneLineTableViewCell {
        clearHistoryCell = cell
        cell.titleLabel.text = Strings.HistoryPanelClearHistoryButtonTitle
        cell.titleLabel.textColor = UIColor.theme.ecosia.warning
        cell.leftImageView.image = UIImage.templateImageNamed("forget")
        cell.leftImageView.backgroundColor = UIColor.theme.homePanel.historyHeaderIconsBackground
        cell.accessibilityIdentifier = "HistoryPanel.clearHistory"

        /* Ecosia: ignore empty logic here
        var isEmpty = true
        for i in Section.today.rawValue..<tableView.numberOfSections {
            if tableView.numberOfRows(inSection: i) > 0 {
                isEmpty = false
            }
        }
        cell.imageView?.tintColor = isEmpty ? HistoryPanelUX.actionIconColor : .theme.general.destructiveRed
        AdditionalHistoryActionRow.setStyle(enabled: !isEmpty, forCell: cell)
         */
        cell.leftImageView.tintColor = UIColor.theme.ecosia.warning
        return cell
    }

    func configureRecentlyClosed(_ cell: OneLineTableViewCell, for indexPath: IndexPath) -> OneLineTableViewCell {
        cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.right"))
        cell.accessoryView?.tintColor = UIColor.theme.ecosia.primaryText

        cell.titleLabel.text = Strings.RecentlyClosedTabsButtonTitle
        cell.titleLabel.textColor = .theme.ecosia.primaryText
        cell.leftImageView.image = UIImage.templateImageNamed("recently_closed")
        cell.leftImageView.tintColor = UIColor.theme.ecosia.primaryText
        AdditionalHistoryActionRow.setStyle(enabled: hasRecentlyClosed, forCell: cell)
        cell.accessibilityIdentifier = "HistoryPanel.recentlyClosedCell"
        return cell
    }

    func configureSite(_ cell: UITableViewCell, for indexPath: IndexPath) -> UITableViewCell {
        if let site = siteForIndexPath(indexPath), let cell = cell as? TwoLineImageOverlayCell {
            cell.titleLabel.text = site.title
            cell.titleLabel.isHidden = site.title.isEmpty ? true : false
            cell.descriptionLabel.isHidden = false
            cell.descriptionLabel.text = site.url
            /* Ecosia: remove border for site icons
            cell.leftImageView.layer.borderColor = HistoryPanelUX.IconBorderColor.cgColor
            cell.leftImageView.layer.borderWidth = HistoryPanelUX.IconBorderWidth
            */
            cell.leftImageView.contentMode = .center
            cell.leftImageView.setImageAndBackground(forIcon: site.icon, website: site.tileURL) { [weak cell] in
                cell?.leftImageView.image = cell?.leftImageView.image?.createScaled(CGSize(width: HistoryPanelUX.IconSize, height: HistoryPanelUX.IconSize))
            }
        }
        return cell
    }

    // MARK: - Selector callbacks

    func onNotificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .PrivateDataClearedHistory:
            reloadData()

            if profile.hasSyncableAccount() {
                resyncHistory()
            }
            break
        case .DynamicFontChanged:
            reloadData()
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

    func onLongPressGestureRecognized(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }

        if indexPath.section != Section.additionalHistoryActions.rawValue {
            presentContextMenu(for: indexPath)
        }
    }

    func onRefreshPulled() {
        refreshControl?.beginRefreshing()
        resyncHistory()
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        if groupedSites.isEmpty {
            return 1
        }
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // First section is for recently closed and always has 1 row.
        guard section > Section.additionalHistoryActions.rawValue else {
            return 2
        }

        return groupedSites.numberOfItemsForSection(section - 1)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // First section is for recently closed and has no title.
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
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! TwoLineImageOverlayCell
        cell.accessoryType = .none
        // First section is reserved for recently closed.
        guard indexPath.section > Section.additionalHistoryActions.rawValue else {
            cell.leftImageView.layer.borderWidth = 0

            guard let row = AdditionalHistoryActionRow(rawValue: indexPath.row) else {
                assertionFailure("Bad row number")
                return cell
            }

            let oneLineCell = tableView.dequeueReusableCell(withIdentifier: OneLineCellIdentifier, for: indexPath) as! OneLineTableViewCell
            switch row {
            case .clearRecent:
                return configureClearHistory(oneLineCell, for: indexPath)
            case .showRecentlyClosedTabs:
                return configureRecentlyClosed(oneLineCell, for: indexPath)
            }
        }

        return configureSite(cell, for: indexPath)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // First section is reserved for recently closed.
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        guard indexPath.section > Section.additionalHistoryActions.rawValue else {
            switch indexPath.row {
            case 0:
                showClearRecentHistory()
            default:
                navigateToRecentlyClosed()
            }
            return
        }

        if let site = siteForIndexPath(indexPath), let url = URL(string: site.url) {
            if let libraryPanelDelegate = libraryPanelDelegate {
                Analytics.shared.browser(.open, label: .history)
                libraryPanelDelegate.libraryPanel(didSelectURL: url, visitType: VisitType.typed)
            }
            return
        }
        print("Error: No site or no URL when selecting row.")
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor.theme.ecosia.secondaryText
            header.contentView.backgroundColor = UIColor.theme.homePanel.panelBackground
            if #available(iOS 14.0, *) {
                header.backgroundConfiguration?.backgroundColor = UIColor.theme.homePanel.panelBackground
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footer = view as? UITableViewHeaderFooterView {
            footer.contentView.backgroundColor = UIColor.theme.homePanel.panelBackground
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // First section is for recently closed and its header has no view.
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
        // First section is for recently closed and its header has no height.
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
    /* Ecosia: use newer API for table swipe actions
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == Section.additionalHistoryActions.rawValue {
            return []
        }
        let title: String = Strings.HistoryPanelDelete

        let delete = UITableViewRowAction(style: .default, title: title, handler: { (action, indexPath) in
            self.removeHistoryForURLAtIndexPath(indexPath: indexPath)
        })
        return [delete]
    }
    */
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == Section.additionalHistoryActions.rawValue {
            return nil
        }
        let action = UIContextualAction(style: .destructive, title: Strings.HistoryPanelDelete) { _, _, _ in
            self.removeHistoryForURLAtIndexPath(indexPath: indexPath)
        }
        action.backgroundColor = .Light.State.warning
        return UISwipeActionsConfiguration(actions: [action])
    }


    override func applyTheme() {
        super.applyTheme()
        tableView.reloadData()
        emptyHeader.applyTheme()
        view.backgroundColor = UIColor.theme.homePanel.panelBackground
        tableView.backgroundColor = UIColor.theme.homePanel.panelBackground
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

        let removeAction = PhotonActionSheetItem(title: Strings.DeleteFromHistoryContextMenuTitle, iconString: "action_delete", handler: { _, _ in
            self.removeHistoryForURLAtIndexPath(indexPath: indexPath)
        })

        let pinTopSite = PhotonActionSheetItem(title: Strings.AddToShortcutsActionTitle, iconString: "action_pin", handler: { _, _ in
            self.pinToTopSites(site)
        })
        actions.append(pinTopSite)
        actions.append(removeAction)
        return actions
    }
}
