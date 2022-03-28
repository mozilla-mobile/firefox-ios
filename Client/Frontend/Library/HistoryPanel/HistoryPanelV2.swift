// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

// TODO: HistoryPanel AND HistoryPanelV2 currently coexist until v100. Revert https://github.com/mozilla-mobile/firefox-ios/pull/10259 in v100.
// Related to: https://mozilla-hub.atlassian.net/browse/FXIOS-2931 

import UIKit
import Shared
import Storage
import XCGLogger
import WebKit
import os.log

private struct HistoryPanelUX {
    static let WelcomeScreenItemWidth = 170
    static let HeaderHeight = CGFloat(32)
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
class HistoryPanelV2: UIViewController, LibraryPanel, Loggable, NotificationThemeable {
    
    // MARK: - Properties
    
    typealias HistoryPanelSections = HistoryPanelViewModel.Sections
    typealias a11yIds = AccessibilityIdentifiers.LibraryPanels.HistoryPanel
    
    var libraryPanelDelegate: LibraryPanelDelegate?
    var recentlyClosedTabsDelegate: RecentlyClosedPanelDelegate?
    
    let profile: Profile
    let viewModel: HistoryPanelViewModel
    private let clearHistoryHelper: ClearHistoryHelper
    
    // We'll be able to prefetch more often the higher this number is. But remember, it's expensive!
    private let historyPanelPrefetchOffset = 8

    private var diffableDatasource: UITableViewDiffableDataSource<HistoryPanelSections, AnyHashable>?
    private var hasRecentlyClosed: Bool { profile.recentlyClosedTabs.tabs.count > 0 }
    
