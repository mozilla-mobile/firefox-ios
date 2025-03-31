// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Storage
import WebKit
import Common
import SiteImageView

@objcMembers
class HistoryPanel: UIViewController,
                    LibraryPanel,
                    LibraryPanelContextMenu,
                    Themeable {
    struct UX {
        static let WelcomeScreenItemWidth = 170
        static let IconSize = 23
        static let IconBorderWidth: CGFloat = 0.5
        static let EmptyTabContentOffset: CGFloat = -180
    }

    // MARK: - Properties
    typealias HistoryPanelSections = HistoryPanelViewModel.Sections
    typealias a11yIds = AccessibilityIdentifiers.LibraryPanels.HistoryPanel

    weak var libraryPanelDelegate: LibraryPanelDelegate?
    weak var historyCoordinatorDelegate: HistoryCoordinatorDelegate?
    var recentlyClosedTabsDelegate: RecentlyClosedPanelDelegate?
    var state: LibraryPanelMainState

    let profile: Profile
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    let viewModel: HistoryPanelViewModel
    private let clearHistoryHelper: ClearHistorySheetProvider
    var keyboardState: KeyboardState?
    var chevronImage = UIImage(named: StandardImageIdentifiers.Large.chevronRight)?.withRenderingMode(.alwaysTemplate)
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    var logger: Logger

    // We'll be able to prefetch more often the higher this number is. But remember, it's expensive!
    private let historyPanelPrefetchOffset = 8
    var diffableDataSource: UITableViewDiffableDataSource<HistoryPanelSections, AnyHashable>?

    var shouldShowToolBar: Bool {
        return state == .history(state: .mainView) || state == .history(state: .search)
    }

    var shouldShowSearch: Bool {
        return state == .history(state: .mainView) || state == .history(state: .search)
    }

    var bottomToolbarItems: [UIBarButtonItem] {
        guard case .history = state else { return [UIBarButtonItem]() }

        return toolbarButtonItems
    }

    private var toolbarButtonItems: [UIBarButtonItem] {
        guard shouldShowToolBar else {
            return [UIBarButtonItem]()
        }

        guard shouldShowSearch else {
            return [bottomDeleteButton, flexibleSpace]
        }

        return [bottomDeleteButton, flexibleSpace, bottomSearchButton, flexibleSpace]
    }

    // UI
    private lazy var bottomSearchButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.search),
                                     style: .plain,
                                     target: self,
                                     action: #selector(bottomSearchButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomSearchButton
        return button
    }()

    private lazy var bottomDeleteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.delete),
                                     style: .plain,
                                     target: self,
                                     action: #selector(bottomDeleteButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomDeleteButton
        return button
    }()

    var bottomStackView: BaseAlphaStackView = .build { _ in }

    lazy var searchbar: UISearchBar = .build { searchbar in
        searchbar.searchTextField.placeholder = self.viewModel.searchHistoryPlaceholder
        searchbar.returnKeyType = .go
        searchbar.delegate = self
        searchbar.showsCancelButton = true
    }

    private lazy var tableView: UITableView = .build { [weak self] tableView in
        guard let self = self else { return }
        tableView.dataSource = self.diffableDataSource
        tableView.addGestureRecognizer(self.longPressRecognizer)
        tableView.accessibilityIdentifier = a11yIds.tableView
        tableView.prefetchDataSource = self
        tableView.delegate = self
        tableView.register(TwoLineImageOverlayCell.self,
                           forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier)
        tableView.register(TwoLineImageOverlayCell.self,
                           forCellReuseIdentifier: TwoLineImageOverlayCell.accessoryUsageReuseIdentifier)
        tableView.register(OneLineTableViewCell.self,
                           forCellReuseIdentifier: OneLineTableViewCell.cellIdentifier)
        tableView.register(SiteTableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: SiteTableViewHeader.cellIdentifier)

        tableView.sectionHeaderTopPadding = 0
    }

    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGestureRecognized))
    }()

    lazy var emptyStateOverlayView: UIView = createEmptyStateOverlayView()
    private weak var emptyStateOverlayBackgroundColorView: UIView?
    lazy var welcomeLabel: UILabel = .build { label in
        label.text = self.viewModel.emptyStateText
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
    }
    var refreshControl: UIRefreshControl?
    var recentlyClosedCell: OneLineTableViewCell?

    // MARK: - Inits

    init(profile: Profile,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared) {
        self.clearHistoryHelper = ClearHistorySheetProvider(profile: profile)
        self.viewModel = HistoryPanelViewModel(profile: profile)
        self.profile = profile
        self.state = .history(state: .mainView)
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        KeyboardHelper.defaultHelper.addDelegate(self)
        viewModel.historyPanelNotifications.forEach {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleNotifications),
                name: $0,
                object: nil
            )
        }

        listenForThemeChange(view)
        handleRefreshControl()
        setupLayout()
        configureDataSource()
        applyTheme()
        // Update theme of already existing view
        bottomStackView.applyTheme(theme: currentTheme())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.shouldResetHistory = true
        bottomStackView.isHidden = !viewModel.isSearchInProgress
        if viewModel.shouldResetHistory {
            fetchDataAndUpdateLayout()
        }
        DispatchQueue.main.async {
            self.refreshRecentlyClosedCell()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .historyPanelOpened)
    }

    // MARK: - Private helpers

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

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
        // Avoid refreshing if search is in progress
        guard !viewModel.isSearchInProgress else { return }

        viewModel.reloadData { [weak self] success in
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

    func shouldDismissOnDone() -> Bool {
        guard state != .history(state: .search) else { return false }

        return true
    }

    // Use to enable/disable the additional history action rows. `HistoryActionablesModel`
    private func setTappableStateAndStyle(with item: AnyHashable, on cell: OneLineTableViewCell) {
        var isEnabled = false

        if let actionableItem = item as? HistoryActionablesModel {
            switch actionableItem.itemIdentity {
            case .clearHistory:
                isEnabled = !viewModel.dateGroupedSites.isEmpty
            case .recentlyClosed:
                isEnabled = viewModel.hasRecentlyClosed
                recentlyClosedCell = cell
            default: break
            }
        }

        // Set interaction behavior and style
        cell.configureTapState(isEnabled: isEnabled)
        cell.selectionStyle = isEnabled ? .default : .none
        cell.isUserInteractionEnabled = isEnabled
    }

    // MARK: - Datasource helpers

    func siteAt(indexPath: IndexPath) -> Site? {
        guard let siteItem = diffableDataSource?.itemIdentifier(for: indexPath) as? Site else { return nil }

        return siteItem
    }

    func showClearRecentHistory() {
        clearHistoryHelper.showClearRecentHistory(onViewController: self) { [weak self] dateOption in
            // Delete groupings that belong to THAT section.
            switch dateOption {
            case .lastHour, .lastTwentyFourHours, .lastSevenDays, .lastFourWeeks:
                self?.viewModel.deleteGroupsFor(dateOption: dateOption)
            default:
                self?.viewModel.removeAllData()
            }

            DispatchQueue.main.async {
                self?.applySnapshot()
                self?.tableView.reloadData()
                self?.refreshRecentlyClosedCell()
            }
        }
    }

    private func refreshRecentlyClosedCell() {
        guard let cell = recentlyClosedCell else { return }

        let item: HistoryActionablesModel? =
        HistoryActionablesModel.activeActionables
            .first(where: { $0.itemIdentity == .recentlyClosed })
            .map {
                var item = $0
                item.configureImage(for: windowUUID)
                return item
            }
        self.setTappableStateAndStyle(
            with: item,
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
            break
        case .OpenRecentlyClosedTabs:
            historyCoordinatorDelegate?.showRecentlyClosedTab()
            applySnapshot(animatingDifferences: true)
            break
        default:
            // no need to do anything at all
            break
        }
    }

    // MARK: - UITableViewDataSource

    /// Handles dequeuing the appropriate type of cell when needed.
    private func configureDataSource() {
        diffableDataSource = UITableViewDiffableDataSource<
            HistoryPanelSections,
            AnyHashable
        >(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self else { return nil }

            if var historyActionable = item as? HistoryActionablesModel {
                historyActionable.configureImage(for: windowUUID)
                return getHistoryActionableCell(historyActionable: historyActionable, indexPath: indexPath)
            }

            if let site = item as? Site {
                return getSiteCell(site: site, indexPath: indexPath)
            }

            // This should never happen! You will have an empty row!
            return UITableViewCell()
        }
    }

    private func getHistoryActionableCell(historyActionable: HistoryActionablesModel,
                                          indexPath: IndexPath) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OneLineTableViewCell.cellIdentifier,
            for: indexPath
        ) as? OneLineTableViewCell
        else {
            logger.log("History Panel - cannot create OneLineTableViewCell for historyActionable",
                       level: .debug,
                       category: .library)
            return nil
        }

        let actionableCell = configureHistoryActionableCell(historyActionable, cell)
        return actionableCell
    }

    private func configureHistoryActionableCell(
        _ historyActionable: HistoryActionablesModel,
        _ cell: OneLineTableViewCell
    ) -> OneLineTableViewCell {
        cell.leftImageView.tintColor = currentTheme().colors.textPrimary
        cell.leftImageView.backgroundColor = .clear

        let viewModel = OneLineTableViewCellViewModel(title: historyActionable.itemTitle,
                                                      leftImageView: historyActionable.itemImage,
                                                      accessoryView: nil,
                                                      accessoryType: .none,
                                                      editingAccessoryView: nil)
        cell.configure(viewModel: viewModel)
        cell.accessibilityIdentifier = historyActionable.itemA11yId
        setTappableStateAndStyle(with: historyActionable, on: cell)
        cell.applyTheme(theme: currentTheme())
        return cell
    }

    private func getSiteCell(site: Site, indexPath: IndexPath) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TwoLineImageOverlayCell.accessoryUsageReuseIdentifier,
            for: indexPath
        ) as? TwoLineImageOverlayCell else {
            logger.log("History Panel - cannot create TwoLineImageOverlayCell for site",
                       level: .debug,
                       category: .library)
            return nil
        }

        let siteCell = configureSiteCell(site, cell)
        return siteCell
    }

    private func configureSiteCell(
        _ site: Site,
        _ cell: TwoLineImageOverlayCell
    ) -> TwoLineImageOverlayCell {
        cell.titleLabel.text = site.title
        cell.titleLabel.isHidden = site.title.isEmpty
        cell.descriptionLabel.text = site.url
        cell.descriptionLabel.isHidden = false
        cell.leftImageView.layer.borderColor = currentTheme().colors.borderPrimary.cgColor
        cell.leftImageView.layer.borderWidth = UX.IconBorderWidth
        cell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: site.url))
        cell.accessoryView = nil
        cell.applyTheme(theme: currentTheme())
        return cell
    }

    /// The data source gets populated here for your choice of section.
    func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<HistoryPanelSections, AnyHashable>()

        snapshot.appendSections(viewModel.visibleSections)

        snapshot.sectionIdentifiers.forEach { section in
            if !viewModel.hiddenSections.contains(where: { $0 == section }) {
                let sectionData = viewModel.dateGroupedSites.itemsForSection(section.rawValue - 1)
                let sectionDataUniqued = sectionData.uniqued()

                // FXIOS-10996 Temporary check for duplicates to help diagnose history panel crashes
                if sectionData.count > sectionDataUniqued.count {
                    let numberOfDuplicates = sectionData.count - sectionDataUniqued.count
                    logger.log(
                        "Duplicates found in HistoryPanel applySnapshot method in section \(section): \(numberOfDuplicates)",
                        level: .fatal,
                        category: .library
                    )

                    // If you crash here, please record your steps in ticket FXIOS-10996. Diagnose if possible as you
                    // have stumbled upon one of our rare Sentry crashes that is probably dependent on your unique
                    // browsing history state.
                    assertionFailure("FXIOS-10996 We should never have duplicates! Log how you made this crash happen.")
                }

                snapshot.appendItems(
                    sectionDataUniqued, // FXIOS-10996 Force unique while we investigate history panel crashes
                    toSection: section
                )
            }
        }

        // Insert your fixed first section and data (e.g. "Recently Closed" cell)
        if let historySection = snapshot.sectionIdentifiers.first, historySection != .additionalHistoryActions {
            snapshot.insertSections([.additionalHistoryActions], beforeSection: historySection)
        } else {
            snapshot.appendSections([.additionalHistoryActions])
        }
        snapshot.appendItems(viewModel.historyActionables, toSection: .additionalHistoryActions)

        diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences, completion: nil)
        updateEmptyPanelState()
    }

    // MARK: - Swipe Action helpers

    func removeHistoryItem(at indexPath: IndexPath) {
        guard let historyItem = diffableDataSource?.itemIdentifier(for: indexPath) else { return }

        viewModel.removeHistoryItems(item: [historyItem], at: indexPath.section)

        if viewModel.isSearchInProgress {
            applySearchSnapshot()
        } else {
            applySnapshot(animatingDifferences: true)
        }

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .swipe,
                                     object: .historySingleItemRemoved)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        if let item = diffableDataSource?.itemIdentifier(for: indexPath),
           item as? HistoryActionablesModel != nil {
            return nil
        }

        // For UX consistency, every cell in history panel SHOULD have a trailing action.
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: .HistoryPanelDelete
        ) { [weak self] (_, _, completion) in
            guard let self = self else {
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
            applyEmptyStateViewTheme(currentTheme())
            welcomeLabel.text = viewModel.emptyStateText
            tableView.tableFooterView = emptyStateOverlayView
        } else {
            tableView.alwaysBounceVertical = true
            tableView.tableFooterView = nil
        }
    }

    private func applyEmptyStateViewTheme(_ theme: Theme) {
        welcomeLabel.textColor = theme.colors.textSecondary
        emptyStateOverlayBackgroundColorView?.backgroundColor = theme.colors.layer1
    }

    private func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()

        // overlayView becomes the footer view, and for unknown reason, setting the bgcolor is ignored.
        // Create an explicit view for setting the color.
        let bgColor: UIView = .build { view in
            view.backgroundColor = self.currentTheme().colors.layer1
        }
        overlayView.addSubview(bgColor)
        emptyStateOverlayBackgroundColorView = bgColor

        NSLayoutConstraint.activate([
            bgColor.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height),
            bgColor.widthAnchor.constraint(equalTo: overlayView.widthAnchor)
        ])

        overlayView.addSubview(welcomeLabel)

        let welcomeLabelPriority = UILayoutPriority(100)
        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor,
                                                  constant: UX.EmptyTabContentOffset).priority(welcomeLabelPriority),
            welcomeLabel.topAnchor.constraint(greaterThanOrEqualTo: overlayView.topAnchor,
                                              constant: 50),
            welcomeLabel.widthAnchor.constraint(equalToConstant: CGFloat(UX.WelcomeScreenItemWidth))
        ])
        return overlayView
    }

    // MARK: - Themeable

    func applyTheme() {
        updateEmptyPanelState()

        let theme = currentTheme()
        tableView.backgroundColor = theme.colors.layer1
        emptyStateOverlayView.backgroundColor = theme.colors.layer1

        searchbar.backgroundColor = theme.colors.layer3
        let tintColor = theme.colors.textPrimary
        let searchBarImage = UIImage(named: StandardImageIdentifiers.Large.history)?
            .withRenderingMode(.alwaysTemplate)
            .tinted(withColor: tintColor)
        searchbar.setImage(searchBarImage, for: .search, state: .normal)
        searchbar.tintColor = theme.colors.textPrimary
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
        ]
        bottomSearchButton.tintColor = theme.colors.iconPrimary
        bottomDeleteButton.tintColor = theme.colors.iconPrimary
        applyEmptyStateViewTheme(theme)

        tableView.reloadData()
    }

    // MARK: Telemetry

    func sendOpenedHistoryItemTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .openedHistoryItem)
    }

    func sendSelectedHistoryItemCount() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .selectedHistoryItem,
                                     value: .historyPanelNonGroupItem)
    }

    // MARK: - LibraryPanelContextMenu

    func presentContextMenu(
        for site: Site,
        with indexPath: IndexPath,
        completionHandler: @escaping () -> PhotonActionSheet?
    ) {
        guard let contextMenu = completionHandler() else { return }

        present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        return siteAt(indexPath: indexPath)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        guard var actions = getDefaultContextMenuActions(
            for: site,
            libraryPanelDelegate: libraryPanelDelegate
        ) else { return nil }

        let removeAction = SingleActionViewModel(title: .DeleteFromHistoryContextMenuTitle,
                                                 iconString: StandardImageIdentifiers.Large.delete,
                                                 tapHandler: { _ in
            self.removeHistoryItem(at: indexPath)
        })

        let pinTopSite = SingleActionViewModel(title: .AddToShortcutsActionTitle,
                                               iconString: StandardImageIdentifiers.Large.pin,
                                               tapHandler: { _ in
            self.pinToTopSites(site)
        })

        actions.append(PhotonRowActions(pinTopSite))
        actions.append(PhotonRowActions(removeAction))

        let cell = tableView.cellForRow(at: indexPath)
        actions.append(getShareAction(site: site, sourceView: cell ?? self.view, delegate: historyCoordinatorDelegate))
        return actions
    }
}

