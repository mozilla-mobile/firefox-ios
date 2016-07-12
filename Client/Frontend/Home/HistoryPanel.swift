/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.browserLogger

private func getDate(dayOffset: Int) -> Date {
    let calendar = Calendar(calendarIdentifier: Calendar.Identifier.gregorian)!
    let nowComponents = calendar.components([Calendar.Unit.year, Calendar.Unit.month, Calendar.Unit.day], from: Date())
    let today = calendar.date(from: nowComponents)!
    return calendar.date(byAdding: Calendar.Unit.day, value: dayOffset, to: today, options: [])!
}

private typealias SectionNumber = Int
private typealias CategoryNumber = Int
private typealias CategorySpec = (section: SectionNumber?, rows: Int, offset: Int)

private struct HistoryPanelUX {
    private static let WelcomeScreenItemTextColor = UIColor.gray()
    private static let WelcomeScreenItemWidth = 170
    private static let SyncedTabsCellChevronInset: CGFloat = 20
    private static let SyncedTabsCellChevronSize: CGFloat = 20
    private static let SyncedTabsCellImageSize: CGFloat = 32
    private static let SyncedTabsCellHeight: CGFloat = 60
    private static let SyncedTabsCellChevronLineWidth: CGFloat = 4.0
    private static let SyncedTabsCellChevronColor = UIColor(red: 92/255, green: 92/255, blue: 92/255, alpha: 1.0)
}

