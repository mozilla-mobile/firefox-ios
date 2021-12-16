// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
    enum Section: Int {
        // Showing showing recently closed, and clearing recent history are action rows of this type.
        case additionalHistoryActions
        case today
        case yesterday
        case lastWeek
        case lastMonth
        case older

        static let count = 6

        var title: String? {
            switch self {
            case .today:
                return .LibraryPanel.Sections.Today
            case .yesterday:
                return .LibraryPanel.Sections.Yesterday
            case .lastWeek:
                return .LibraryPanel.Sections.LastWeek
            case .lastMonth:
                return .LibraryPanel.Sections.LastMonth
            case .older:
                return .LibraryPanel.Sections.Older
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
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
            } else {
                cell.titleLabel.alpha = 0.5
                cell.leftImageView.alpha = 0.5
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
    private let clearHistoryHelper: ClearHistoryHelper

    var hasRecentlyClosed: Bool {
        return profile.recentlyClosedTabs.tabs.count > 0
    }

    lazy var emptyStateOverlayView: UIView = createEmptyStateOverlayView()

    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGestureRecognized))
    }()

    // MARK: - Lifecycle
    override init(profile: Profile) {
        self.clearHistoryHelper = ClearHistoryHelper(profile: profile)
        super.init(profile: profile)

        [ Notification.Name.FirefoxAccountChanged,
          Notification.Name.PrivateDataClearedHistory,
          Notification.Name.DynamicFontChanged,
          Notification.Name.DatabaseWasReopened,
          Notification.Name.OpenClearRecentHistory].forEach {
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
        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            if result.isSuccess {
                SimpleToast().showAlertWithText(.AppMenuAddPinToShortcutsConfirmMessage, bottomContainer: self.view)
            }
        }
    }

    func navigateToRecentlyClosed() {
        guard hasRecentlyClosed else {
            return
        }

        let nextController = RecentlyClosedTabsPanel(profile: profile)
        nextController.title = .RecentlyClosedTabsButtonTitle
        nextController.libraryPanelDelegate = libraryPanelDelegate
        nextController.recentlyClosedTabsDelegate = BrowserViewController.foregroundBVC()
        refreshControl?.endRefreshing()
        navigationController?.pushViewController(nextController, animated: true)
    }

    private func showClearRecentHistory() {
        clearHistoryHelper.showClearRecentHistory(onViewController: self, didComplete: { [weak self] in
            self?.reloadData()
        })
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
        cell.titleLabel.text = .HistoryPanelClearHistoryButtonTitle
        cell.leftImageView.image = UIImage.templateImageNamed("forget")
        cell.leftImageView.tintColor = UIColor.theme.browser.tint
        cell.leftImageView.backgroundColor = UIColor.theme.homePanel.historyHeaderIconsBackground
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

    func configureRecentlyClosed(_ cell: OneLineTableViewCell, for indexPath: IndexPath) -> OneLineTableViewCell {
        cell.accessoryType = .disclosureIndicator
        cell.titleLabel.text = .RecentlyClosedTabsButtonTitle
        cell.leftImageView.image = UIImage.templateImageNamed("recently_closed")
        cell.leftImageView.tintColor = UIColor.theme.browser.tint
        cell.leftImageView.backgroundColor = UIColor.theme.homePanel.historyHeaderIconsBackground
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
            cell.leftImageView.layer.borderColor = HistoryPanelUX.IconBorderColor.cgColor
            cell.leftImageView.layer.borderWidth = HistoryPanelUX.IconBorderWidth
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
        case .OpenClearRecentHistory:
            showClearRecentHistory()
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
                clearHistoryHelper.showClearRecentHistory(onViewController: self, didComplete: { [weak self] in
                    self?.reloadData()
                })
                showClearRecentHistory()

            default:
                navigateToRecentlyClosed()
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
            header.contentView.backgroundColor = UIColor.theme.tableView.selectedBackground
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

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section != Section.additionalHistoryActions.rawValue else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: .HistoryPanelDelete) { [weak self] (_, _, completion) in
            guard let strongSelf = self else { completion(false); return }

            strongSelf.removeHistoryForURLAtIndexPath(indexPath: indexPath)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // MARK: - Empty State
    func updateEmptyPanelState() {
        if groupedSites.isEmpty {
            if emptyStateOverlayView.superview == nil {
                tableView.tableFooterView = emptyStateOverlayView
            }
        } else {
            tableView.alwaysBounceVertical = true
            tableView.tableFooterView = nil
        }
    }

    func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()

        // overlayView becomes the footer view, and for unknown reason, setting the bgcolor is ignored.
        // Create an explicit view for setting the color.
        let bgColor = UIView()
        bgColor.backgroundColor = UIColor.theme.homePanel.panelBackground
        overlayView.addSubview(bgColor)
        bgColor.snp.makeConstraints { make in
            // Height behaves oddly: equalToSuperview fails in this case, as does setting top.equalToSuperview(), simply setting this to ample height works.
            make.height.equalTo(UIScreen.main.bounds.height)
            make.width.equalToSuperview()
        }

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = .HistoryPanelEmptyStateTitle
        welcomeLabel.textAlignment = .center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.textColor = UIColor.theme.homePanel.welcomeScreenText
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

        let removeAction = PhotonActionSheetItem(title: .DeleteFromHistoryContextMenuTitle, iconString: "action_delete", handler: { _, _ in
            self.removeHistoryForURLAtIndexPath(indexPath: indexPath)
        })

        let pinTopSite = PhotonActionSheetItem(title: .AddToShortcutsActionTitle, iconString: "action_pin", handler: { _, _ in
            self.pinToTopSites(site)
        })
        actions.append(pinTopSite)
        actions.append(removeAction)
        return actions
    }
}
