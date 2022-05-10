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
    static let HeaderHeight = CGFloat(40)
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
class HistoryPanelWithGroups: UIViewController, LibraryPanel, Loggable, NotificationThemeable {

    // MARK: - Properties

    typealias HistoryPanelSections = HistoryPanelViewModel.Sections
    typealias a11yIds = AccessibilityIdentifiers.LibraryPanels.HistoryPanel

    var libraryPanelDelegate: LibraryPanelDelegate?
    var recentlyClosedTabsDelegate: RecentlyClosedPanelDelegate?

    let profile: Profile
    let viewModel: HistoryPanelViewModel
    private let clearHistoryHelper: ClearHistoryHelper
    var keyboardState: KeyboardState?
    private lazy var siteImageHelper = SiteImageHelper(profile: profile)
    var chevronImage = UIImage(named: ImageIdentifiers.menuChevron)

    // We'll be able to prefetch more often the higher this number is. But remember, it's expensive!
    private let historyPanelPrefetchOffset = 8

    var diffableDatasource: UITableViewDiffableDataSource<HistoryPanelSections, AnyHashable>?
    private var hasRecentlyClosed: Bool { profile.recentlyClosedTabs.tabs.count > 0 }

    // UI
    var bottomStackView: BaseAlphaStackView = .build { _ in }

    lazy var searchbar: UISearchBar = .build { searchbar in
        searchbar.searchTextField.placeholder = self.viewModel.searchHistoryPlaceholder
        searchbar.returnKeyType = .go
        searchbar.delegate = self
    }

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
    lazy var welcomeLabel: UILabel = .build { label in
        label.text = self.viewModel.emptyStateText
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        label.textColor = UIColor.theme.homePanel.welcomeScreenText
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
    }
    var refreshControl: UIRefreshControl?
    var recentlyClosedCell: OneLineTableViewCell?

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

