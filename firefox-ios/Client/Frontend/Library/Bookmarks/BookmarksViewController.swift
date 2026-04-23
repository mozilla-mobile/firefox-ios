// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Storage
import Shared
import SiteImageView

import MozillaAppServices

final class BookmarksViewController: SiteTableViewController,
                                     LibraryPanel,
                                     CanRemoveQuickActionBookmark,
                                     UITableViewDropDelegate,
                                     Notifiable,
                                     FeatureFlaggable {
    struct UX {
        static let FolderIconSize = CGSize(width: 24, height: 24)
        static let RowFlashDelay: TimeInterval = 0.4
        static let toastDismissDelay = DispatchTimeInterval.seconds(8)
        static let toastDelayBefore = DispatchTimeInterval.milliseconds(0)
    }

    // MARK: - Properties
    var bookmarksHandler: BookmarksHandler
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    weak var bookmarkCoordinatorDelegate: BookmarksCoordinatorDelegate?
    var state: LibraryPanelMainState
    var isTransitioning = false
    let viewModel: BookmarksPanelViewModelProtocol
    private var logger: Logger
    private let bookmarksTelemetry = BookmarksTelemetry()

    // MARK: - Search Properties
    var keyboardState: KeyboardState?

    // MARK: - Search UI (History-style bottom search bar)
    var bottomStackView: BaseAlphaStackView = .build { _ in }

    lazy var searchbar: UISearchBar = .build { searchbar in
        searchbar.searchTextField.placeholder = .LibraryPanel.History.SearchHistoryPlaceholder
        searchbar.returnKeyType = .go
        searchbar.delegate = self
        searchbar.showsCancelButton = true
    }

    // MARK: - Toolbar items
    var bottomToolbarItems: [UIBarButtonItem] {
        // Return empty toolbar when bookmarks is in desktop folder node
        guard case .bookmarks = state,
              viewModel.bookmarkFolderGUID != LocalDesktopFolder.localDesktopFolderGuid
        else { return [] }

        return toolbarButtonItems
    }

    private var isBookmarksSearchEnabled: Bool {
        featureFlagsProvider.isEnabled(.bookmarksSearchFeature)
    }

    private var toolbarButtonItems: [UIBarButtonItem] {
        // The search bar button should only be available when the current folder is not empty of bookmarks or subfolders
        let searchItems: [UIBarButtonItem] = isBookmarksSearchEnabled && !viewModel.isCurrentFolderEmpty
            ? [flexibleSpace, bottomSearchButton]
            : []

        switch state {
        case .bookmarks(state: .mainView),
             .bookmarks(state: .inFolder):
            bottomRightButton.title = .BookmarksEdit
            if #available(iOS 26.0, *) {
                bottomRightButton.tintColor = currentTheme().colors.textPrimary
            }
            return searchItems + [flexibleSpace, bottomRightButton]
        case .bookmarks(state: .search):
            return searchItems + [flexibleSpace]
        case .bookmarks(state: .inFolderEditMode):
            bottomRightButton.title = String.AppSettingsDone
            if #available(iOS 26.0, *) {
                bottomRightButton.tintColor = currentTheme().colors.textAccent
            }
            return [bottomLeftButton, flexibleSpace, bottomRightButton]
        case .bookmarks(state: .itemEditMode):
            bottomRightButton.title = String.AppSettingsDone
            if #available(iOS 26.0, *) {
                bottomRightButton.tintColor = currentTheme().colors.textAccent
            }
            bottomRightButton.isEnabled = true
            return [flexibleSpace, bottomRightButton]
        case .bookmarks(state: .itemEditModeInvalidField):
            bottomRightButton.title = String.AppSettingsDone
            if #available(iOS 26.0, *) {
                bottomRightButton.tintColor = currentTheme().colors.textAccent
            }
            bottomRightButton.isEnabled = false
            return [flexibleSpace, bottomRightButton]
        default:
            return []
        }
    }

    private lazy var bottomLeftButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: .BookmarksNewFolder,
            style: .plain,
            target: self,
            action: #selector(bottomLeftButtonAction)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomLeftButton
        return button
    }()

    private lazy var bottomRightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: .BookmarksEdit,
            style: .plain,
            target: self,
            action: #selector(bottomRightButtonAction)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomRightButton
        return button
    }()

    private lazy var bottomSearchButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.search),
            style: .plain,
            target: self,
            action: #selector(bottomSearchButtonAction)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomSearchButton
        return button
    }()

    private lazy var emptyStateView: BookmarksFolderEmptyStateView = .build { emptyStateView in
        emptyStateView.signInAction = { [weak self] in
            self?.bookmarkCoordinatorDelegate?.showSignIn()
        }
    }

    private lazy var a11yEmptyStateScrollView: UIScrollView = .build()

    // MARK: - Init

    init(viewModel: BookmarksPanelViewModelProtocol,
         windowUUID: WindowUUID,
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = viewModel
        self.logger = logger

        let isMobileFolder = viewModel.bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID
        self.state = isMobileFolder ? .bookmarks(state: .mainView) : .bookmarks(state: .inFolder)
        self.bookmarksHandler = viewModel.profile.places
        super.init(profile: viewModel.profile, windowUUID: windowUUID)

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [.FirefoxAccountChanged, .ProfileDidFinishSyncing]
        )

        tableView.register(cellType: OneLineTableViewCell.self)
        tableView.register(cellType: SeparatorTableViewCell.self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            DefaultLogger.shared.log(
                "AddressToolbarContainer was not deallocated on the main thread. Redux was not cleaned up.",
                level: .fatal,
                category: .lifecycle
            )
            assertionFailure("The view was not deallocated on the main thread. Redux was not cleaned up.")
            return
        }

        MainActor.assumeIsolated {
            // FXIOS-11315: Necessary to prevent BookmarksFolderEmptyStateView from being retained in memory
            a11yEmptyStateScrollView.removeFromSuperview()
        }
    }

    // MARK: - Lifecycle

    // FIXME: FXIOS-12996 Use Themeable instead of custom theme setting
    override func viewDidLoad() {
        super.viewDidLoad()

        KeyboardHelper.defaultHelper.addDelegate(self)

        let tableViewLongPressRecognizer = UILongPressGestureRecognizer(target: self,
                                                                        action: #selector(didLongPressTableView))
        tableView.addGestureRecognizer(tableViewLongPressRecognizer)
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.tableView
        tableView.allowsSelectionDuringEditing = true
        tableView.dragInteractionEnabled = false
        tableView.dragDelegate = self
        tableView.dropDelegate = self

        setupLayout()
        setupEmptyStateView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if self.state == .bookmarks(state: .inFolderEditMode) {
            self.tableView.setEditing(true, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set this panel's initial state.
        if tableView.isEditing {
            // This happens if we navigate back to the panel either from the bookmark/folder detail screen during "Edit" mode
            updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        } else {
            if viewModel.isRootNode {
                updatePanelState(newState: .bookmarks(state: .mainView))
            } else {
                updatePanelState(newState: .bookmarks(state: .inFolder))
            }
        }

        sendPanelChangeNotification()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Clear any `isTransitioning` state once the user is back on this panel fully
        isTransitioning = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If needed, exit the search when the view disappears
        if state == .bookmarks(state: .search) {
            exitSearchState()
        }
    }

    // MARK: - Data

    override func reloadData() {
        viewModel.reloadData {
            self.tableView.reloadData()
            if self.viewModel.shouldFlashRow {
                self.flashRow()
            }
            self.updateEmptyState(animated: false)
            self.updateParentViewControllerTitle()
        }
    }

    private func updateParentViewControllerTitle() {
        if !viewModel.isRootNode, let folderTitle = viewModel.bookmarkFolder?.title {
            notificationCenter.post(name: .LibraryPanelBookmarkTitleChanged,
                                    withObject: nil,
                                    withUserInfo: ["title": folderTitle])
        } else {
            // This will set the title to the default one
            notificationCenter.post(name: .LibraryPanelBookmarkTitleChanged,
                                    withObject: nil,
                                    withUserInfo: nil)
        }
    }

    // MARK: - Actions

    private func centerVisibleRow() -> Int {
        let visibleCells = tableView.visibleCells
        if let middleCell = visibleCells[safe: visibleCells.count / 2],
           let middleIndexPath = tableView.indexPath(for: middleCell) {
            return middleIndexPath.row
        }

        return viewModel.displayedBookmarkNodes.count
    }

    /// Attempt to delete the bookmark node (bookmark or folder) at the given index path. If the node is for a folder,
    /// will present an alert for the user to confirm deletion.
    private func deleteBookmarkNodeAtIndexPath(_ indexPath: IndexPath) {
        guard let bookmarkNode = viewModel.displayedBookmarkNodes[safe: indexPath.row] else {
            return
        }

        // If this node is a folder and it is not empty, we need to prompt the user before deleting
        if bookmarkNode.isNonEmptyFolder {
            presentAlertToConfirmFolderDeletion(indexPath, bookmarkNode: bookmarkNode)
        } else if bookmarkNode.type == .separator {
            deleteBookmarkNode(indexPath, bookmarkNode: bookmarkNode)
        } else {
            deleteBookmarkNode(indexPath, bookmarkNode: bookmarkNode)
        }
    }

    /// Show an alert to confirm whether the user wishes to delete a bookmarks folder.
    /// - Parameters:
    ///   - indexPath: The index path of the folder.
    ///   - bookmarkNode: The bookmark node of the folder.
    private func presentAlertToConfirmFolderDeletion(_ indexPath: IndexPath, bookmarkNode: FxBookmarkNode) {
        let alertController = UIAlertController(title: .BookmarksDeleteFolderWarningTitle,
                                                message: .BookmarksDeleteFolderWarningDescription,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: .BookmarksDeleteFolderCancelButtonLabel,
                                                style: .default))
        alertController.addAction(UIAlertAction(title: .BookmarksDeleteFolderDeleteButtonLabel,
                                                style: .destructive) { [weak self] action in
            self?.deleteBookmarkNode(indexPath, bookmarkNode: bookmarkNode)
        })
        present(alertController, animated: true, completion: nil)
    }

    /// Performs the delete asynchronously even though we update the
    /// table view data source immediately for responsiveness.
    private func deleteBookmarkNode(_ indexPath: IndexPath, bookmarkNode: FxBookmarkNode) {
        tableView.beginUpdates()
        // Removes the bookmark from local data arrays for optimistic UI update, then re-queries and reloads the table
        // because deleting a node while searching can alter the bookmarks tree at lower depths.
        viewModel.remove(bookmark: bookmarkNode, afterAsyncRemoval: { [weak self] in
            self?.tableView.reloadData()
        })
        tableView.deleteRows(at: [indexPath], with: .left)
        tableView.endUpdates()

        // If the last bookmark in this folder was deleted and the user is searching, exit search
        if viewModel.isCurrentFolderEmpty && state == .bookmarks(state: .search) {
            exitSearchState() // Note: Also calls updateEmptyState()
        } else {
            updateEmptyState(animated: false)
        }
    }

    // MARK: Button Actions helpers

    func enableEditMode() {
        updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        self.tableView.setEditing(true, animated: true)
        self.tableView.dragInteractionEnabled = true
        updateEmptyState(animated: true)
    }

    func disableEditMode() {
        let substate: LibraryPanelSubState = viewModel.isRootNode ? .mainView : .inFolder
        updatePanelState(newState: .bookmarks(state: substate))
        self.tableView.setEditing(false, animated: true)
        self.tableView.dragInteractionEnabled = false
        updateEmptyState(animated: true)
    }

    private func sendPanelChangeNotification() {
        let userInfo: [String: Any] = ["state": state]
        NotificationCenter.default.post(name: .LibraryPanelStateDidChange, object: nil, userInfo: userInfo)
    }

    // MARK: - Utility

    private func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        return indexPath.section < numberOfSections(in: tableView)
        && indexPath.row < tableView(tableView, numberOfRowsInSection: indexPath.section)
        && indexPath.row >= 0
        && viewModel.bookmarkFolderGUID != BookmarkRoots.MobileFolderGUID
    }

    private func numberOfSections(in tableView: UITableView) -> Int {
        if let folder = viewModel.bookmarkFolder, folder.guid == BookmarkRoots.RootGUID {
            return 2
        }

        return 1
    }

    private func flashRow() {
        let lastIndexPath = IndexPath(row: viewModel.displayedBookmarkNodes.count - 1,
                                      section: BookmarksPanelViewModel.BookmarksSection.bookmarks.rawValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.RowFlashDelay) {
            self.flashRow(at: lastIndexPath)
        }
    }

    private func flashRow(at indexPath: IndexPath) {
        guard indexPathIsValid(indexPath) else {
            logger.log("Flash row indexPath invalid: \(indexPath)",
                       level: .debug,
                       category: .library)
            return
        }

        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)

        DispatchQueue.main.asyncAfter(deadline: .now() + UX.RowFlashDelay) {
            if self.indexPathIsValid(indexPath) {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    private func updateEmptyState(animated: Bool) {
        let showEmptyState = viewModel.isCurrentFolderEmpty && !tableView.isEditing && state != .bookmarks(state: .search)

        if animated {
            a11yEmptyStateScrollView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.a11yEmptyStateScrollView.alpha = showEmptyState ? 1 : 0
            }) { _ in
                self.a11yEmptyStateScrollView.isHidden = !showEmptyState
            }
        } else {
            a11yEmptyStateScrollView.alpha = showEmptyState ? 1 : 0
            a11yEmptyStateScrollView.isHidden = !showEmptyState
        }

        emptyStateView.configure(isRoot: viewModel.isRootNode,
                                 isSignedIn: profile.hasAccount())

        // Depending on empty state, show/hide the search bar in the library panel's toolbar
        sendPanelChangeNotification()
    }

    private func createContextButton() -> UIButton {
        var buttonConfig = UIButton.Configuration.plain()
        let icon = UIImage(named: StandardImageIdentifiers.Large.ellipsis)?.withRenderingMode(.alwaysTemplate)
        buttonConfig.image = icon
        buttonConfig.automaticallyUpdateForSelection = true
        let contextButton = UIButton()
        contextButton.configuration = buttonConfig
        contextButton.accessibilityLabel = .Bookmarks.Menu.MoreOptionsA11yLabel

        return contextButton
    }

    // MARK: - Actions

    @objc
    private func didLongPressTableView(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard longPressGestureRecognizer.state == .began,
              let indexPath = tableView.indexPathForRow(at: touchPoint) else {
            return
        }

        presentContextMenu(for: indexPath)
    }

    private func resetSearch() {
        viewModel.resetSearch()
        tableView.reloadData()
        updateEmptyState(animated: false)
    }

    private func backButtonView() -> UIView? {
        let navigationBarContentView = navigationController?.navigationBar.subviews.first(where: {
            $0.description.starts(with: "<_UINavigationBarContentView:")
        })

        return navigationBarContentView?.subviews.first(where: {
            $0.description.starts(with: "<_UIButtonBarButton:")
        })
    }

    // MARK: - UI Setup
    private func setupLayout() {
        view.addSubview(bottomStackView)
        bottomStackView.addArrangedSubview(searchbar)
        bottomStackView.isHidden = true

        NSLayoutConstraint.activate([
            bottomStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        bottomStackView.applyTheme(theme: currentTheme())
    }

    func updateLayoutForKeyboard() {
        guard let keyboardHeight = keyboardState?.intersectionHeightForView(view),
              keyboardHeight > 0 else {
            bottomStackView.removeKeyboardSpacer()
            return
        }

        let spacerHeight = keyboardHeight - UIConstants.BottomToolbarHeight
        bottomStackView.addKeyboardSpacer(spacerHeight: spacerHeight)
    }

    private func updateBottomSearchBarLayout(isHidden: Bool) {
        bottomStackView.isHidden = isHidden

        let bottomInset = isHidden ? 0 : searchbar.bounds.height
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func setupEmptyStateView() {
        view.addSubview(a11yEmptyStateScrollView)
        a11yEmptyStateScrollView.addSubview(emptyStateView)
        a11yEmptyStateScrollView.isHidden = true
        NSLayoutConstraint.activate(
            [
                a11yEmptyStateScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                a11yEmptyStateScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                a11yEmptyStateScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                a11yEmptyStateScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

                emptyStateView.leadingAnchor.constraint(equalTo: a11yEmptyStateScrollView.contentLayoutGuide.leadingAnchor),
                emptyStateView.trailingAnchor.constraint(
                        equalTo: a11yEmptyStateScrollView.contentLayoutGuide.trailingAnchor),
                emptyStateView.topAnchor.constraint(equalTo: a11yEmptyStateScrollView.contentLayoutGuide.topAnchor),
                emptyStateView.bottomAnchor.constraint(equalTo: a11yEmptyStateScrollView.contentLayoutGuide.bottomAnchor),
                emptyStateView.widthAnchor.constraint(equalTo: a11yEmptyStateScrollView.frameLayoutGuide.widthAnchor),
                emptyStateView.heightAnchor.constraint(
                    greaterThanOrEqualTo: a11yEmptyStateScrollView.frameLayoutGuide.heightAnchor),
            ]
        )
        emptyStateView.applyTheme(theme: currentTheme())
    }

    // MARK: - UITableViewDataSource | UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard let node = viewModel.displayedBookmarkNodes[safe: indexPath.row],
              let bookmarkCell = node as? BookmarksFolderCell
        else { return }

        guard !tableView.isEditing else {
            if let bookmarkFolder = self.viewModel.bookmarkFolder,
               !(node is BookmarkSeparatorData),
               state != .bookmarks(state: .search),
               isCurrentFolderEditable(at: indexPath) {
                // Only show detail controller for editable nodes
                bookmarkCoordinatorDelegate?.showBookmarkDetail(for: node, folder: bookmarkFolder)
            }
            return
        }

        if let itemData = bookmarkCell as? BookmarkItemData,
           let url = URL(string: itemData.url) {
            // Navigate to a webpage when tapping a bookmark
            libraryPanelDelegate?.libraryPanel(didSelectURL: url, visitType: .bookmark)
        } else {
            // Drill deeper into a bookmark folder
            guard let folder = bookmarkCell as? FxBookmarkNode else { return }

            // If the user taps on a folder before filtering the bookmarks with a search term, simply exit search
            if state == .bookmarks(state: .search) {
                exitSearchState()
            }

            bookmarkCoordinatorDelegate?.start(from: folder)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.displayedBookmarkNodes.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let node = viewModel.displayedBookmarkNodes[safe: indexPath.row] else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        if let bookmarkCell = node as? BookmarksFolderCell,
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OneLineTableViewCell.cellIdentifier,
                for: indexPath) as? OneLineTableViewCell {
            var viewModel = bookmarkCell.getViewModel()

            let cellA11yId = "\(AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.bookmarksCell)_\(indexPath.row)"
            cell.accessibilityIdentifier = cellA11yId
            cell.accessibilityTraits = .button

            // BookmarkItemData requires:
            // - Site to setup cell image
            // - AccessoryView to setup context menu button affordance
            if let node = node as? BookmarkItemData {
                let site = Site.createBasicSite(
                    url: node.url,
                    title: node.title,
                    isBookmarked: true
                )
                if viewModel.leftImageView == nil {
                    cell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: site.url))
                }

                let contextButton = createContextButton()
                contextButton.accessibilityIdentifier = cellA11yId +
                AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.bookmarksCellDisclosureButton
                contextButton.addAction(UIAction { [weak self] _ in
                    guard let indexPath = tableView.indexPath(for: cell) else { return }
                    self?.presentContextMenu(for: indexPath)
                }, for: .touchUpInside)
                viewModel.accessoryView = contextButton
            }

            cell.configure(viewModel: viewModel)
            cell.applyTheme(theme: currentTheme())
            return cell
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: SeparatorTableViewCell.cellIdentifier,
                                                        for: indexPath) as? SeparatorTableViewCell {
                cell.applyTheme(theme: currentTheme())
                return cell
            } else {
                return UITableViewCell()
            }
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard state != .bookmarks(state: .search) else { return false }
        return isCurrentFolderEditable(at: indexPath)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard state != .bookmarks(state: .search) else { return false }
        return isCurrentFolderEditable(at: indexPath)
    }

    /// Root folders and local desktop folder cannot be moved or edited
    private func isCurrentFolderEditable(at indexPath: IndexPath) -> Bool {
        guard let currentRowData = viewModel.displayedBookmarkNodes[safe: indexPath.row] else {
            return false
        }

        var uneditableGuids = Array(BookmarkRoots.All)
        uneditableGuids.append(LocalDesktopFolder.localDesktopFolderGuid)
        return !uneditableGuids.contains(currentRowData.guid)
    }

    func tableView(_ tableView: UITableView,
                   moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath) {
        viewModel.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: .BookmarksPanelDeleteTableAction
        ) { [weak self] (_, _, completion) in
            guard let self else {
                completion(false)
                return
            }

            self.deleteBookmarkNodeAtIndexPath(indexPath)
            self.bookmarksTelemetry.deleteBookmark(eventLabel: .bookmarksPanel)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    private func applyThemeToSearchBar() {
        bottomStackView.applyTheme(theme: currentTheme())
    }

    override func applyTheme() {
        super.applyTheme()
        applyThemeToSearchBar()
    }

    // MARK: - UITableViewDragDelegate | UITableViewDropDelegate

    override func tableView(_ tableView: UITableView,
                            itemsForBeginning session: any UIDragSession,
                            at indexPath: IndexPath) -> [UIDragItem] {
        let item = UIDragItem(itemProvider: NSItemProvider())
        item.localObject = indexPath

        return [item]
    }

    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard let destinationIndex = destinationIndexPath?.row,
              let sourceIndex = (session.localDragSession?.items[safe: 0]?.localObject as? IndexPath)?.row,
              let destinationFolder = viewModel.displayedBookmarkNodes[safe: destinationIndex],
              let sourceNode = viewModel.displayedBookmarkNodes[safe: sourceIndex],
              destinationFolder.type == .folder,
              sourceNode.type == .bookmark || sourceNode.type == .folder,
              sourceNode.guid != destinationFolder.guid else {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UITableViewDropProposal(operation: .move, intent: .automatic)
    }

    /// Called when a user is in Edit mode and drags and drops a bookmark into a folder. Updates the bookmark's parent folder
    /// GUID and reloads the table.
    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items[safe: 0],
              let sourceIndexPath = item.dragItem.localObject as? IndexPath,
              let sourceItem = viewModel.displayedBookmarkNodes[safe: sourceIndexPath.row],
              let destinationItem = viewModel.displayedBookmarkNodes[safe: destinationIndexPath.row],
              coordinator.proposal.intent == .insertIntoDestinationIndexPath
        else { return }

        tableView.beginUpdates()
        viewModel.moveBookmarkToFolder(bookmark: sourceItem, withGUID: destinationItem.guid)
        tableView.deleteRows(at: [sourceIndexPath], with: .left)
        tableView.endUpdates()

        updateEmptyState(animated: false)
        profile.prefs.setString(destinationItem.guid, forKey: PrefsKeys.RecentBookmarkFolder)
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        updateEmptyState(animated: false)
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .ProfileDidFinishSyncing:
            ensureMainThread {
                self.reloadData()
            }
        default:
            break
        }
    }
}