    // UI
    lazy private var tableView: UITableView = .build { [weak self] tableView in
        guard let self = self else { return }
        tableView.dataSource = self.diffableDatasource
        tableView.addGestureRecognizer(self.longPressRecognizer)
        tableView.accessibilityIdentifier = a11yIds.tableView
        tableView.prefetchDataSource = self
        tableView.delegate = self
        tableView.register(TwoLineImageOverlayCell.self, forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier)
        tableView.register(TwoLineImageOverlayCell.self, forCellReuseIdentifier: TwoLineImageOverlayCell.accessoryUsageReuseIdentifier)
        tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: OneLineTableViewCell.cellIdentifier)
        tableView.register(SiteTableViewHeader.self, forHeaderFooterViewReuseIdentifier: SiteTableViewHeader.cellIdentifier)
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGestureRecognized))
    }()
    
    lazy var emptyStateOverlayView: UIView = createEmptyStateOverlayView()
    var refreshControl: UIRefreshControl?
    var clearHistoryCell: OneLineTableViewCell?
    
    // MARK: - Inits
    
    init(profile: Profile, tabManager: TabManager) {
        self.clearHistoryHelper = ClearHistoryHelper(profile: profile, tabManager: tabManager)
        self.viewModel = HistoryPanelViewModel(profile: profile)
        self.profile = profile
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        browserLog.debug("HistoryPanel Deinitialized.")
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.viewDidLoad()
        viewModel.historyPanelNotifications.forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: $0, object: nil)
        }
        
        setupLayout()
        configureDatasource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Add a refresh control if the user is logged in and the control was not added before. If the user is not
        // logged in, remove any existing control.
        handleRefreshControl()
        applySnapshot()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Since the reload operation to fetch STG completes LATE, we need to apply snapshot again here :(
        // Especially in the case where you navigate to the history panel from another panel.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.applySnapshot(animatingDifferences: true)
        }
        
    }
    
    // MARK: - Misc. helpers
    
    private func setupLayout() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    // Use to enable/disable the additional history action rows. `HistoryActionablesModel`
    private func setTappableStateAndStyle(with item: AnyHashable, on cell: OneLineTableViewCell) {
        var isEnabled: Bool = false
        
        if let actionableItem = item as? HistoryActionablesModel {
            switch actionableItem.itemIdentity {
            case .clearHistory:
                viewModel.groupedSites.isEmpty ? (isEnabled = false) : (isEnabled = true)
            case .recentlyClosed:
                isEnabled = hasRecentlyClosed
            default: break
            }
        }
        
        // Set interaction behavior and style
        if isEnabled {
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
    
    // MARK: - Datasource helpers
    
    func siteAt(indexPath: IndexPath) -> Site? {
        guard let siteItem = diffableDatasource?.itemIdentifier(for: indexPath) as? Site else { return nil }
        
        return siteItem
    }

    private func showClearRecentHistory() {
        clearHistoryHelper.showClearRecentHistory(onViewController: self, didComplete: { [weak self] date in
            if let date = date {
                self?.viewModel.removeVisibleSectionFor(date: date)
            } else {
                // The only time there's no date is when we are deleting everything.
                self?.viewModel.visibleSections = []
            }
            
            self?.viewModel.reloadData()
            self?.applySnapshot(animatingDifferences: true)
            
            if let cell = self?.clearHistoryCell {
                self?.setTappableStateAndStyle(
                    with: HistoryActionablesModel.activeActionables.first(where: { $0.itemIdentity == .clearHistory }),
                    on: cell)
            }
        })
        
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .PrivateDataClearedHistory:
            viewModel.groupedSites = DateGroupedTableData<Site>()
            
            viewModel.reloadData()
            applySnapshot(animatingDifferences: true)

            if profile.hasSyncableAccount() {
                resyncHistory()
            }
            break
        case .DynamicFontChanged:
            if emptyStateOverlayView.superview != nil {
                emptyStateOverlayView.removeFromSuperview()
            }
            emptyStateOverlayView = createEmptyStateOverlayView()
            resyncHistory()
            break
        case .DatabaseWasReopened:
            if let dbName = notification.object as? String, dbName == "browser.db" {
                viewModel.reloadData()
                applySnapshot(animatingDifferences: true)
            }
        case .OpenClearRecentHistory:
            showClearRecentHistory()
        default:
            // no need to do anything at all
            browserLog.error("Error: Received unexpected notification \(notification.name)")
            break
        }
    }

    // MARK: - UITableViewDataSource
    
    private func configureHistoryActionableCell(_ historyActionable: HistoryActionablesModel, _ cell: OneLineTableViewCell) -> OneLineTableViewCell {
        cell.titleLabel.text = historyActionable.itemTitle
        cell.leftImageView.image = historyActionable.itemImage
        cell.leftImageView.tintColor = .theme.browser.tint
        cell.leftImageView.backgroundColor = .theme.homePanel.historyHeaderIconsBackground
        cell.accessibilityIdentifier = historyActionable.itemA11yId
        self.setTappableStateAndStyle(with: historyActionable, on: cell)
        
        return cell
    }
    
    private func configureSiteCell(_ site: Site, _ cell: TwoLineImageOverlayCell) -> TwoLineImageOverlayCell {
        cell.titleLabel.text = site.title
        cell.titleLabel.isHidden = site.title.isEmpty
        cell.descriptionLabel.text = site.url
        cell.descriptionLabel.isHidden = false
        cell.leftImageView.layer.borderColor = HistoryPanelUX.IconBorderColor.cgColor
        cell.leftImageView.layer.borderWidth = HistoryPanelUX.IconBorderWidth
        cell.leftImageView.contentMode = .center
        cell.leftImageView.setImageAndBackground(forIcon: site.icon, website: site.tileURL) { [weak cell] in
            cell?.leftImageView.image = cell?.leftImageView.image?.createScaled(CGSize(width: HistoryPanelUX.IconSize, height: HistoryPanelUX.IconSize))
        }
        
        return cell
    }
    
    private func configureASGroupCell(_ asGroup: ASGroup<Site>, _ cell: TwoLineImageOverlayCell) -> TwoLineImageOverlayCell {
        if let groupCount = asGroup.description {
            cell.descriptionLabel.text = "\(groupCount) sites"
        }
        
        cell.titleLabel.text = asGroup.displayTitle
        cell.leftImageView.layer.borderWidth = 0
        cell.leftImageView.contentMode = .center
        cell.chevronAccessoryView.isHidden = false
        cell.leftImageView.setImageAndBackground(forIcon: nil, website: nil) { [weak cell] in
            cell?.leftImageView.image = cell?.leftImageView.image?.createScaled(CGSize(width: HistoryPanelUX.IconSize, height: HistoryPanelUX.IconSize))
            cell?.leftImageView.image = UIImage(named: ImageIdentifiers.stackedTabsIcon)
        }
        
        return cell
    }
    
    /// Handles dequeuing the appropriate type of cell when needed.
    private func configureDatasource() {
        diffableDatasource = UITableViewDiffableDataSource<HistoryPanelSections, AnyHashable>(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else {
                Logger.browserLogger.error("History Panel - self became nil inside diffableDatasource!")
                return nil
            }
            
            if let historyActionable = item as? HistoryActionablesModel {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: OneLineTableViewCell.cellIdentifier, for: indexPath) as? OneLineTableViewCell else {
                    self.browserLog.error("History Panel - cannot create OneLineTableViewCell for historyActionable!")
                    return nil
                }
                
                let actionableCell = self.configureHistoryActionableCell(historyActionable, cell)
                return actionableCell
            }
            
            if let site = item as? Site {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.cellIdentifier, for: indexPath) as? TwoLineImageOverlayCell else {
                    self.browserLog.error("History Panel - cannot create TwoLineImageOverlayCell for site!")
                    return nil
                }
                
                let siteCell = self.configureSiteCell(site, cell)
                return siteCell
            }
            
            if let searchTermGroup = item as? ASGroup<Site> {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.accessoryUsageReuseIdentifier, for: indexPath) as? TwoLineImageOverlayCell else {
                    self.browserLog.error("History Panel - cannot create TwoLineImageOverlayCell for STG!")
                    return nil
                }
                
                let asGroupCell = self.configureASGroupCell(searchTermGroup, cell)
                return asGroupCell
            }
            
            // This should never happen! You will have an empty row!
            return UITableViewCell()
        }
        
    }
    
    /// The data source gets populated here for your choice of section.
    fileprivate func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<HistoryPanelSections, AnyHashable>()
        
        snapshot.appendSections(viewModel.visibleSections)
        
        snapshot.sectionIdentifiers.forEach { section in
            snapshot.appendItems(viewModel.groupedSites.itemsForSection(section.rawValue - 1), toSection: section)
        }
        
        // Insert the ASGroup at the correct spot!
        viewModel.searchTermGroups.forEach { grouping in
            if let groupSection = viewModel.groupBelongsToSection(asGroup: grouping), viewModel.visibleSections.contains(groupSection) {
                guard let individualItem = grouping.groupedItems.last, let lastVisit = individualItem.latestVisit else { return }
                
                let groupTimeInterval = TimeInterval.fromMicrosecondTimestamp(lastVisit.date)
                
                if let groupPlacedAfterItem = (viewModel.groupedSites.itemsForSection(groupSection.rawValue - 1)).first(where : { site in
                    guard let lastVisit = site.latestVisit else { return false }
                    return groupTimeInterval > TimeInterval.fromMicrosecondTimestamp(lastVisit.date)
                }) {
                    // In this case, we have Site items AND a group in the section.
                    snapshot.insertItems([grouping], beforeItem: groupPlacedAfterItem)
                } else {
                    // Looks like this group's the only item in the section
                    snapshot.appendItems([grouping], toSection: groupSection)
                }
            }
        }
        
        // Insert your fixed first section and data
        if let historySection = snapshot.sectionIdentifiers.first, historySection != .additionalHistoryActions {
            snapshot.insertSections([.additionalHistoryActions], beforeSection: historySection)
        } else {
            snapshot.appendSections([.additionalHistoryActions])
        }
        snapshot.appendItems(viewModel.historyActionables, toSection: .additionalHistoryActions)
        
        diffableDatasource?.apply(snapshot, animatingDifferences: animatingDifferences, completion: nil)
    }
    
    // MARK: - Swipe Action helpers
    
    func removeHistoryItem(at indexPath: IndexPath) {
        guard let historyItem = diffableDatasource?.itemIdentifier(for: indexPath) else { return }
        
        viewModel.removeHistoryItems(item: historyItem, at: indexPath.section)
        
        updateEmptyPanelState()
        
        if let historyActionableCell = clearHistoryCell {
            setTappableStateAndStyle(with: HistoryActionablesModel.activeActionables.first, on: historyActionableCell)
        }
        
        applySnapshot(animatingDifferences: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // For UX consistency, every cell in history panel SHOULD have a trailing action.
        let deleteAction = UIContextualAction(style: .destructive, title: .HistoryPanelDelete) { [weak self] (_, _, completion) in
            guard let self = self else {
                Logger.browserLogger.error("History Panel - self became nil inside SwipeActionConfiguration!")
                completion(false)
                return
            }
            
            self.removeHistoryItem(at: indexPath)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // MARK: - Empty State helpers
    
    private func updateEmptyPanelState() {
        if viewModel.groupedSites.isEmpty, emptyStateOverlayView.superview == nil {
            tableView.tableFooterView = emptyStateOverlayView
        } else {
            tableView.alwaysBounceVertical = true
            tableView.tableFooterView = nil
        }
    }

    private func createEmptyStateOverlayView() -> UIView {
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

    // MARK: - Themeable
    
    func applyTheme() {
        emptyStateOverlayView.removeFromSuperview()
        emptyStateOverlayView = createEmptyStateOverlayView()
        updateEmptyPanelState()
        
        tableView.backgroundColor = UIColor.theme.homePanel.panelBackground
        tableView.separatorColor = UIColor.theme.tableView.separator
        
        tableView.reloadData()
    }
    
}

// MARK: - UITableViewDelegate related helpers

extension HistoryPanelV2: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let item = diffableDatasource?.itemIdentifier(for: indexPath) else { return }
        
        if let site = item as? Site {
            handleSiteItemTapped(site: site)
        }
        
        if let historyActionable = item as? HistoryActionablesModel {
            handleHistoryActionableTapped(historyActionable: historyActionable)
        }
        
        if let asGroupItem = item as? ASGroup<Site> {
            handleASGroupItemTapped(asGroupItem: asGroupItem)
        }
    }
    
    private func handleSiteItemTapped(site: Site) {
        guard let url = URL(string: site.url) else {
            browserLog.error("Couldn't navigate to site: \(site.url)")
            return
        }
        
        libraryPanelDelegate?.libraryPanel(didSelectURL: url, visitType: .typed)
        
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .selectedHistoryItem,
                                     value: .historyPanelNonGroupItem,
                                     extras: nil)
    }
    
    private func handleHistoryActionableTapped(historyActionable: HistoryActionablesModel) {
        switch historyActionable.itemIdentity {
        case .clearHistory:
            showClearRecentHistory()
        case .recentlyClosed:
            navigateToRecentlyClosed()
        default: break
        }
    }
    
    private func handleASGroupItemTapped(asGroupItem: ASGroup<Site>) {
        let asGroupListViewModel = GroupedHistoryItemsViewModel(asGroup: asGroupItem)
        let asGroupListVC = GroupedHistoryItemsViewController(profile: profile, viewModel: asGroupListViewModel)
        asGroupListVC.libraryPanelDelegate = libraryPanelDelegate
        asGroupListVC.title = asGroupItem.displayTitle
        
        navigationController?.pushViewController(asGroupListVC, animated: true)
    }
    
}