// MARK: - UITableViewDelegate related helpers

extension HistoryPanel: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let item = diffableDataSource?.itemIdentifier(for: indexPath) else { return }

        if let site = item as? Site {
            handleSiteItemTapped(site: site)
        }

        if let historyActionable = item as? HistoryActionablesModel {
            handleHistoryActionableTapped(historyActionable: historyActionable)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if searchbar.isFirstResponder {
            searchbar.resignFirstResponder()
        }
    }

    private func handleSiteItemTapped(site: Site) {
        guard let url = URL(string: site.url, invalidCharacters: false) else {
            self.logger.log("Couldn't navigate to site",
                            level: .warning,
                            category: .library)
            return
        }

        libraryPanelDelegate?.libraryPanel(didSelectURL: url, visitType: .typed)

        sendSelectedHistoryItemCount()
        sendOpenedHistoryItemTelemetry()
    }

    private func handleHistoryActionableTapped(historyActionable: HistoryActionablesModel) {
        updatePanelState(newState: .history(state: .inFolder))

        switch historyActionable.itemIdentity {
        case .clearHistory:
            showClearRecentHistory()
        case .recentlyClosed:
            guard viewModel.hasRecentlyClosed else { return }
            refreshControl?.endRefreshing()
            historyCoordinatorDelegate?.showRecentlyClosedTab()
        default: break
        }
    }

    @objc
    private func sectionHeaderTapped(sender: UIGestureRecognizer) {
        guard let sectionNumber = sender.view?.tag else { return }

        viewModel.collapseSection(sectionIndex: sectionNumber)
        applySnapshot()
        // Needed to refresh the header state
        tableView.reloadData()
    }

    // MARK: - TableView's Header & Footer view
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // First section is for recently closed and its header has no view.
        guard HistoryPanelSections(rawValue: section) != .additionalHistoryActions,
              let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: SiteTableViewHeader.cellIdentifier
              ) as? SiteTableViewHeader,
              let actualSection = viewModel.visibleSections[safe: section - 1]
        else { return nil }

        let isCollapsed = viewModel.isSectionCollapsed(sectionIndex: section - 1)
        let headerViewModel = SiteTableViewHeaderModel(
            title: actualSection.title ?? "",
            isCollapsible: true,
            collapsibleState: isCollapsed ? ExpandButtonState.trailing : ExpandButtonState.down
        )
        header.configure(headerViewModel)
        header.applyTheme(theme: currentTheme())

        // Configure tap to collapse/expand section
        header.tag = section
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sectionHeaderTapped(sender:)))
        header.addGestureRecognizer(tapGesture)

        return header
    }

    // viewForHeaderInSection REQUIRES implementing heightForHeaderInSection
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // First section is for recently closed and its header has no height.
        guard HistoryPanelSections(rawValue: section) != .additionalHistoryActions else {
            return 0
        }

        return UITableView.automaticDimension
    }
}