// MARK: - LibraryPanelContextMenu

extension BookmarksViewController: LibraryPanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        guard let bookmark = viewModel.displayedBookmarkNodes[safe: indexPath.row] else { return }

        viewModel.getSiteDetails(for: bookmark) { [weak self] site in
            if let site {
                self?.presentContextMenu(for: site, with: indexPath, completionHandler: {
                    return self?.contextMenu(for: site, with: indexPath)
                })
            } else if let bookmarkNode = self?.viewModel.displayedBookmarkNodes[safe: indexPath.row],
                      bookmarkNode.type == .folder,
                      self?.isCurrentFolderEditable(at: indexPath) ?? false {
                self?.presentContextMenu(for: bookmarkNode, indexPath: indexPath)
            }
        }
    }

    func presentContextMenu(for site: Site,
                            with indexPath: IndexPath,
                            completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else {
            return
        }

        present(contextMenu, animated: true, completion: nil)
    }

    private func presentContextMenu(for folder: FxBookmarkNode, indexPath: IndexPath) {
        let actions: [PhotonRowActions] = getFolderContextMenuActions(for: folder, indexPath: indexPath)
        let viewModel = PhotonActionSheetViewModel(actions: [actions],
                                                   bookmarkFolderTitle: folder.title,
                                                   modalStyle: .overFullScreen)

        let contextMenu = PhotonActionSheet(viewModel: viewModel, windowUUID: windowUUID)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        present(contextMenu, animated: true, completion: nil)
    }

    private func getFolderContextMenuActions(for folder: FxBookmarkNode, indexPath: IndexPath) -> [PhotonRowActions] {
        let editAction = SingleActionViewModel(title: .Bookmarks.Menu.EditFolder,
                                               iconString: StandardImageIdentifiers.Large.edit,
                                               tapHandler: { _ in
            guard let parentFolder = self.viewModel.bookmarkFolder else {return}
            self.bookmarkCoordinatorDelegate?.showBookmarkDetail(for: folder, folder: parentFolder)
        }).items

        let removeAction = SingleActionViewModel(title: String.Bookmarks.Menu.DeleteFolder,
                                                 iconString: StandardImageIdentifiers.Large.delete,
                                                 tapHandler: { _ in
            self.deleteBookmarkNodeAtIndexPath(indexPath)
        }).items

        return [editAction, removeAction]
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        guard let defaultActions = getDefaultContextMenuActions(for: site, libraryPanelDelegate: libraryPanelDelegate) else {
            return nil
        }

        var actions: [PhotonRowActions] = defaultActions

        let editBookmark = SingleActionViewModel(title: .Bookmarks.Menu.EditBookmark,
                                                 iconString: StandardImageIdentifiers.Large.edit,
                                                 tapHandler: { _ in
            guard let bookmarkNode = self.viewModel.displayedBookmarkNodes[safe: indexPath.row],
                  let bookmarkFolder = self.viewModel.bookmarkFolder else {
                return
            }
            self.bookmarkCoordinatorDelegate?.showBookmarkDetail(for: bookmarkNode, folder: bookmarkFolder)
        }).items
        actions.append(editBookmark)

        let pinTopSiteAction = viewModel.createPinUnpinAction(
            for: site,
            isPinned: site.isPinnedSite
        ) { [weak self] message in
            self?.libraryPanelDelegate?.showToast(message: message)
        }
        actions.append(pinTopSiteAction)

        let removeAction = SingleActionViewModel(title: .RemoveBookmarkContextMenuTitle,
                                                 iconString: StandardImageIdentifiers.Large.bookmarkSlash,
                                                 tapHandler: { _ in
            self.deleteBookmarkNodeAtIndexPath(indexPath)
            self.bookmarksTelemetry.deleteBookmark(eventLabel: .bookmarksPanel)
        }).items
        actions.append(removeAction)

        let cell = tableView.cellForRow(at: indexPath)
        actions.append(getShareAction(site: site, sourceView: cell ?? self.view, delegate: bookmarkCoordinatorDelegate))

        return actions
    }
}

