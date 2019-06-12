/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

private let BookmarkNodeCellIdentifier = "BookmarkNodeCellIdentifier"
private let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorCellIdentifier"

private struct BookmarksPanelUX {
    static let FolderIconSize = CGSize(width: 20, height: 20)
    static let RowFlashDelay: TimeInterval = 0.4
}

let LocalizedRootBookmarkFolderStrings = [
    BookmarkRoots.MenuFolderGUID: Strings.BookmarksFolderTitleMenu,
    BookmarkRoots.ToolbarFolderGUID: Strings.BookmarksFolderTitleToolbar,
    BookmarkRoots.UnfiledFolderGUID: Strings.BookmarksFolderTitleUnsorted,
    BookmarkRoots.MobileFolderGUID: Strings.BookmarksFolderTitleMobile
]

fileprivate class SeparatorTableViewCell: OneLineTableViewCell {
    override func applyTheme() {
        super.applyTheme()

        backgroundColor = UIColor.theme.tableView.headerBackground
    }
}

class BookmarksPanel: SiteTableViewController, LibraryPanel {
    enum BookmarksSection: Int, CaseIterable {
        case bookmarks
        case recent
    }

    var libraryPanelDelegate: LibraryPanelDelegate?

    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
    }()

    let bookmarkFolderGUID: GUID

    var editBarButtonItem: UIBarButtonItem!
    var doneBarButtonItem: UIBarButtonItem!
    var newBarButtonItem: UIBarButtonItem!

    var bookmarkFolder: BookmarkFolder?
    var bookmarkNodes = [BookmarkNode]()
    var recentBookmarks = [BookmarkNode]()

    fileprivate var flashLastRowOnNextReload = false

    init(profile: Profile, bookmarkFolderGUID: GUID = BookmarkRoots.RootGUID) {
        self.bookmarkFolderGUID = bookmarkFolderGUID

        super.init(profile: profile)

        [ Notification.Name.FirefoxAccountChanged,
          Notification.Name.DynamicFontChanged ].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: $0, object: nil)
        }

        self.tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: BookmarkNodeCellIdentifier)
        self.tableView.register(SeparatorTableViewCell.self, forCellReuseIdentifier: BookmarkSeparatorCellIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.accessibilityIdentifier = "Bookmarks List"
        tableView.allowsSelectionDuringEditing = true

        self.editBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit) { _ in
            self.tableView.setEditing(true, animated: true)
            self.navigationItem.leftBarButtonItem = self.newBarButtonItem
            self.navigationItem.rightBarButtonItem = self.doneBarButtonItem
        }

        self.doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done) { _ in
            self.tableView.setEditing(false, animated: true)
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = self.editBarButtonItem
        }

        self.newBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add) { _ in
            let newBookmark = PhotonActionSheetItem(title: Strings.BookmarksNewBookmark, iconString: "action_bookmark", handler: { action in
                guard let bookmarkFolder = self.bookmarkFolder else {
                    return
                }

                let detailController = BookmarkDetailPanel(profile: self.profile, withNewBookmarkNodeType: .bookmark, parentBookmarkFolder: bookmarkFolder)
                self.navigationController?.pushViewController(detailController, animated: true)
            })

            let newFolder = PhotonActionSheetItem(title: Strings.BookmarksNewFolder, iconString: "bookmarkFolder", handler: { action in
                guard let bookmarkFolder = self.bookmarkFolder else {
                    return
                }

                let detailController = BookmarkDetailPanel(profile: self.profile, withNewBookmarkNodeType: .folder, parentBookmarkFolder: bookmarkFolder)
                self.navigationController?.pushViewController(detailController, animated: true)
            })

            let newSeparator = PhotonActionSheetItem(title: Strings.BookmarksNewSeparator, iconString: "nav-menu", handler: { action in
                let centerVisibleRow = self.centerVisibleRow()

                self.profile.places.createSeparator(parentGUID: self.bookmarkFolderGUID, position: UInt32(centerVisibleRow)) >>== { guid in
                    self.profile.places.getBookmark(guid: guid).uponQueue(.main) { result in
                        guard let bookmarkNode = result.successValue, let bookmarkSeparator = bookmarkNode as? BookmarkSeparator else {
                            return
                        }

                        let indexPath = IndexPath(row: centerVisibleRow, section: BookmarksSection.bookmarks.rawValue)
                        self.tableView.beginUpdates()
                        self.bookmarkNodes.insert(bookmarkSeparator, at: centerVisibleRow)
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                        self.tableView.endUpdates()

                        self.flashRow(at: indexPath)
                    }
                }
            })

            let sheet = PhotonActionSheet(actions: [[newBookmark, newFolder, newSeparator]])
            sheet.modalPresentationStyle = .overFullScreen
            sheet.modalTransitionStyle = .crossDissolve
            self.present(sheet, animated: true)
        }

        if bookmarkFolderGUID != BookmarkRoots.RootGUID {
            navigationItem.rightBarButtonItem = editBarButtonItem
        }
    }

    override func applyTheme() {
        super.applyTheme()

        if let current = navigationController?.visibleViewController as? Themeable, current !== self {
            current.applyTheme()
        }
    }

    override func reloadData() {
        profile.places.getBookmarksTree(rootGUID: bookmarkFolderGUID, recursive: false).uponQueue(.main) { result in

            guard let folder = result.successValue as? BookmarkFolder else {
                // TODO: Handle error case?
                self.bookmarkFolder = nil
                self.bookmarkNodes = []
                self.recentBookmarks = []
                return
            }

            self.bookmarkFolder = folder
            self.bookmarkNodes = folder.children ?? []

            if folder.guid == BookmarkRoots.RootGUID {
                self.profile.places.getRecentBookmarks(limit: 20).uponQueue(.main) { result in
                    self.recentBookmarks = result.successValue ?? []
                    self.tableView.reloadData()
                }
            } else {
                self.recentBookmarks = []
                self.tableView.reloadData()
            }

            if self.flashLastRowOnNextReload {
                self.flashLastRowOnNextReload = false

                let lastIndexPath = IndexPath(row: self.bookmarkNodes.count - 1, section: BookmarksSection.bookmarks.rawValue)
                DispatchQueue.main.asyncAfter(deadline: .now() + BookmarksPanelUX.RowFlashDelay) {
                    self.flashRow(at: lastIndexPath)
                }
            }
        }
    }

    fileprivate func centerVisibleRow() -> Int {
        let visibleCells = tableView.visibleCells
        if let middleCell = visibleCells[safe: visibleCells.count / 2],
            let middleIndexPath = tableView.indexPath(for: middleCell) {
            return middleIndexPath.row
        }

        return bookmarkNodes.count
    }

    fileprivate func deleteBookmarkNodeAtIndexPath(_ indexPath: IndexPath) {
        guard let bookmarkNode = indexPath.section == BookmarksSection.bookmarks.rawValue ? bookmarkNodes[safe: indexPath.row] : recentBookmarks[safe: indexPath.row] else {
            return
        }

        func doDelete() {
            // Perform the delete asynchronously even though we update the
            // table view data source immediately for responsiveness.
            _ = profile.places.deleteBookmarkNode(guid: bookmarkNode.guid)

            tableView.beginUpdates()
            if indexPath.section == BookmarksSection.recent.rawValue {
                recentBookmarks.remove(at: indexPath.row)
            } else {
                bookmarkNodes.remove(at: indexPath.row)
            }
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.endUpdates()
        }

        // If this node is a folder and it is not empty, we need
        // to prompt the user before deleting.
        if let bookmarkFolder = bookmarkNode as? BookmarkFolder,
            !bookmarkFolder.childGUIDs.isEmpty {
            let alertController = UIAlertController(title: Strings.BookmarksDeleteFolderWarningTitle, message: Strings.BookmarksDeleteFolderWarningDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: Strings.BookmarksDeleteFolderCancelButtonLabel, style: .cancel))
            alertController.addAction(UIAlertAction(title: Strings.BookmarksDeleteFolderDeleteButtonLabel, style: .destructive) { (action) in
                doDelete()
            })
            present(alertController, animated: true, completion: nil)
            return
        }

        doDelete()
    }

    fileprivate func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        return indexPath.section < numberOfSections(in: tableView) &&
            indexPath.row < tableView(tableView, numberOfRowsInSection: indexPath.section)
    }

    fileprivate func flashRow(at indexPath: IndexPath) {
        guard indexPathIsValid(indexPath) else {
            return
        }

        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)

        DispatchQueue.main.asyncAfter(deadline: .now() + BookmarksPanelUX.RowFlashDelay) {
            if self.indexPathIsValid(indexPath) {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    func didAddBookmarkNode() {
        flashLastRowOnNextReload = true
    }

    @objc fileprivate func didLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard longPressGestureRecognizer.state == .began, let indexPath = tableView.indexPathForRow(at: touchPoint) else {
            return
        }

        presentContextMenu(for: indexPath)
    }

    @objc fileprivate func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .DynamicFontChanged:
            reloadData()
        default:
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    // MARK: UITableViewDataSource | UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let node: BookmarkNode?

        if indexPath.section == BookmarksSection.recent.rawValue {
            node = recentBookmarks[safe: indexPath.row]
        } else {
            node = bookmarkNodes[safe: indexPath.row]
        }

        guard let bookmarkNode = node else {
            return
        }

        guard !tableView.isEditing else {
            if let bookmarkFolder = self.bookmarkFolder, !(bookmarkNode is BookmarkSeparator) {
                let detailController = BookmarkDetailPanel(profile: profile, bookmarkNode: bookmarkNode, parentBookmarkFolder: bookmarkFolder)
                navigationController?.pushViewController(detailController, animated: true)
            }
            return
        }

        switch bookmarkNode {
        case let bookmarkFolder as BookmarkFolder:
            let nextController = BookmarksPanel(profile: profile, bookmarkFolderGUID: bookmarkFolder.guid)
            if bookmarkFolder.isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[bookmarkFolder.guid] {
                nextController.title = localizedString
            } else {
                nextController.title = bookmarkFolder.title
            }
            nextController.libraryPanelDelegate = libraryPanelDelegate
            navigationController?.pushViewController(nextController, animated: true)
        case let bookmarkItem as BookmarkItem:
            libraryPanelDelegate?.libraryPanel(didSelectURLString: bookmarkItem.url, visitType: .bookmark)
            LeanPlumClient.shared.track(event: .openedBookmark)
            UnifiedTelemetry.recordEvent(category: .action, method: .open, object: .bookmark, value: .bookmarksPanel)
        default:
            return // Likely a separator was selected so do nothing.
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == BookmarksSection.recent.rawValue ? recentBookmarks.count : bookmarkNodes.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if let folder = bookmarkFolder, folder.guid == BookmarkRoots.RootGUID {
            return 2
        }

        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let bookmarkNode = indexPath.section == BookmarksSection.recent.rawValue ? recentBookmarks[safe: indexPath.row] : bookmarkNodes[safe: indexPath.row] else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        switch bookmarkNode {
        case let bookmarkFolder as BookmarkFolder:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkNodeCellIdentifier, for: indexPath)
            if bookmarkFolder.isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[bookmarkFolder.guid] {
                cell.textLabel?.text = localizedString
            } else {
                cell.textLabel?.text = bookmarkFolder.title
            }

            cell.imageView?.image = UIImage(named: "bookmarkFolder")?.createScaled(BookmarksPanelUX.FolderIconSize)
            cell.imageView?.contentMode = .center
            cell.accessoryType = .disclosureIndicator
            cell.editingAccessoryType = .disclosureIndicator
            return cell
        case let bookmarkItem as BookmarkItem:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkNodeCellIdentifier, for: indexPath)
            if bookmarkItem.title.isEmpty {
                cell.textLabel?.text = bookmarkItem.url
            } else {
                cell.textLabel?.text = bookmarkItem.title
            }

            let site = Site(url: bookmarkItem.url, title: bookmarkItem.title, bookmarked: true, guid: bookmarkItem.guid)
            profile.favicons.getFaviconImage(forSite: site).uponQueue(.main) { result in
                // Check that we successfully retrieved an image (should always happen)
                // and ensure that the cell we were fetching for is still on-screen.
                guard let image = result.successValue, let cell = tableView.cellForRow(at: indexPath) else {
                    return
                }

                cell.imageView?.image = image
                cell.imageView?.contentMode = .scaleAspectFill
                cell.setNeedsLayout()
            }

            cell.accessoryType = .none
            cell.editingAccessoryType = .disclosureIndicator
            return cell
        case is BookmarkSeparator:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkSeparatorCellIdentifier, for: indexPath)
            return cell
        default:
            return super.tableView(tableView, cellForRowAt: indexPath) // Should not happen.
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == BookmarksSection.recent.rawValue, !recentBookmarks.isEmpty else {
            return nil
        }

        return super.tableView(tableView, viewForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == BookmarksSection.recent.rawValue ? Strings.RecentlyBookmarkedTitle : nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == BookmarksSection.recent.rawValue ? UITableView.automaticDimension : 0
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Root folders cannot be edited.
        guard let bookmarkFolder = self.bookmarkFolder, bookmarkFolder.guid != BookmarkRoots.RootGUID else {
            // Allow delete of recent BMs
            return indexPath.section == BookmarksSection.recent.rawValue
        }

        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Root folders cannot be moved.
        guard let bookmarkFolder = self.bookmarkFolder, bookmarkFolder.guid != BookmarkRoots.RootGUID else {
            return false
        }

        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let bookmarkNode = bookmarkNodes[safe: sourceIndexPath.row] else {
            return
        }

        _ = profile.places.updateBookmarkNode(guid: bookmarkNode.guid, position: UInt32(destinationIndexPath.row))

        bookmarkNodes.remove(at: sourceIndexPath.row)
        bookmarkNodes.insert(bookmarkNode, at: destinationIndexPath.row)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: Strings.BookmarksPanelDeleteTableAction, handler: { (action, indexPath) in
            self.deleteBookmarkNodeAtIndexPath(indexPath)
            UnifiedTelemetry.recordEvent(category: .action, method: .delete, object: .bookmark, value: .bookmarksPanel, extras: ["gesture": "swipe"])
        })

        return [delete]
    }
}

// MARK: LibraryPanelContextMenu

extension BookmarksPanel: LibraryPanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else {
            return
        }

        present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let bookmarkNode = indexPath.section == BookmarksSection.recent.rawValue ? recentBookmarks[safe: indexPath.row] : bookmarkNodes[safe: indexPath.row],
            let bookmarkItem = bookmarkNode as? BookmarkItem else {
            return nil
        }

        return Site(url: bookmarkItem.url, title: bookmarkItem.title, bookmarked: true, guid: bookmarkItem.guid)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard var actions = getDefaultContextMenuActions(for: site, libraryPanelDelegate: libraryPanelDelegate) else {
            return nil
        }

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { action in
            _ = self.profile.history.addPinnedTopSite(site)
        })
        actions.append(pinTopSite)

        let removeAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { action in
            self.deleteBookmarkNodeAtIndexPath(indexPath)
            UnifiedTelemetry.recordEvent(category: .action, method: .delete, object: .bookmark, value: .bookmarksPanel, extras: ["gesture": "long-press"])
        })
        actions.append(removeAction)

        return actions
    }
}