/// Refresh controls helpers
extension HistoryPanelV2 {
    private func handleRefreshControl() {
        if profile.hasSyncableAccount() && refreshControl == nil {
            let control = UIRefreshControl()
            control.addTarget(self, action: #selector(onRefreshPulled), for: .valueChanged)
            refreshControl = control
            tableView.refreshControl = control
        } else if !profile.hasSyncableAccount() && refreshControl != nil {
            tableView.refreshControl = nil
            refreshControl = nil
        }
    }

    private func endRefreshing() {
        // Always end refreshing, even if we failed!
        refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        handleRefreshControl()
    }
    
    private func resyncHistory() {
        profile.syncManager.syncHistory().uponQueue(.main) { syncResult in
            self.endRefreshing()

            if syncResult.isSuccess {
                self.viewModel.reloadData()
                self.applySnapshot(animatingDifferences: true)
            }
            
        }
        
    }
    
}

/// User actions helpers
extension HistoryPanelV2 {
    // MARK: - User Interactions
    
    /// When long pressed, a menu appears giving the choice of pinning as a Top Site.
    func pinToTopSites(_ site: Site) {
        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            if result.isSuccess {
                SimpleToast().showAlertWithText(.AppMenu.AddPinToShortcutsConfirmMessage, bottomContainer: self.view)
            }
        }
    }