// MARK: - Toolbar button actions
extension BookmarksViewController {
    func bottomLeftButtonAction() {
        if state == .bookmarks(state: .inFolderEditMode) {
            guard let bookmarkFolder = viewModel.bookmarkFolder else { return }

            bookmarkCoordinatorDelegate?.showBookmarkDetail(
                bookmarkType: .folder,
                parentBookmarkFolder: bookmarkFolder
            )
        }
    }

    func handleLeftTopButton() {
        // We use the isTransitioning so that the "<" back toolbar navigation button cannot be spammed
        isTransitioning = true
    }

    func handleRightTopButton() {
        // When the Done button is tapped and search is active, exit search mode
        if state == .bookmarks(state: .search) {
            exitSearchState()
        }
    }

    func shouldDismissOnDone() -> Bool {
        guard state != .bookmarks(state: .itemEditMode),
              state != .bookmarks(state: .search) else { return false }

        return true
    }

    func bottomSearchButtonAction() {
        startSearchState()
    }

    func bottomRightButtonAction() {
        guard case .bookmarks(let subState) = state else { return }

        switch subState {
        case .mainView, .inFolder:
            // Set editing false first to hide any swipe actions that may already be showing
            tableView.setEditing(false, animated: true)
            enableEditMode()
        case .inFolderEditMode:
            disableEditMode()
        default:
            return
        }
    }
}

