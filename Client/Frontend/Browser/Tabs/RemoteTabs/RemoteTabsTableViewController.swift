// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import Shared
import Redux

class RemoteTabsTableViewController: UITableViewController,
                                     Themeable,
                                     CollapsibleTableViewSection,
                                     LibraryPanelContextMenu {
    struct UX {
        static let rowHeight = SiteTableViewControllerUX.RowHeight
    }

    // MARK: - Properties

    private(set) var state: RemoteTabsPanelState

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    weak var remoteTabsPanel: RemoteTabsPanel?

    private var isShowingEmptyView: Bool { state.showingEmptyState != nil }
    private let emptyView: RemoteTabsEmptyView = .build()

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    // MARK: - Initializer

    init(state: RemoteTabsPanelState,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.state = state
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

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

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }

        tableView.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.syncedTabs

        tableView.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
        ])

        listenForThemeChange(view)
        applyTheme()

        refreshUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? ThemedNavigationController)?.applyTheme()

        // Add a refresh control if the user is logged in and the control
        // was not added before. If the user is not logged in, remove any
        // existing control.
        if state.allowsRefresh && refreshControl == nil {
            addRefreshControl()
        }

        refreshTabs(state: state, updateCache: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if refreshControl != nil {
            removeRefreshControl()
        }
    }

    // MARK: - UI

    func applyTheme() {
        tableView.separatorColor = themeManager.currentTheme.colors.layerLightGrey30
        emptyView.applyTheme(theme: themeManager.currentTheme)
        // TODO: Ensure theme applied to any custom cells.
    }

    private func refreshUI() {
        emptyView.isHidden = !isShowingEmptyView

        if isShowingEmptyView {
            configureEmptyView()
        }

        tableView.reloadData()
    }

    private func configureEmptyView() {
        guard let emptyState = state.showingEmptyState else { return }
        emptyView.configure(state: emptyState, delegate: remoteTabsPanel?.remotePanelDelegate)
        emptyView.applyTheme(theme: themeManager.currentTheme)
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
        refreshTabs(state: state, updateCache: true)
    }

    func endRefreshing() {
        // Always end refreshing, even if we failed!
        refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        if !state.allowsRefresh {
            removeRefreshControl()
        }
    }

    func updateDelegateClientAndTabData(_ clientAndTabs: [ClientAndTabs]) {
        // TODO: Forthcoming as part of ongoing tab tray Redux refactors. [FXIOS-6942] & [FXIOS-7509]

        refreshUI()
    }

    func refreshTabs(state: RemoteTabsPanelState, updateCache: Bool = false, completion: (() -> Void)? = nil) {
        ensureMainThread { [self] in
            self.state = state
            performRefresh(updateCache: updateCache, completion: completion)
        }
    }

    private func performRefresh(updateCache: Bool, completion: (() -> Void)?) {
        // Short circuit if the user is not logged in
        guard state.allowsRefresh else {
            endRefreshing()
            return
        }

        // TODO: Send Redux action to get clients & tabs, update once state received. Forthcoming.  [FXIOS-6942] & [FXIOS-7509]
        // store.dispatch(RemoteTabsPanelAction.refreshCachedTabs)
    }

    @objc
    private func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
    }

    func hideTableViewSection(_ section: Int) {
        // TODO: Forthcoming as part of ongoing Redux refactors. [FXIOS-6942] & [FXIOS-7509]

        refreshUI()
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
        return getRemoteTabContextMenuActions(for: site, remotePanelDelegate: remoteTabsPanel?.remotePanelDelegate)
    }

    // MARK: - UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isShowingEmptyView {
            return 0
        } else {
            // TODO: Show clients and tabs. Forthcoming. [FXIOS-6942]
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isShowingEmptyView {
            return 0
        } else {
            // TODO: Show clients and tabs. Forthcoming. [FXIOS-6942]
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !isShowingEmptyView else { assertionFailure("Empty view state should always have 0 sections/rows."); return .build() }

        // TODO: Show clients and tabs. Forthcoming. [FXIOS-6942]
        return UITableViewCell(frame: .zero)
    }
}
