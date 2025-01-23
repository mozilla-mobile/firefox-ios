// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import Shared
import Redux
import SiteImageView

import enum MozillaAppServices.VisitType

protocol CollapsibleTableViewSection: AnyObject {
    func hideTableViewSection(_ section: Int)
}

class RemoteTabsTableViewController: UITableViewController,
                                     Themeable,
                                     CollapsibleTableViewSection,
                                     LibraryPanelContextMenu,
                                     FeatureFlaggable {
    struct UX {
        static let rowHeight = SiteTableViewControllerUX.RowHeight
    }

    // MARK: - Properties

    private(set) var state: RemoteTabsPanelState
    private var hiddenSections = Set<Int>()
    private let logger: Logger

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    weak var remoteTabsPanel: RemoteTabsPanel?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private var isShowingEmptyView: Bool { state.showingEmptyState != nil }
    private let emptyView: RemoteTabsEmptyView = .build()

    private var closeTabRemoteDeviceId: String?
    private var closeTab: RemoteTab?
    private var tabCommandsFlushTimer: Timer?
    private let tabCommandsFlushDelay = 6.0

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    // Checks whether we have allowed the user to close tabs on other
    // devices
    private var closeRemoteTabsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.closeRemoteTabs, checking: .buildOnly)
    }

    // MARK: - Initializer

    init(state: RemoteTabsPanelState,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.state = state
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        listenForThemeChange(view)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? ThemedNavigationController)?.applyTheme()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if refreshControl != nil {
            removeRefreshControl()
        }
    }

    // MARK: - UI

    private func setupLayout() {
        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.register(SiteTableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: SiteTableViewHeader.cellIdentifier)
        tableView.register(TwoLineImageOverlayCell.self,
                           forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier)

        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UX.rowHeight
        tableView.separatorInset = .zero
        tableView.alwaysBounceVertical = false

        tableView.sectionHeaderTopPadding = 0.0

        tableView.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.syncedTabs

        tableView.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
        ])

        reloadUI()
        addRefreshControl()
    }

    func newState(state: RemoteTabsPanelState) {
        self.state = state
        reloadUI()
    }

    private func reloadUI() {
        updateUI()
        tableView.reloadData()
    }

    private func updateUI() {
        if state.refreshState == .refreshing {
            emptyView.isHidden = true
            refreshControl?.beginRefreshing()
        } else {
            emptyView.isHidden = !isShowingEmptyView
            if isShowingEmptyView {
                configureEmptyView()
            }
            refreshControl?.endRefreshing()
        }
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        emptyView.applyTheme(theme: theme)
        tableView.visibleCells.forEach { ($0 as? ThemeApplicable)?.applyTheme(theme: theme) }
    }

    private func configureEmptyView() {
        guard let emptyState = state.showingEmptyState else { return }
        emptyView.configure(state: emptyState, delegate: remoteTabsPanel)
        emptyView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
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
        guard state.allowsRefresh else {
            endRefreshing()
            return
        }
        guard state.refreshState == .idle else {
            return
        }
        refreshControl?.beginRefreshing()
        remoteTabsPanel?.tableViewControllerDidPullToRefresh()
    }

    private func beginRefreshing() {
        if state.allowsRefresh && refreshControl == nil {
            addRefreshControl()
            refreshControl?.beginRefreshing()
        }
    }

    private func endRefreshing() {
        // Always end refreshing, even if we failed!
        refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        if !state.allowsRefresh {
            removeRefreshControl()
        }
    }

    @objc
    private func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
    }

    func hideTableViewSection(_ section: Int) {
        if hiddenSections.contains(section) {
            hiddenSections.remove(section)
        } else {
            hiddenSections.insert(section)
        }

        reloadUI()
    }

    func presentContextMenu(for site: Site, with indexPath: IndexPath,
                            completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }

        present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        // TODO: Forthcoming as part of ongoing Redux refactors. [FXIOS-6942] & [FXIOS-7509]
        return nil
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        // TODO: Forthcoming as part of ongoing Redux refactors. [FXIOS-6942] & [FXIOS-7509]
        return nil
    }

    // MARK: - UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard !isShowingEmptyView else { return 0 }

        return state.clientAndTabs.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !isShowingEmptyView, !hiddenSections.contains(section) else { return 0 }
        return state.clientAndTabs[section].tabs.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !isShowingEmptyView else {
            assertionFailure("Empty state; expecting 0 sections/rows.")
            return .build()
        }

        let identifier = TwoLineImageOverlayCell.cellIdentifier
        let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        guard let cell = dequeuedCell as? TwoLineImageOverlayCell else { return UITableViewCell() }

        let tab = state.clientAndTabs[indexPath.section].tabs[indexPath.item]
        configureCell(cell, for: tab)

        return cell
    }

    private func configureCell(_ cell: TwoLineImageOverlayCell, for tab: RemoteTab) {
        cell.titleLabel.text = tab.title
        cell.descriptionLabel.text = tab.URL.absoluteString
        cell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: tab.URL.absoluteString))
        cell.accessoryView = nil
        cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
    }

    @objc
    private func sectionHeaderTapped(sender: UIGestureRecognizer) {
         guard let section = sender.view?.tag else { return }
         hideTableViewSection(section)
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let tab = state.clientAndTabs[indexPath.section].tabs[indexPath.item]

        // Remote panel delegate for cell selection
        remoteTabsPanel?.remoteTabsClientAndTabsDataSourceDidSelectURL(tab.URL, visitType: VisitType.typed)
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let clientAndTabs = state.clientAndTabs[indexPath.section]
            guard let fxaDeviceId = clientAndTabs.client.fxaDeviceId else {
                // This is a state we probably shouldn't be able to get into
                // so logging the error
                logger.log("Error retrieving remote device ID to close tab",
                           level: .fatal,
                           category: .tabs)
                return
            }
            let tab = clientAndTabs.tabs[indexPath.item]

            // Setting the two private variables below so that the toast button action function has access to them
            // since that function cannot have any parameters.
            self.closeTabRemoteDeviceId = fxaDeviceId
            self.closeTab = tab

            // Creating a modal with an undo button that will allow the user to undo closing the last remote tab
            // they attempted to close
            ActionToast(
                text: .TabsTray.CloseTabsToast.SingleTabTitle,
                bottomContainer: view,
                theme: themeManager.getCurrentTheme(for: windowUUID),
                buttonTitle: .UndoString,
                buttonAction: self.undo
            ).show()

            self.remoteTabsPanel?.remoteTabsClientAndTabsDataSourceDidCloseURL(deviceId: fxaDeviceId, url: tab.URL)

            // Initiating the process of sending (i.e. executing) any unsent commands
            self.flushTabCommands(deviceId: fxaDeviceId)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let clientAndTabs = state.clientAndTabs[indexPath.section]
        guard let deviceId = clientAndTabs.client.fxaDeviceId else {
            // should not get into this situation, we should probs throw an error
            // re above, can't throw from here so logging
            logger.log("Error retrieving remote device ID to close tab",
                       level: .fatal,
                       category: .tabs)
            return false
        }

        // Checking whether the device has the capability to send a close remote tab command
        let isCloseRemoteTabCompatible = self.state.devices.first(where: { $0.id == deviceId })?
                                                            .capabilities.contains(.closeTabs) ?? false

        // Enabling close tab UI if the capability on this device exists and the feature is enabled
        return isCloseRemoteTabCompatible && closeRemoteTabsEnabled
    }

    override func tableView(_ tableView: UITableView,
                            titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
         return .ContextualHints.ContextualHintsCloseAccessibility
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: SiteTableViewHeader.cellIdentifier) as? SiteTableViewHeader else { return nil }

        let clientTabs = state.clientAndTabs[section]
        let client = clientTabs.client

        let isCollapsed = hiddenSections.contains(section)
        let collapsibleState = isCollapsed ? ExpandButtonState.trailing : ExpandButtonState.down
        let headerModel = SiteTableViewHeaderModel(title: client.name,
                                                   isCollapsible: true,
                                                   collapsibleState: collapsibleState)
        headerView.configure(headerModel)
        headerView.showBorder(for: .bottom, true)
        headerView.showBorder(for: .top, section != 0)

        // Configure tap to collapse/expand section
        headerView.tag = section
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(sectionHeaderTapped(sender:)))
        headerView.addGestureRecognizer(tapGesture)
        headerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        /*
        * (Copied from legacy RemoteTabsClientAndTabsDataSource)
        * A note on timestamps.
        * We have access to two timestamps here: the timestamp of the remote client record,
        * and the set of timestamps of the client's tabs.
        * Neither is "last synced". The client record timestamp changes whenever the remote
        * client uploads its record (i.e., infrequently), but also whenever another device
        * sends a command to that client -- which can be much later than when that client
        * last synced.
        * The client's tabs haven't necessarily changed, but it can still have synced.
        * Ideally, we should save and use the modified time of the tabs record itself.
        * This will be the real time that the other client uploaded tabs.
        */
        return headerView
    }

    private func undo() {
        guard let tabUrl = self.closeTab?.URL, let deviceId = self.closeTabRemoteDeviceId else {
            return
        }

        // Removing the close tab command from the command queue
        remoteTabsPanel?.remoteTabsClientAndTabsDataSourceDidUndo(deviceId: deviceId, url: tabUrl)

        // Initiating the process of sending any unsent commands
        self.flushTabCommands(deviceId: deviceId)
    }

    private func flushTabCommands(deviceId: String) {
        // If the timer property is set and is valid, we reset it. This will prevent flush
        // from being executed too often. It will run `self.tabCommandsFlushDelay` seconds
        // after the last interaction with the close tab UI.
        if self.tabCommandsFlushTimer != nil && self.tabCommandsFlushTimer?.isValid ?? false {
            self.tabCommandsFlushTimer?.invalidate()
            self.tabCommandsFlushTimer = nil
        }

        self.tabCommandsFlushTimer = Timer.scheduledTimer(withTimeInterval: self.tabCommandsFlushDelay,
                                                          repeats: false) { _ in
            self.remoteTabsPanel?.remoteTabsClientAndTabsDataSourceDidTabCommandsFlush(deviceId: deviceId)
        }
    }
}