class HistoryPanel: UIViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var profile: Profile!
    private var currentSyncedDevicesCount: Int? = nil
    private lazy var tableViewController: HistoryPanelSiteTableViewController = {
        return HistoryPanelSiteTableViewController()
    }()

    private lazy var recentlyClosedTabsButton: RecentlyClosedTabsButton = {
        let button = RecentlyClosedTabsButton()
        button.addTarget(self, action: #selector(HistoryPanel.recentlyClosedTabsCellWasTapped), for: .touchUpInside)
        return button
    }()

    private lazy var syncedTabsButton: SyncedTabsButton = {
        let button = SyncedTabsButton()
        button.addTarget(self, action: #selector(HistoryPanel.syncedTabsCellWasTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.profile = self.profile
        tableViewController.homePanelDelegate = homePanelDelegate
        tableViewController.historyPanel = self

        self.addChildViewController(tableViewController)
        self.tableViewController.didMove(toParentViewController: self)

        setUpHistoryPanelViews()
    }

    func updateSyncedDevicesCount() -> Success {
        return chainDeferred(self.profile.getCachedClientsAndTabs()) { tabsAndClients in
            self.currentSyncedDevicesCount = tabsAndClients.count
            return succeed()
        }
    }

    func setUpHistoryPanelViews() -> Void {
        return updateSyncedDevicesCount().uponQueue(DispatchQueue.main) { result in
            self.view.addSubview(self.recentlyClosedTabsButton)
            self.view.addSubview(self.tableViewController.view)
            self.view.addSubview(self.syncedTabsButton)

            self.updateNumberOfSyncedDevices(self.currentSyncedDevicesCount)

            self.syncedTabsButton.snp_makeConstraints { make in
                make.leading.trailing.equalTo(self.view)
                make.top.equalTo(self.recentlyClosedTabsButton.snp_bottom)
                make.height.equalTo(HistoryPanelUX.SyncedTabsCellHeight)
                make.bottom.equalTo(self.tableViewController.view.snp_top)
            }
            self.recentlyClosedTabsButton.snp_makeConstraints { make in
                make.top.leading.trailing.equalTo(self.view)
                make.height.equalTo(HistoryPanelUX.SyncedTabsCellHeight)
                make.bottom.equalTo(self.syncedTabsButton.snp_top)
            }
            self.tableViewController.view.snp_makeConstraints { make in
                make.top.equalTo(self.syncedTabsButton.snp_bottom)
                make.leading.trailing.bottom.equalTo(self.view)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        recentlyClosedTabsButton.enabled = profile.recentlyClosedTabs.tabs.count > 0
    }

    func updateNumberOfSyncedDevices(_ count: Int?) {
        if let count = count where count > 0 {
            self.syncedTabsButton.descriptionLabel.text = String.localizedStringWithFormat(Strings.SyncedTabsTableViewCellDescription, count)
            self.syncedTabsButton.descriptionLabel.isHidden = false
        } else {
            self.syncedTabsButton.descriptionLabel.isHidden = true
            self.syncedTabsButton.updateConstraints()
        }
        self.syncedTabsButton.updateConstraints()
    }

    @objc private func syncedTabsCellWasTapped() {
        let nextController = RemoteTabsPanel()
        nextController.homePanelDelegate = self.homePanelDelegate
        nextController.profile = self.profile
        tableViewController.refreshControl?.endRefreshing()
        self.navigationController?.pushViewController(nextController, animated: true)
    }

    @objc private func recentlyClosedTabsCellWasTapped() {
        let nextController = RecentlyClosedTabsPanel()
        nextController.homePanelDelegate = self.homePanelDelegate
        nextController.profile = self.profile
        tableViewController.refreshControl?.endRefreshing()
        self.navigationController?.pushViewController(nextController, animated: true)
    }
}

class HistoryPanelSiteTableViewController: SiteTableViewController {
    weak var homePanelDelegate: HomePanelDelegate?
    weak var historyPanel: HistoryPanel?

    var refreshControl: UIRefreshControl?

    private lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverlayView()

    private let QueryLimit = 100
    private let NumSections = 4
    private let Today = getDate(dayOffset: 0)
    private let Yesterday = getDate(dayOffset: -1)
    private let ThisWeek = getDate(dayOffset: -7)

    init() {
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryPanelSiteTableViewController.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)
        NotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryPanelSiteTableViewController.notificationReceived(_:)), name: NotificationPrivateDataClearedHistory, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryPanelSiteTableViewController.notificationReceived(_:)), name: NSNotification.Name(rawValue: NotificationDynamicFontChanged), object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "History List"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearedHistory, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationDynamicFontChanged), object: nil)
    }

    func notificationReceived(_ notification: Notification) {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Add a refresh control if the user is logged in and the control was not added before. If the user is not
        // logged in, remove any existing control but only when it is not currently refreshing. Otherwise, wait for
        // the refresh to finish before removing the control.
        if profile.hasSyncableAccount() && refreshControl == nil {
            addRefreshControl()
        } else if refreshControl?.isRefreshing == false {
            removeRefreshControl()
        }
        historyPanel?.updateSyncedDevicesCount().uponQueue(DispatchQueue.main) { result in
            self.historyPanel?.updateNumberOfSyncedDevices(self.historyPanel?.currentSyncedDevicesCount)
        }
    }

    /**
     * fetch from the profile
     **/
    private func fetchData() -> Deferred<Maybe<Cursor<Site>>> {
        return profile.history.getSitesByLastVisit(withLimit: QueryLimit)
    }

    private func setData(_ data: Cursor<Site>) {
        self.data = data
        self.computeSectionOffsets()
    }

    /**
     * sync history with the server and ensure that we update our view afterwards
     **/
    func resyncHistory() {
        profile.syncManager.syncHistory().uponQueue(DispatchQueue.main) { result in
            if result.isSuccess {
                self.reloadData()
            } else {
                self.endRefreshing()
            }

            self.historyPanel?.updateSyncedDevicesCount().uponQueue(dispatch_get_main_queue()) { result in
                self.historyPanel?.updateNumberOfSyncedDevices(self.historyPanel?.currentSyncedDevicesCount)
            }
        }
    }

    func addRefreshControl() {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(HistoryPanelSiteTableViewController.refresh), for: UIControlEvents.valueChanged)
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
        self.fetchData().uponQueue(DispatchQueue.main) { result in
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
            if self.emptyStateOverlayView.superview == nil {
                self.tableView.addSubview(self.emptyStateOverlayView)
                self.emptyStateOverlayView.snp_makeConstraints { make -> Void in
                    make.edges.equalTo(self.tableView)
                    make.size.equalTo(self.view)
                }
            }
        } else {
            self.emptyStateOverlayView.removeFromSuperview()
        }
    }

    private func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white()

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = Strings.HistoryPanelEmptyStateTitle
        welcomeLabel.textAlignment = NSTextAlignment.center
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let category = self.categories[(indexPath as NSIndexPath).section]

        if let site = data[indexPath.row + category.offset] {
            if let cell = cell as? TwoLineTableViewCell {
                cell.setLines(site.title, detailText: site.url)
                cell.imageView?.setIcon(site.icon, withPlaceholder: FaviconFetcher.getDefaultFavicon(site.tileURL))
            }
        }

        return cell
    }

    private func site(forIndexPath indexPath: NSIndexPath) -> Site? {
        let offset = self.categories[sectionLookup[indexPath.section]!].offset
        return data[indexPath.row + offset]
    }

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if let site = self.site(forIndexPath: indexPath),
           let url = URL(string: site.url) {
            let visitType = VisitType.Typed    // Means History, too.
            if let homePanelDelegate = homePanelDelegate,
                   historyPanel = historyPanel {
                homePanelDelegate.homePanel(historyPanel, didSelectURL: url, visitType: visitType)
            }
            return
        }
        log.warning("No site or no URL when selecting row.")
    }

    // Functions that deal with showing header rows.
    func numberOfSections(in tableView: UITableView) -> Int {
        var count = 0
        for category in self.categories {
            if category.rows > 0 {
                count += 1
            }
        }
        return count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = String()
        switch sectionLookup[section]! {
        case 0: title = NSLocalizedString("Today", comment: "History tableview section header")
        case 1: title = NSLocalizedString("Yesterday", comment: "History tableview section header")
        case 2: title = NSLocalizedString("Last week", comment: "History tableview section header")
        case 3: title = NSLocalizedString("Last month", comment: "History tableview section header")
        default:
            assertionFailure("Invalid history section \(section)")
        }
        return title
    }

    func category(forDate date: MicrosecondTimestamp) -> Int {
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

    private func isInCategory(_ date: MicrosecondTimestamp, category: Int) -> Bool {
        return self.category(forDate: date) == category
    }

    func computeSectionOffsets() {
        var counts = [Int](repeating: 0, count: NumSections)

        // Loop over all the data. Record the start of each "section" of our list.
        for i in 0..<data.count {
            if let site = data[i] {
                counts[category(forDate: site.latestVisit!.date)] += 1
            }
        }

        var section = 0
        var offset = 0
        self.categories = [CategorySpec]()
        for i in 0..<NumSections {
            let count = counts[i]
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
    private func uiSectionToCategory(_ section: SectionNumber) -> CategoryNumber {
        for i in 0..<self.categories.count {
            if let s = self.categories[i].section where s == section {
                return i
            }
        }
        return 0
    }

    private func categoryToUISection(_ category: CategoryNumber) -> SectionNumber? {
        return self.categories[category].section
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories[uiSectionToCategory(section)].rows
    }

    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [AnyObject]? {
        let title = NSLocalizedString("Remove", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the history panel.")

        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: title, handler: { (action, indexPath) in
            if let site = self.site(forIndexPath: indexPath) {
                // Why the dispatches? Because we call success and failure on the DB
                // queue, and so calling anything else that calls through to the DB will
                // deadlock. This problem will go away when the history API switches to
                // Deferred instead of using callbacks.
                self.profile.history.removeHistory(forURL: site.url)
                    .upon { res in
                        self.fetchData().uponQueue(DispatchQueue.main) { result in
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

class SyncedTabsButton: UIButton {
    private let ImageMargin: CGFloat = 12

    lazy var title: UILabel = {
        let label = UILabel()
        label.textColor = TwoLineCellUX.TextColor
        label.text = Strings.SyncedTabsTableViewCellTitle
        label.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallHistoryPanel
        label.textColor = TwoLineCellUX.DetailTextColor
        return label
    }()

    lazy var image: UIImageView = {
        let image = UIImage(named: "panelIconSyncedTabs")!
        return UIImageView(image: image)
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .right)
        chevron.tintColor = HistoryPanelUX.SyncedTabsCellChevronColor
        chevron.lineWidth = 3.0
        return chevron
    }()

    lazy var topBorder: UIView = self.createBorderView()
    lazy var bottomBorder: UIView = self.createBorderView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = SiteTableViewControllerUX.HeaderBackgroundColor

        addSubview(topBorder)
        addSubview(bottomBorder)
        addSubview(chevron)
        addSubview(title)
        addSubview(image)
        addSubview(descriptionLabel)


        image.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(TwoLineCellUX.BorderViewMargin)
            make.centerY.equalTo(self)
            make.width.equalTo(HistoryPanelUX.SyncedTabsCellImageSize)
        }

        chevron.snp_makeConstraints { make in
            make.trailing.equalTo(self).offset(-HistoryPanelUX.SyncedTabsCellChevronInset)
            make.centerY.equalTo(self)
            make.size.equalTo(HistoryPanelUX.SyncedTabsCellChevronSize)
        }

        topBorder.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp_makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.leading.equalTo(image.snp_trailing).offset(TwoLineCellUX.BorderViewMargin)
            make.centerY.equalTo(self).offset(10)
        }

        updateConstraints()
    }

    private func createBorderView() -> UIView {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }

    override func updateConstraints() {
        super.updateConstraints()

        title.snp_remakeConstraints { make in
            make.leading.equalTo(image.snp_trailing).offset(TwoLineCellUX.BorderViewMargin)
            make.centerY.equalTo(self).offset(descriptionLabel.isHidden ? 0 : -10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RecentlyClosedTabsButton: UIButton {
    private let ImageMargin: CGFloat = 12

    override var isEnabled: Bool {
        didSet {
            super.isEnabled = isEnabled
            self.alpha = isEnabled ? 1.0 : 0.5
        }
    }

    lazy var title: UILabel = {
        let label = UILabel()
        label.textColor = TwoLineCellUX.TextColor
        label.text = Strings.RecentlyClosedTabsButtonTitle
        label.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallHistoryPanel
        label.textColor = TwoLineCellUX.DetailTextColor
        return label
    }()

    lazy var image: UIImageView = {
        let image = UIImage(named: "panelIconHistory")!
        return UIImageView(image: image)
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .right)
        chevron.tintColor = HistoryPanelUX.SyncedTabsCellChevronColor
        chevron.lineWidth = 3.0
        return chevron
    }()

    lazy var topBorder: UIView = self.createBorderView()
    lazy var bottomBorder: UIView = self.createBorderView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = SiteTableViewControllerUX.HeaderBackgroundColor

        addSubview(topBorder)
        addSubview(bottomBorder)
        addSubview(chevron)
        addSubview(title)
        addSubview(image)
        addSubview(descriptionLabel)

        title.snp_makeConstraints { make in
            make.leading.equalTo(image.snp_trailing).offset(TwoLineCellUX.BorderViewMargin * 1.25)
            make.centerY.equalTo(self)
        }

        image.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(TwoLineCellUX.BorderViewMargin * 1.3)
            make.centerY.equalTo(self)
            make.size.equalTo(24)
        }

        chevron.snp_makeConstraints { make in
            make.trailing.equalTo(self).offset(-HistoryPanelUX.SyncedTabsCellChevronInset)
            make.centerY.equalTo(self)
            make.size.equalTo(HistoryPanelUX.SyncedTabsCellChevronSize)
        }

        topBorder.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp_makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.leading.equalTo(image.snp_trailing).offset(TwoLineCellUX.BorderViewMargin)
            make.centerY.equalTo(self).offset(10)
        }
    }

    private func createBorderView() -> UIView {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
