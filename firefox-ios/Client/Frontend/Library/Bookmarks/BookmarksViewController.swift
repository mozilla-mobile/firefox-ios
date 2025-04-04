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
                               UITableViewDropDelegate {
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
    let viewModel: BookmarksPanelViewModel
    var bookmarksSaver: BookmarksSaver?
    private var logger: Logger
    private let bookmarksTelemetry = BookmarksTelemetry()

    // MARK: - Toolbar items
    var bottomToolbarItems: [UIBarButtonItem] {
        // Return empty toolbar when bookmarks is in desktop folder node
        guard case .bookmarks = state,
              viewModel.bookmarkFolderGUID != LocalDesktopFolder.localDesktopFolderGuid
        else { return [UIBarButtonItem]() }

        return toolbarButtonItems
    }

    private var toolbarButtonItems: [UIBarButtonItem] {
        switch state {
        case .bookmarks(state: .mainView), .bookmarks(state: .inFolder):
            bottomRightButton.title = .BookmarksEdit
            return [flexibleSpace, bottomRightButton]
        case .bookmarks(state: .inFolderEditMode):
            bottomRightButton.title = String.AppSettingsDone
            return [bottomLeftButton, flexibleSpace, bottomRightButton]
        case .bookmarks(state: .itemEditMode):
            bottomRightButton.title = String.AppSettingsDone
            bottomRightButton.isEnabled = true
            return [flexibleSpace, bottomRightButton]
        case .bookmarks(state: .itemEditModeInvalidField):
            bottomRightButton.title = String.AppSettingsDone
            bottomRightButton.isEnabled = false
            return [flexibleSpace, bottomRightButton]
        default:
            return [UIBarButtonItem]()
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

    private lazy var emptyStateView: BookmarksFolderEmptyStateView = .build { emptyStateView in
        emptyStateView.signInAction = { [weak self] in
            self?.bookmarkCoordinatorDelegate?.showSignIn()
        }
    }

    private lazy var a11yEmptyStateScrollView: UIScrollView = .build()

    // MARK: - Init

    init(viewModel: BookmarksPanelViewModel,
         windowUUID: WindowUUID,
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = viewModel
        self.logger = logger

        let guidMatches = viewModel.bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID
        self.state = guidMatches ? .bookmarks(state: .mainView) : .bookmarks(state: .inFolder)
        self.bookmarksHandler = viewModel.profile.places
        super.init(profile: viewModel.profile, windowUUID: windowUUID)

        bookmarksSaver = DefaultBookmarksSaver(profile: profile)

        setupNotifications(forObserver: self, observing: [.FirefoxAccountChanged, .ProfileDidFinishSyncing])

        tableView.register(cellType: OneLineTableViewCell.self)
        tableView.register(cellType: SeparatorTableViewCell.self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)

        // FXIOS-11315: Necessary to prevent BookmarksFolderEmptyStateView from being retained in memory
        a11yEmptyStateScrollView.removeFromSuperview()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableViewLongPressRecognizer = UILongPressGestureRecognizer(target: self,
                                                                        action: #selector(didLongPressTableView))
        tableView.addGestureRecognizer(tableViewLongPressRecognizer)
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.tableView
        tableView.allowsSelectionDuringEditing = true
        tableView.dragInteractionEnabled = false
        tableView.dragDelegate = self
        tableView.dropDelegate = self

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

        if tableView.isEditing {
            updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        } else if viewModel.isRootNode {
            updatePanelState(newState: .bookmarks(state: .mainView))
        } else {
            updatePanelState(newState: .bookmarks(state: .inFolder))
        }
        sendPanelChangeNotification()
    }

    // MARK: - Data

    override func reloadData() {
        viewModel.reloadData { [weak self] in
            ensureMainThread {
                self?.tableView.reloadData()
                if self?.viewModel.shouldFlashRow ?? false {
                    self?.flashRow()
                }
                self?.updateEmptyState(animated: false)
                self?.updateParentViewControllerTitle()
            }
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

        return viewModel.bookmarkNodes.count
    }

    private func deleteBookmarkNodeAtIndexPath(_ indexPath: IndexPath) {
        guard let bookmarkNode = viewModel.bookmarkNodes[safe: indexPath.row]else {
            return
        }

        // If this node is a folder and it is not empty, we need
        // to prompt the user before deleting.
        if bookmarkNode.isNonEmptyFolder {
            presentDeletingActionToUser(indexPath, bookmarkNode: bookmarkNode)
            return
        } else if bookmarkNode.type == .separator {
            deleteBookmarkNode(indexPath, bookmarkNode: bookmarkNode)
            return
        }

        deleteBookmarkWithUndo(indexPath: indexPath, bookmarkNode: bookmarkNode)
    }

    private func restoreBookmarkTree(bookmarkTreeRoot: BookmarkNodeData,
                                     parentFolderGUID: String,
                                     recentBookmarkFolderGUID: String?,
                                     completion: ((GUID) -> Void)? = nil) {
        guard bookmarkTreeRoot.type == .folder || bookmarkTreeRoot.type == .bookmark else { return }
        bookmarksSaver?.restoreBookmarkNode(bookmarkNode: bookmarkTreeRoot, parentFolderGUID: parentFolderGUID) { res in
            guard let guid = res else {return}
            completion?(guid)

            if recentBookmarkFolderGUID != nil && recentBookmarkFolderGUID == bookmarkTreeRoot.guid {
                self.profile.prefs.setString(guid, forKey: PrefsKeys.RecentBookmarkFolder)
            }

            // In the case that the node is a folder, restore its children as well
            guard let children = (bookmarkTreeRoot as? BookmarkFolderData)?.children else { return }

            for child in children {
                self.restoreBookmarkTree(bookmarkTreeRoot: child,
                                         parentFolderGUID: guid,
                                         recentBookmarkFolderGUID: recentBookmarkFolderGUID)
            }
        }
    }

    private func presentDeletingActionToUser(_ indexPath: IndexPath, bookmarkNode: FxBookmarkNode) {
        let alertController = UIAlertController(title: .BookmarksDeleteFolderWarningTitle,
                                                message: .BookmarksDeleteFolderWarningDescription,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: .BookmarksDeleteFolderCancelButtonLabel,
                                                style: .default))
        alertController.addAction(UIAlertAction(title: .BookmarksDeleteFolderDeleteButtonLabel,
                                                style: .destructive) { [weak self] action in
            self?.deleteBookmarkWithUndo(indexPath: indexPath, bookmarkNode: bookmarkNode)
        })
        present(alertController, animated: true, completion: nil)
    }

    private func deleteBookmarkWithUndo(indexPath: IndexPath,
                                        bookmarkNode: FxBookmarkNode) {
        profile.places.getBookmarksTree(rootGUID: bookmarkNode.guid, recursive: true).uponQueue(.main) { result in
            guard let maybeBookmarkTreeRoot = result.successValue,
                  let bookmarkTreeRoot = maybeBookmarkTreeRoot else { return }

            let recentBookmarkFolderGUID = self.profile.prefs.stringForKey(PrefsKeys.RecentBookmarkFolder)

            self.deleteBookmarkNode(indexPath, bookmarkNode: bookmarkNode)

            let toastVM = ButtonToastViewModel(
                labelText: String(format: .Bookmarks.Menu.DeletedBookmark, bookmarkNode.title),
                buttonText: .UndoString)
            let toast = ButtonToast(viewModel: toastVM,
                                    theme: self.currentTheme(),
                                    completion: { buttonPressed in
                guard buttonPressed, let parentGUID = bookmarkTreeRoot.parentGUID else { return }
                self.restoreBookmarkTree(bookmarkTreeRoot: bookmarkTreeRoot,
                                         parentFolderGUID: parentGUID,
                                         recentBookmarkFolderGUID: recentBookmarkFolderGUID) { guid in
                    self.profile.places.getBookmark(guid: guid).uponQueue(.main) { result in
                        guard let newBookmarkNode = result.successValue ?? nil,
                              let fxBookmarkNode = newBookmarkNode as? FxBookmarkNode else { return }
                        self.addBookmarkNodeToTable(bookmarkNode: fxBookmarkNode)
                    }
                }
            })
            toast.showToast(viewController: self, delay: UX.toastDelayBefore, duration: UX.toastDismissDelay) { toast in
                [
                    toast.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                                                   constant: Toast.UX.toastSidePadding),
                    toast.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                                                    constant: -Toast.UX.toastSidePadding),
                    toast.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
                ]
            }
        }
    }

    private func addBookmarkNodeToTable(bookmarkNode: FxBookmarkNode) {
        let position = Int(bookmarkNode.position)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: position, section: 0)], with: .left)
        viewModel.bookmarkNodes.insert(bookmarkNode, at: position)
        tableView.endUpdates()
        updateEmptyState(animated: false)
    }

    /// Performs the delete asynchronously even though we update the
    /// table view data source immediately for responsiveness.
    private func deleteBookmarkNode(_ indexPath: IndexPath, bookmarkNode: FxBookmarkNode) {
        profile.places.deleteBookmarkNode(guid: bookmarkNode.guid).uponQueue(.main) { _ in
            if let recentBookmarkFolderGuid = self.profile.prefs.stringForKey(PrefsKeys.RecentBookmarkFolder) {
                self.profile.places.getBookmark(guid: recentBookmarkFolderGuid).uponQueue(.main) { node in
                    guard let nodeValue = node.successValue, nodeValue == nil else { return }
                    self.profile.prefs.removeObjectForKey(PrefsKeys.RecentBookmarkFolder)
                }
            }
            self.removeBookmarkShortcut()
        }

        tableView.beginUpdates()
        viewModel.bookmarkNodes.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .left)
        tableView.endUpdates()
        updateEmptyState(animated: false)
    }

    // MARK: Button Actions helpers

    func enableEditMode() {
        updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        self.tableView.setEditing(true, animated: true)
        self.tableView.dragInteractionEnabled = true
        sendPanelChangeNotification()
        updateEmptyState(animated: true)
    }

    func disableEditMode() {
        let substate: LibraryPanelSubState = viewModel.isRootNode ? .mainView : .inFolder
        updatePanelState(newState: .bookmarks(state: substate))
        self.tableView.setEditing(false, animated: true)
        self.tableView.dragInteractionEnabled = false
        sendPanelChangeNotification()
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
        let lastIndexPath = IndexPath(row: viewModel.bookmarkNodes.count - 1,
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
        let showEmptyState = viewModel.bookmarkNodes.isEmpty && !tableView.isEditing

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

        emptyStateView.configure(isRoot: viewModel.bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID,
                                 isSignedIn: profile.hasAccount())
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

    private func backButtonView() -> UIView? {
        let navigationBarContentView = navigationController?.navigationBar.subviews.first(where: {
            $0.description.starts(with: "<_UINavigationBarContentView:")
        })

        return navigationBarContentView?.subviews.first(where: {
            $0.description.starts(with: "<_UIButtonBarButton:")
        })
    }

    // MARK: - UI Setup
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

        guard let node = viewModel.bookmarkNodes[safe: indexPath.row],
              let bookmarkCell = node as? BookmarksFolderCell
        else { return }

        guard !tableView.isEditing else {
            if let bookmarkFolder = self.viewModel.bookmarkFolder,
                !(node is BookmarkSeparatorData),
                isCurrentFolderEditable(at: indexPath) {
                // Only show detail controller for editable nodes
                bookmarkCoordinatorDelegate?.showBookmarkDetail(for: node, folder: bookmarkFolder, completion: nil)
            }
            return
        }

        updatePanelState(newState: .bookmarks(state: .inFolder))
        if let itemData = bookmarkCell as? BookmarkItemData,
           let url = URL(string: itemData.url, invalidCharacters: false) {
            libraryPanelDelegate?.libraryPanel(didSelectURL: url, visitType: .bookmark)
        } else {
            guard let folder = bookmarkCell as? FxBookmarkNode else { return }
            bookmarkCoordinatorDelegate?.start(from: folder)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.bookmarkNodes.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let node = viewModel.bookmarkNodes[safe: indexPath.row] else {
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
        return isCurrentFolderEditable(at: indexPath)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return isCurrentFolderEditable(at: indexPath)
    }

    /// Root folders and local desktop folder cannot be moved or edited
    private func isCurrentFolderEditable(at indexPath: IndexPath) -> Bool {
        guard let currentRowData = viewModel.bookmarkNodes[safe: indexPath.row] else {
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
            guard let strongSelf = self else { completion(false); return }

            strongSelf.deleteBookmarkNodeAtIndexPath(indexPath)
            strongSelf.bookmarksTelemetry.deleteBookmark(eventLabel: .bookmarksPanel)
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
              let destinationFolder = viewModel.bookmarkNodes[safe: destinationIndex],
              let sourceNode = viewModel.bookmarkNodes[safe: sourceIndex],
              destinationFolder.type == .folder,
              sourceNode.type == .bookmark || sourceNode.type == .folder,
              sourceNode.guid != destinationFolder.guid else {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UITableViewDropProposal(operation: .move, intent: .automatic)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items[safe: 0],
              let sourceIndexPath = item.dragItem.localObject as? IndexPath,
              let sourceItem = viewModel.bookmarkNodes[safe: sourceIndexPath.row],
              let destinationItem = viewModel.bookmarkNodes [safe: destinationIndexPath.row],
              coordinator.proposal.intent == .insertIntoDestinationIndexPath
        else { return }

        Task {
            let result = await bookmarksSaver?.save(bookmark: sourceItem,
                                                    parentFolderGUID: destinationItem.guid)
            switch result {
            case .success:
                Task { @MainActor in
                    tableView.beginUpdates()
                    viewModel.bookmarkNodes.remove(at: sourceIndexPath.row)
                    tableView.deleteRows(at: [sourceIndexPath], with: .left)
                    tableView.endUpdates()
                    updateEmptyState(animated: false)
                    profile.prefs.setString(destinationItem.guid, forKey: PrefsKeys.RecentBookmarkFolder)
                }
            default:
                return
            }
        }
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        updateEmptyState(animated: false)
    }
}

// MARK: - LibraryPanelContextMenu

extension BookmarksViewController: LibraryPanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        viewModel.getSiteDetails(for: indexPath) { [weak self] site in
            guard let self else { return }
            if let site {
                presentContextMenu(for: site, with: indexPath, completionHandler: {
                    return self.contextMenu(for: site, with: indexPath)
                })
            } else if let bookmarkNode = viewModel.bookmarkNodes[safe: indexPath.row],
                      bookmarkNode.type == .folder,
                      isCurrentFolderEditable(at: indexPath) {
                presentContextMenu(for: bookmarkNode, indexPath: indexPath)
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
            self.bookmarkCoordinatorDelegate?.showBookmarkDetail(for: folder, folder: parentFolder, completion: nil)
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
        let editBookmark = SingleActionViewModel(title: .Bookmarks.Menu.EditBookmark,
                                                 iconString: StandardImageIdentifiers.Large.edit,
                                                 tapHandler: { _ in
            guard let bookmarkNode = self.viewModel.bookmarkNodes[safe: indexPath.row],
                  let bookmarkFolder = self.viewModel.bookmarkFolder else {
                return
            }
            self.bookmarkCoordinatorDelegate?.showBookmarkDetail(for: bookmarkNode, folder: bookmarkFolder, completion: nil)
        }).items
        var actions: [PhotonRowActions] = [editBookmark] + defaultActions

        let pinTopSiteAction = viewModel.createPinUnpinAction(
            for: site,
            isPinned: site.isPinnedSite
        ) { [weak self] message in
            guard let view = self?.view, let theme = self?.currentTheme() else { return }
            SimpleToast().showAlertWithText(message, bottomContainer: view, theme: theme)
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

// MARK: - Notifiable
extension BookmarksViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .ProfileDidFinishSyncing:
            reloadData()
        default:
            break
        }
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
        // We use the "transitioning" so that the "<" back toolbar navigation button cannot be spammed
        updatePanelState(newState: .bookmarks(state: .transitioning))
    }

    func shouldDismissOnDone() -> Bool {
        guard state != .bookmarks(state: .itemEditMode) else { return false }

        return true
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