// MARK: - UISearchBarDelegate
extension BookmarksViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }

        performSearch(term: searchText)
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            handleEmptySearch()
            return
        }

        performSearch(term: searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        exitSearchState()
        sendPanelChangeNotification()
    }

    func startSearchState() {
        updatePanelState(newState: .bookmarks(state: .search))
        updateBottomSearchBarLayout(isHidden: false)
        searchbar.becomeFirstResponder()
        sendPanelChangeNotification()
    }

    func exitSearchState() {
        resetSearch()

        searchbar.text = ""
        searchbar.resignFirstResponder()
        updateBottomSearchBarLayout(isHidden: true)

        // Transition back to non-searching state
        updatePanelState(newState: viewModel.isRootNode
                                   ? .bookmarks(state: .mainView)
                                   : .bookmarks(state: .inFolder))
        updateEmptyState(animated: true)
    }

    func performSearch(term: String) {
        viewModel.searchBookmarks(query: term) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func handleEmptySearch() {
        resetSearch()
    }
}

// MARK: - KeyboardHelperDelegate
extension BookmarksViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        keyboardState = state
        updateLayoutForKeyboard()
        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))],
            animations: {
                self.bottomStackView.layoutIfNeeded()
            })
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = nil
        updateLayoutForKeyboard()
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {}
}