/// Refresh controls helpers
extension HistoryPanel {
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
        profile.syncManager?.syncHistory().uponQueue(.main) { syncResult in
            self.endRefreshing()

            if syncResult.isSuccess {
                self.fetchDataAndUpdateLayout(animating: true)
            }
        }
    }
}

// MARK: - User action helpers
extension HistoryPanel {
    func handleLeftTopButton() {
        updatePanelState(newState: .history(state: .mainView))
    }

    func handleRightTopButton() {
        if state == .history(state: .search) {
            exitSearchState()
            updatePanelState(newState: .history(state: .mainView))
        }
    }

    func bottomSearchButtonAction() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .searchHistory)
        startSearchState()
    }

    func bottomDeleteButtonAction() {
        // Leave search mode when clearing history
        updatePanelState(newState: .history(state: .mainView))

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .deleteHistory)
        showClearRecentHistory()
    }

    // MARK: - User Interactions

    /// When long pressed, a menu appears giving the choice of pinning as a Top Site.
    func pinToTopSites(_ site: Site) {
        profile.pinnedSites.addPinnedTopSite(site).uponQueue(.main) { result in
            if result.isSuccess {
                SimpleToast().showAlertWithText(.LegacyAppMenu.AddPinToShortcutsConfirmMessage,
                                                bottomContainer: self.view,
                                                theme: self.currentTheme())
            }
        }
    }

    @objc
    private func onLongPressGestureRecognized(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint),
              diffableDataSource?.itemIdentifier(for: indexPath) as? HistoryActionablesModel == nil
        else { return }

        presentContextMenu(for: indexPath)
    }

    @objc
    private func onRefreshPulled() {
        refreshControl?.beginRefreshing()
        resyncHistory()
    }
}

extension HistoryPanel: UITableViewDataSourcePrefetching {
    // Happens WAY too often. We should consider fetching the next set when the user HITS the bottom instead.
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard !viewModel.isFetchInProgress, indexPaths.contains(where: shouldLoadRow) else { return }

        fetchDataAndUpdateLayout()
    }

    func shouldLoadRow(for indexPath: IndexPath) -> Bool {
        guard HistoryPanelSections(rawValue: indexPath.section) != .additionalHistoryActions else { return false }

        return indexPath.row >= viewModel.dateGroupedSites.numberOfItemsForSection(
            indexPath.section - 1
        ) - historyPanelPrefetchOffset
    }
}