    private func navigateToRecentlyClosed() {
        guard hasRecentlyClosed else { return }

        let nextController = RecentlyClosedTabsPanel(profile: profile)
        nextController.title = .RecentlyClosedTabsPanelTitle
        nextController.libraryPanelDelegate = libraryPanelDelegate
        nextController.recentlyClosedTabsDelegate = BrowserViewController.foregroundBVC()
        refreshControl?.endRefreshing()
        navigationController?.pushViewController(nextController, animated: true)
    }
    
    @objc private func onLongPressGestureRecognized(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        
        if indexPath.section != HistoryPanelSections.additionalHistoryActions.rawValue {
            presentContextMenu(for: indexPath)
        }
    }

    @objc private func onRefreshPulled() {
        refreshControl?.beginRefreshing()
        resyncHistory()
    }
    
}

// MARK: - TableView's Header & Footer view helpers
extension HistoryPanelV2 {
        
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? SiteTableViewHeader, let actualSection = viewModel.visibleSections[safe: section - 1] {
            
            header.textLabel?.textColor = UIColor.theme.tableView.headerTextDark
            header.contentView.backgroundColor = UIColor.theme.tableView.selectedBackground
            header.textLabel?.text = actualSection.title // At worst, we have a header with no text.

            // let historySectionsWithGroups
            let _ = viewModel.searchTermGroups.map { group in
                viewModel.groupBelongsToSection(asGroup: group)
            }
            
            // NOTE: Uncomment this when we support showing the Show all button and its functionality in a later time.
            // let visibleSectionsWithGroups = viewModel.visibleSections.filter { historySectionsWithGroups.contains($0) }
            // header.headerActionButton.isHidden = !visibleSectionsWithGroups.contains(actualSection)
        }
        
    }

    // viewForHeaderInSection REQUIRES implementing heightForHeaderInSection
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // First section is for recently closed and its header has no view.
        guard HistoryPanelSections(rawValue: section) != .additionalHistoryActions else {
            return nil
        }

        return tableView.dequeueReusableHeaderFooterView(withIdentifier: SiteTableViewHeader.cellIdentifier)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // First section is for recently closed and its header has no height.
        guard HistoryPanelSections(rawValue: section) != .additionalHistoryActions else {
            return 0
        }

        return HistoryPanelUX.HeaderHeight
    }
    
}

extension HistoryPanelV2: UITableViewDataSourcePrefetching {
    
    // Happens WAY too often. We should consider fetching the next set when the user HITS the bottom instead.
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard !viewModel.isFetchInProgress, indexPaths.contains(where: shouldLoadRow) else { return }

        viewModel.reloadData()
        applySnapshot(animatingDifferences: false)
    }

    func shouldLoadRow(for indexPath: IndexPath) -> Bool {
        guard HistoryPanelSections(rawValue: indexPath.section) != .additionalHistoryActions else { return false }

        return indexPath.row >= viewModel.groupedSites.numberOfItemsForSection(indexPath.section - 1) - historyPanelPrefetchOffset
    }
    
}