        KeyboardHelper.defaultHelper.addDelegate(self)
        viewModel.historyPanelNotifications.forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: $0, object: nil)
        }

        handleRefreshControl()
        setupLayout()
        configureDatasource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bottomStackView.isHidden = !viewModel.isSearchInProgress
        fetchDataAndUpdateLayout()
    }

    // MARK: - Private helpers

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(bottomStackView)
        bottomStackView.addArrangedSubview(searchbar)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            bottomStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    // Reload viewModel data and update layout
    private func fetchDataAndUpdateLayout(animating: Bool = false) {
        // Avoid refresing if search is in progress
        guard !viewModel.isSearchInProgress else { return }

        viewModel.reloadData() { [weak self] success in
            DispatchQueue.main.async {
                self?.applySnapshot(animatingDifferences: animating)
            }
        }
    }

    func updateLayoutForKeyboard() {
        guard let keyboardHeight = keyboardState?.intersectionHeightForView(view),
              keyboardHeight > 0 else {
            bottomStackView.removeKeyboardSpacer()
            return
        }

        let spacerHeight = keyboardHeight - UIConstants.BottomToolbarHeight
        bottomStackView.addKeyboardSpacer(spacerHeight: spacerHeight)
        bottomStackView.isHidden = false
    }

    // Use to enable/disable the additional history action rows. `HistoryActionablesModel`
    private func setTappableStateAndStyle(with item: AnyHashable, on cell: OneLineTableViewCell) {
        var isEnabled = false

        if let actionableItem = item as? HistoryActionablesModel {
            switch actionableItem.itemIdentity {
            case .clearHistory:
                isEnabled = !viewModel.groupedSites.isEmpty
            case .recentlyClosed:
                isEnabled = hasRecentlyClosed
                recentlyClosedCell = cell
            default: break
            }
        }

        // Set interaction behavior and style
        cell.titleLabel.alpha = isEnabled ? 1.0 : 0.5
        cell.leftImageView.alpha = isEnabled ? 1.0 : 0.5
        cell.selectionStyle = isEnabled ? .default : .none
        cell.isUserInteractionEnabled = isEnabled
    }

    // MARK: - Datasource helpers

    func siteAt(indexPath: IndexPath) -> Site? {
        guard let siteItem = diffableDatasource?.itemIdentifier(for: indexPath) as? Site else { return nil }

        return siteItem
    }

    private func showClearRecentHistory() {
        clearHistoryHelper.showClearRecentHistory(onViewController: self, didComplete: { [weak self] date in
            // Delete groupings that belong to THAT section.
            if let date = date {
                self?.viewModel.deleteGroupsForDates(date: date)
            } else {
                // Otherwise delete ALL groups, since we're deleting all history anyways.
                self?.viewModel.removeAllData()
            }

            DispatchQueue.main.async {
                self?.applySnapshot()
                self?.tableView.reloadData()
                self?.refreshRecentlyClosedCell()
            }
        })
    }

    private func refreshRecentlyClosedCell() {
        guard let cell = recentlyClosedCell else { return }

        self.setTappableStateAndStyle(
            with: HistoryActionablesModel.activeActionables.first(where: { $0.itemIdentity == .recentlyClosed }),
            on: cell)
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .PrivateDataClearedHistory:
            viewModel.removeAllData()
            fetchDataAndUpdateLayout(animating: true)

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
                fetchDataAndUpdateLayout(animating: true)
            }
        case .OpenClearRecentHistory:
            if viewModel.isSearchInProgress {
                exitSearchState()
            }

            showClearRecentHistory()
        default:
            // no need to do anything at all
            browserLog.error("Error: Received unexpected notification \(notification.name)")
            break
        }
    }

    // MARK: - UITableViewDataSource

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
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.accessoryUsageReuseIdentifier, for: indexPath) as? TwoLineImageOverlayCell else {
                    self.browserLog.error("History Panel - cannot create TwoLineImageOverlayCell for site!")
                    return nil
                }

                let siteCell = self.configureSiteCell(site, cell)
                return siteCell
            }

            if let searchTermGroup = item as? ASGroup<Site> {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.cellIdentifier, for: indexPath) as? TwoLineImageOverlayCell else {
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

    private func configureHistoryActionableCell(_ historyActionable: HistoryActionablesModel, _ cell: OneLineTableViewCell) -> OneLineTableViewCell {
        cell.titleLabel.text = historyActionable.itemTitle
        cell.leftImageView.image = historyActionable.itemImage
        cell.leftImageView.tintColor = .theme.browser.tint
        cell.leftImageView.backgroundColor = .theme.homePanel.historyHeaderIconsBackground
        cell.accessibilityIdentifier = historyActionable.itemA11yId
        setTappableStateAndStyle(with: historyActionable, on: cell)

        return cell
    }

    private func configureSiteCell(_ site: Site, _ cell: TwoLineImageOverlayCell) -> TwoLineImageOverlayCell {
        cell.titleLabel.text = site.title
        cell.titleLabel.isHidden = site.title.isEmpty
        cell.descriptionLabel.text = site.url
        cell.descriptionLabel.isHidden = false
        cell.leftImageView.layer.borderColor = HistoryPanelUX.IconBorderColor.cgColor
        cell.leftImageView.layer.borderWidth = HistoryPanelUX.IconBorderWidth
        cell.accessoryView = nil
        getFavIcon(for: site) { [weak cell] image in
            cell?.leftImageView.image = image
            cell?.leftImageView.backgroundColor = UIColor.theme.general.faviconBackground
        }

        return cell
    }

    private func getFavIcon(for site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .favicon, shouldFallback: false) { image in
            completion(image)
        }
    }

    private func configureASGroupCell(_ asGroup: ASGroup<Site>, _ cell: TwoLineImageOverlayCell) -> TwoLineImageOverlayCell {
        if let groupCount = asGroup.description {
            cell.descriptionLabel.text = groupCount
        }

        cell.titleLabel.text = asGroup.displayTitle
        let imageView = UIImageView(image: chevronImage)
        cell.accessoryView = imageView
        cell.leftImageView.image = UIImage(named: ImageIdentifiers.stackedTabsIcon)?.withTintColor(ThemeManager.shared.currentTheme.colours.iconSecondary)
        cell.leftImageView.backgroundColor = .theme.homePanel.historyHeaderIconsBackground

        return cell
    }

    /// The data source gets populated here for your choice of section.
    func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<HistoryPanelSections, AnyHashable>()

        snapshot.appendSections(viewModel.visibleSections)

        snapshot.sectionIdentifiers.forEach { section in
            if !viewModel.hiddenSections.contains(where: { $0 == section }) {
                snapshot.appendItems(viewModel.groupedSites.itemsForSection(section.rawValue - 1), toSection: section)
            }
        }

        // Insert the ASGroup at the correct spot!
        viewModel.searchTermGroups.forEach { grouping in
            if let groupSection = viewModel.shouldAddGroupToSections(group: grouping) {
                guard let individualItem = grouping.groupedItems.last, let lastVisit = individualItem.latestVisit else { return }

                let groupTimeInterval = TimeInterval.fromMicrosecondTimestamp(lastVisit.date)

                if let groupPlacedAfterItem = (viewModel.groupedSites.itemsForSection(groupSection.rawValue - 1)).first(where: { site in
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
        updateEmptyPanelState()
    }

    // MARK: - Swipe Action helpers

    func removeHistoryItem(at indexPath: IndexPath) {
        guard let historyItem = diffableDatasource?.itemIdentifier(for: indexPath) else { return }

        viewModel.removeHistoryItems(item: [historyItem], at: indexPath.section)

        applySnapshot(animatingDifferences: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        // Adding support to delete item during search in next ticket
        guard !viewModel.isSearchInProgress else { return nil }

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

    func updateEmptyPanelState() {
        if viewModel.shouldShowEmptyState(searchText: searchbar.text ?? "") {
            welcomeLabel.text = viewModel.emptyStateText
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
        let bgColor: UIView = .build { view in
            view.backgroundColor = UIColor.theme.homePanel.panelBackground
        }
        overlayView.addSubview(bgColor)

        NSLayoutConstraint.activate([
            bgColor.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height),
            bgColor.widthAnchor.constraint(equalTo: overlayView.widthAnchor)
        ])

        overlayView.addSubview(welcomeLabel)

        let welcomeLabelPriority = UILayoutPriority(100)
        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor,
                                                  constant: LibraryPanelUX.EmptyTabContentOffset).priority(welcomeLabelPriority),
            welcomeLabel.topAnchor.constraint(greaterThanOrEqualTo: overlayView.topAnchor,
                                              constant: 50),
            welcomeLabel.widthAnchor.constraint(equalToConstant: CGFloat(HistoryPanelUX.WelcomeScreenItemWidth))
        ])
        return overlayView
    }

    // MARK: - Themeable

    func applyTheme() {
        updateEmptyPanelState()

        tableView.backgroundColor = UIColor.theme.homePanel.panelBackground
        searchbar.backgroundColor = UIColor.theme.textField.backgroundInOverlay
        let tintColor = UIColor.theme.textField.textAndTint
        let searchBarImage = UIImage(named: ImageIdentifiers.libraryPanelHistory)?.withRenderingMode(.alwaysTemplate).tinted(withColor: tintColor)
        searchbar.setImage(searchBarImage, for: .search, state: .normal)
        searchbar.tintColor = UIColor.theme.textField.textAndTint

        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate related helpers

extension HistoryPanelWithGroups: UITableViewDelegate {

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

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if searchbar.isFirstResponder {
            searchbar.resignFirstResponder()
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
        exitSearchState()

        let asGroupListViewModel = SearchGroupedItemsViewModel(asGroup: asGroupItem, presenter: .historyPanel)
        let asGroupListVC = SearchGroupedItemsViewController(viewModel: asGroupListViewModel, profile: profile)
        asGroupListVC.libraryPanelDelegate = libraryPanelDelegate
        asGroupListVC.title = asGroupItem.displayTitle

        TelemetryWrapper.recordEvent(category: .action, method: .navigate, object: .navigateToGroupHistory, value: nil, extras: nil)

        navigationController?.pushViewController(asGroupListVC, animated: true)
    }

    @objc private func sectionHeaderTapped(sender: UIGestureRecognizer) {
        guard let sectionNumber = sender.view?.tag else {
            return
        }

        viewModel.collapseSection(sectionIndex: sectionNumber)
        applySnapshot()
        // Needed to refresh the header state
        tableView.reloadData()
    }

    // MARK: - TableView's Header & Footer view
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? SiteTableViewHeader, let actualSection = viewModel.visibleSections[safe: section - 1] {

            header.textLabel?.textColor = UIColor.theme.tableView.headerTextDark
            header.contentView.backgroundColor = UIColor.theme.tableView.selectedBackground
            header.textLabel?.text = actualSection.title // At worst, we have a header with no text.
            header.collapsibleImageView.isHidden = false
            let isCollapsed = viewModel.isSectionCollapsed(sectionIndex: section - 1)
            header.collapsibleState = isCollapsed ? ExpandButtonState.right : ExpandButtonState.down

            // Configure tap to collapse/expand section
            header.tag = section
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sectionHeaderTapped(sender:)))
            header.addGestureRecognizer(tapGesture)

            // let historySectionsWithGroups
            let _ = viewModel.searchTermGroups.map { group in
                viewModel.groupBelongsToSection(asGroup: group)
            }
        }

    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // First section is for recently closed and its header has no view.
        guard HistoryPanelSections(rawValue: section) != .additionalHistoryActions else {
            return nil
        }

        return tableView.dequeueReusableHeaderFooterView(withIdentifier: SiteTableViewHeader.cellIdentifier)
    }

    // viewForHeaderInSection REQUIRES implementing heightForHeaderInSection
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // First section is for recently closed and its header has no height.
        guard HistoryPanelSections(rawValue: section) != .additionalHistoryActions else {
            return 0
        }

        return HistoryPanelUX.HeaderHeight
    }
}

/// Refresh controls helpers
extension HistoryPanelWithGroups {
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
                self.fetchDataAndUpdateLayout(animating: true)
            }
        }
    }
}

/// User actions helpers
extension HistoryPanelWithGroups {
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

extension HistoryPanelWithGroups: UITableViewDataSourcePrefetching {

    // Happens WAY too often. We should consider fetching the next set when the user HITS the bottom instead.
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard !viewModel.isFetchInProgress, indexPaths.contains(where: shouldLoadRow) else { return }

        fetchDataAndUpdateLayout(animating: false)
    }

    func shouldLoadRow(for indexPath: IndexPath) -> Bool {
        guard HistoryPanelSections(rawValue: indexPath.section) != .additionalHistoryActions else { return false }

        return indexPath.row >= viewModel.groupedSites.numberOfItemsForSection(indexPath.section - 1) - historyPanelPrefetchOffset
    }
}
