/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.browserLogger

private func getDate(dayOffset dayOffset: Int) -> NSDate {
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let nowComponents = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: NSDate())
    let today = calendar.dateFromComponents(nowComponents)!
    return calendar.dateByAddingUnit(NSCalendarUnit.Day, value: dayOffset, toDate: today, options: [])!
}

private typealias SectionNumber = Int
private typealias CategoryNumber = Int
private typealias CategorySpec = (section: SectionNumber?, rows: Int, offset: Int)

private struct HistoryPanelUX {
    private static let WelcomeScreenItemTextColor = UIColor.grayColor()
    private static let WelcomeScreenItemWidth = 170
}

class HistoryPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    private var currentSyncedDevicesCount: Int? = nil

    var events = [NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory, NotificationDynamicFontChanged]
    var refreshControl: UIRefreshControl?

    private lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverlayView()

    private let QueryLimit = 100
    private let NumSections = 5
    private let Today = getDate(dayOffset: 0)
    private let Yesterday = getDate(dayOffset: -1)
    private let ThisWeek = getDate(dayOffset: -7)

    var syncDetailText = ""
    var hasRecentlyClosed = false

    func updateSyncedDevicesCount() -> Success {
        return chainDeferred(self.profile.getCachedClientsAndTabs()) { tabsAndClients in
            self.currentSyncedDevicesCount = tabsAndClients.count
            return succeed()
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        events.forEach {NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryPanel.notificationReceived(_:)), name: $0, object: nil)}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "History List"
        updateSyncedDevicesCount().uponQueue(dispatch_get_main_queue()) { result in
            self.updateNumberOfSyncedDevices(self.currentSyncedDevicesCount)
        }
    }

    func updateNumberOfSyncedDevices(count: Int?) {
        if let count = count where count > 0 {
            syncDetailText = String.localizedStringWithFormat(Strings.SyncedTabsTableViewCellDescription, count)
        } else {
            syncDetailText = ""
        }
        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)], withRowAnimation: .Automatic)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showSyncedTabs() {
        let nextController = RemoteTabsPanel()
        nextController.homePanelDelegate = self.homePanelDelegate
        nextController.profile = self.profile
        self.refreshControl?.endRefreshing()
        self.navigationController?.pushViewController(nextController, animated: true)
    }

    func showRecentlyClosed() {
        if !hasRecentlyClosed {
            return
        }
        let nextController = RecentlyClosedTabsPanel()
        nextController.homePanelDelegate = self.homePanelDelegate
        nextController.profile = self.profile
        self.refreshControl?.endRefreshing()
        self.navigationController?.pushViewController(nextController, animated: true)
    }

    deinit {
        events.forEach { NSNotificationCenter.defaultCenter().removeObserver(self, name: $0, object: nil) }
    }

    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory:
            if self.profile.hasSyncableAccount() {
                resyncHistory()
            }
            break
        case NotificationDynamicFontChanged:
            if emptyStateOverlayView.superview != nil {
                emptyStateOverlayView.removeFromSuperview()
            }
            emptyStateOverlayView = createEmptyStateOverlayView()
            resyncHistory()
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    // Category number (index) -> (UI section, row count, cursor offset).
    private var categories: [CategorySpec] = [CategorySpec]()

    // Reverse lookup from UI section to data category.
    private var sectionLookup = [SectionNumber: CategoryNumber]()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        hasRecentlyClosed = profile.recentlyClosedTabs.tabs.count > 0

        if profile.hasSyncableAccount() && refreshControl == nil {
            addRefreshControl()
        } else if refreshControl?.refreshing == false {
            removeRefreshControl()
        }
        self.updateSyncedDevicesCount().uponQueue(dispatch_get_main_queue()) { result in
            self.updateNumberOfSyncedDevices(self.currentSyncedDevicesCount)
        }
    }

    /**
     * fetch from the profile
     **/
    private func fetchData() -> Deferred<Maybe<Cursor<Site>>> {
        return profile.history.getSitesByLastVisit(QueryLimit)
    }

    private func setData(data: Cursor<Site>) {
        self.data = data
        self.computeSectionOffsets()
    }

    /**
     * sync history with the server and ensure that we update our view afterwards
     **/
    func resyncHistory() {
        profile.syncManager.syncHistory().uponQueue(dispatch_get_main_queue()) { result in
            if result.isSuccess {
                self.reloadData()
            } else {
                self.endRefreshing()
            }

            self.updateSyncedDevicesCount().uponQueue(dispatch_get_main_queue()) { result in
                self.updateNumberOfSyncedDevices(self.currentSyncedDevicesCount)
            }
        }
    }

    func addRefreshControl() {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(HistoryPanel.refresh), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refresh
        self.tableView.addSubview(refresh)
    }

    func removeRefreshControl() {
        self.refreshControl?.removeFromSuperview()
        self.refreshControl = nil
    }

    func endRefreshing() {
        // Always end refreshing, even if we failed!
        self.refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        if !self.profile.hasSyncableAccount() {
            self.removeRefreshControl()
        }
    }

    /**
     * called by the table view pull to refresh
     **/
    @objc func refresh() {
        self.refreshControl?.beginRefreshing()
        resyncHistory()
    }

    /**
     * Update our view after a data refresh
     **/
    override func reloadData() {
        self.fetchData().uponQueue(dispatch_get_main_queue()) { result in
            if let data = result.successValue {
                self.setData(data)
                self.tableView.reloadData()
                self.updateEmptyPanelState()
            }
            self.endRefreshing()
            // TODO: error handling.
        }
    }

    private func updateEmptyPanelState() {
        if data.count == 0 {
            self.tableView.alwaysBounceVertical = false
            if self.emptyStateOverlayView.superview == nil {
                self.tableView.addSubview(self.emptyStateOverlayView)
                self.emptyStateOverlayView.snp_makeConstraints { make -> Void in
                    make.left.right.bottom.equalTo(self.view)
                    make.top.equalTo(self.view).offset(100)
                }
            }
        } else {
            self.tableView.alwaysBounceVertical = true
            self.emptyStateOverlayView.removeFromSuperview()
        }
    }

    private func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.whiteColor()

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = Strings.HistoryPanelEmptyStateTitle
        welcomeLabel.textAlignment = NSTextAlignment.Center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.textColor = HistoryPanelUX.WelcomeScreenItemTextColor
        welcomeLabel.numberOfLines = 0
        welcomeLabel.adjustsFontSizeToFitWidth = true

        welcomeLabel.snp_makeConstraints { make in
            make.centerX.equalTo(overlayView)
            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(HomePanelUX.EmptyTabContentOffset).priorityMedium()

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
            make.width.equalTo(HistoryPanelUX.WelcomeScreenItemWidth)
        }
        return overlayView
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        cell.accessoryType = UITableViewCellAccessoryType.None
        if indexPath.section == 0 {
            return indexPath.row == 0 ? configureRecentlyClosedCell(cell, forIndexPath: indexPath) : configureSyncedTabs(cell, forIndexPath: indexPath)
        } else {
            return configureSiteCell(cell, forIndexPath: indexPath)
        }
    }



    func configureRecentlyClosedCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        cell.textLabel!.text = Strings.RecentlyClosedTabsButtonTitle
        cell.detailTextLabel!.text = ""
        cell.imageView!.image = UIImage(named: "closed_recently")
        cell.imageView?.backgroundColor = UIColor.whiteColor()
        cell.imageView!.highlightedImage = cell.imageView!.image
        if !hasRecentlyClosed {
            cell.textLabel?.alpha = 0.5
            cell.imageView!.alpha = 0.5
            cell.selectionStyle = .None
        }
        return cell
    }

    func configureSyncedTabs(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        cell.textLabel!.text = Strings.SyncedTabsTableViewCellTitle
        cell.detailTextLabel!.text = self.syncDetailText
        cell.imageView!.image = UIImage(named: "context_sync")
        cell.imageView?.backgroundColor = UIColor.whiteColor()
        cell.imageView!.highlightedImage = cell.imageView!.image
        return cell
    }

    func configureSiteCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let category = categories[indexPath.section]
        if let site = data[indexPath.row + category.offset], let cell = cell as? TwoLineTableViewCell {
            cell.setLines(site.title, detailText: site.url)
            cell.imageView?.setIcon(site.icon, forURL: site.tileURL)
        }
        return cell
    }

    private func siteForIndexPath(indexPath: NSIndexPath) -> Site? {
        let offset = self.categories[sectionLookup[indexPath.section]!].offset
        return data[indexPath.row + offset]
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return indexPath.row == 0 ? self.showRecentlyClosed() : self.showSyncedTabs()
        }
        if let site = self.siteForIndexPath(indexPath),
           let url = NSURL(string: site.url) {
            let visitType = VisitType.Typed    // Means History, too.
            if let homePanelDelegate = homePanelDelegate {
                homePanelDelegate.homePanel(self, didSelectURL: url, visitType: visitType)
            }
            return
        }
        log.warning("No site or no URL when selecting row.")

    }

    // Functions that deal with showing header rows.
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count = 1
        for category in self.categories {
            if category.rows > 0 {
                count += 1
            }
        }
        return count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = String()
        switch sectionLookup[section]! {
        case 0: return nil
        case 1: title = NSLocalizedString("Today", comment: "History tableview section header")
        case 2: title = NSLocalizedString("Yesterday", comment: "History tableview section header")
        case 3: title = NSLocalizedString("Last week", comment: "History tableview section header")
        case 4: title = NSLocalizedString("Last month", comment: "History tableview section header")
        default:
            assertionFailure("Invalid history section \(section)")
        }
        return title
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        }
        return super.tableView(tableView, viewForHeaderInSection: section)
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }


    func categoryForDate(date: MicrosecondTimestamp) -> Int {
        let date = Double(date)
        if date > (1000000 * Today.timeIntervalSince1970) {
            return 0
        }
        if date > (1000000 * Yesterday.timeIntervalSince1970) {
            return 1
        }
        if date > (1000000 * ThisWeek.timeIntervalSince1970) {
            return 2
        }
        return 3
    }

    private func isInCategory(date: MicrosecondTimestamp, category: Int) -> Bool {
        return self.categoryForDate(date) == category
    }

    func computeSectionOffsets() {
        var counts = [Int](count: NumSections, repeatedValue: 0)

        // Loop over all the data. Record the start of each "section" of our list.
        for i in 0..<data.count {
            if let site = data[i] {
                counts[categoryForDate(site.latestVisit!.date) + 1] += 1
            }
        }

        var section = 0
        var offset = 0
        self.categories = [CategorySpec]()
        for i in 0..<NumSections {
            let count = counts[i]
            if i == 0 {
                sectionLookup[section] = i
                section += 1
            }
            if count > 0 {
                log.debug("Category \(i) has \(count) rows, and thus is section \(section).")
                self.categories.append((section: section, rows: count, offset: offset))
                sectionLookup[section] = i
                offset += count
                section += 1
            } else {
                log.debug("Category \(i) has 0 rows, and thus has no section.")
                self.categories.append((section: nil, rows: 0, offset: offset))
            }
        }
    }

    // UI sections disappear as categories empty. We need to translate back and forth.
    private func uiSectionToCategory(section: SectionNumber) -> CategoryNumber {
        for i in 0..<self.categories.count {
            if let s = self.categories[i].section where s == section {
                return i
            }
        }
        return 0
    }

    private func categoryToUISection(category: CategoryNumber) -> SectionNumber? {
        return self.categories[category].section
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return self.categories[uiSectionToCategory(section)].rows
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        if indexPath.section == 0 {
            return []
        }
        let title = NSLocalizedString("Remove", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the history panel.")
        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title, handler: { (action, indexPath) in
            if let site = self.siteForIndexPath(indexPath) {
                // Why the dispatches? Because we call success and failure on the DB
                // queue, and so calling anything else that calls through to the DB will
                // deadlock. This problem will go away when the history API switches to
                // Deferred instead of using callbacks.
                self.profile.history.removeHistoryForURL(site.url)
                    .upon { res in
                        self.fetchData().uponQueue(dispatch_get_main_queue()) { result in
                            // If a section will be empty after removal, we must remove the section itself.
                            if let data = result.successValue {

                                let oldCategories = self.categories
                                self.data = data
                                self.computeSectionOffsets()

                                let sectionsToDelete = NSMutableIndexSet()
                                var rowsToDelete = [NSIndexPath]()
                                let sectionsToAdd = NSMutableIndexSet()
                                var rowsToAdd = [NSIndexPath]()

                                for (index, category) in self.categories.enumerate() {
                                    let oldCategory = oldCategories[index]

                                    // don't bother if we're not displaying this category
                                    if oldCategory.section == nil && category.section == nil {
                                        continue
                                    }

                                    // 1. add a new section if the section didn't previously exist
                                    if oldCategory.section == nil && category.section != oldCategory.section {
                                        log.debug("adding section \(category.section)")
                                        sectionsToAdd.addIndex(category.section!)
                                    }

                                    // 2. add a new row if there are more rows now than there were before
                                    if oldCategory.rows < category.rows {
                                        log.debug("adding row to \(category.section) at \(category.rows-1)")
                                        rowsToAdd.append(NSIndexPath(forRow: category.rows-1, inSection: category.section!))
                                    }

                                    // if we're dealing with the section where the row was deleted:
                                    // 1. if the category no longer has a section, then we need to delete the entire section
                                    // 2. delete a row if the number of rows has been reduced
                                    // 3. delete the selected row and add a new one on the bottom of the section if the number of rows has stayed the same
                                    if oldCategory.section == indexPath.section {
                                        if category.section == nil {
                                            log.debug("deleting section \(indexPath.section)")
                                            sectionsToDelete.addIndex(indexPath.section)
                                        } else if oldCategory.section == category.section {
                                            if oldCategory.rows > category.rows {
                                                log.debug("deleting row from \(category.section) at \(indexPath.row)")
                                                rowsToDelete.append(indexPath)
                                            } else if category.rows == oldCategory.rows {
                                                log.debug("in section \(category.section), removing row at \(indexPath.row) and inserting row at \(category.rows-1)")
                                                rowsToDelete.append(indexPath)
                                                rowsToAdd.append(NSIndexPath(forRow: category.rows-1, inSection: indexPath.section))
                                            }
                                        }
                                    }
                                }

                                tableView.beginUpdates()
                                if sectionsToAdd.count > 0 {
                                    tableView.insertSections(sectionsToAdd, withRowAnimation: UITableViewRowAnimation.Left)
                                }
                                if sectionsToDelete.count > 0 {
                                    tableView.deleteSections(sectionsToDelete, withRowAnimation: UITableViewRowAnimation.Right)
                                }
                                if !rowsToDelete.isEmpty {
                                    tableView.deleteRowsAtIndexPaths(rowsToDelete, withRowAnimation: UITableViewRowAnimation.Right)
                                }

                                if !rowsToAdd.isEmpty {
                                    tableView.insertRowsAtIndexPaths(rowsToAdd, withRowAnimation: UITableViewRowAnimation.Right)
                                }

                                tableView.endUpdates()
                                self.updateEmptyPanelState()
                            }
                        }
                }
            }
        })
        return [delete]
    }
}
