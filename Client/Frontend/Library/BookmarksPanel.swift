/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

private let BookmarkFolderCellIdentifier = "BookmarkFolderCellIdentifier"
private let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorCellIdentifier"

private struct BookmarksPanelUX {
    static let BookmarkFolderHeaderViewChevronInset: CGFloat = 10
    static let BookmarkFolderChevronSize: CGFloat = 20
    static let BookmarkFolderChevronLineWidth: CGFloat = 2.0
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenItemWidth = 170
    static let SeparatorRowHeight: CGFloat = 0.5
    static let IconSize: CGFloat = 23
    static let IconBorderWidth: CGFloat = 0.5
}

private let LocalizedRootFolderStrings = [
    BookmarkRoots.MenuFolderGUID: Strings.BookmarksFolderTitleMenu,
    BookmarkRoots.ToolbarFolderGUID: Strings.BookmarksFolderTitleToolbar,
    BookmarkRoots.UnfiledFolderGUID: Strings.BookmarksFolderTitleUnsorted,
    BookmarkRoots.MobileFolderGUID: Strings.BookmarksFolderTitleMobile
]

fileprivate class BookmarkFolderTableViewCell: TwoLineTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        imageView?.image = UIImage(named: "bookmarkFolder")
        accessoryType = .disclosureIndicator
        separatorInset = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func applyTheme() {
        super.applyTheme()

        backgroundColor = UIColor.theme.homePanel.bookmarkFolderBackground
        textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        textLabel?.backgroundColor = UIColor.clear
        textLabel?.textColor = UIColor.theme.homePanel.bookmarkFolderText
    }
}

@objcMembers
class BookmarksPanel: SiteTableViewController, LibraryPanel {
    var libraryPanelDelegate: LibraryPanelDelegate?

    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
    }()

    let bookmarkFolderGUID: GUID

    var bookmarkFolder: BookmarkFolder?
    var bookmarkNodes = [BookmarkNode]()

    init(profile: Profile, bookmarkFolderGUID: GUID = BookmarkRoots.RootGUID) {
        self.bookmarkFolderGUID = bookmarkFolderGUID

        super.init(profile: profile)

        [ Notification.Name.FirefoxAccountChanged,
          Notification.Name.DynamicFontChanged ].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: $0, object: nil)
        }

        self.tableView.register(SeparatorTableCell.self, forCellReuseIdentifier: BookmarkSeparatorCellIdentifier)
        self.tableView.register(BookmarkFolderTableViewCell.self, forCellReuseIdentifier: BookmarkFolderCellIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.accessibilityIdentifier = "Bookmarks List"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done) { _ in
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadData()
    }

    override func applyTheme() {
        super.applyTheme()
    }

    override func reloadData() {
        loadData()
    }

    fileprivate func loadData() {
        profile.places.getBookmarksTree(rootGUID: bookmarkFolderGUID, recursive: false).uponQueue(.main) { result in

            guard let folder = result.successValue as? BookmarkFolder else {
                // TODO: Handle error case?
                self.bookmarkFolder = nil
                self.bookmarkNodes = []
                self.tableView.reloadData()
                return
            }

            self.bookmarkFolder = folder
            self.bookmarkNodes = folder.children ?? []
            self.tableView.reloadData()
        }
    }

    fileprivate func deleteBookmarkNodeAtIndexPath(_ indexPath: IndexPath) {
        guard let bookmarkNode = bookmarkNodes[safe: indexPath.row] else {
            return
        }

        func doDelete() {
            // Perform the delete asynchronously even though we update the
            // table view data source immediately for responsiveness.
            _ = profile.places.deleteBookmarkNode(guid: bookmarkNode.guid)

            tableView.beginUpdates()
            bookmarkNodes.remove(at: indexPath.row)
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
        guard let bookmarkNode = bookmarkNodes[safe: indexPath.row] else {
            return
        }

        switch bookmarkNode {
        case let bookmarkFolder as BookmarkFolder:
            let nextController = BookmarksPanel(profile: profile, bookmarkFolderGUID: bookmarkFolder.guid)
            if bookmarkFolder.isRoot, let localizedString = LocalizedRootFolderStrings[bookmarkFolder.guid] {
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
        return bookmarkNodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let bookmarkNode = bookmarkNodes[safe: indexPath.row] else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        switch bookmarkNode {
        case let bookmarkFolder as BookmarkFolder:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkFolderCellIdentifier, for: indexPath)
            if bookmarkFolder.isRoot, let localizedString = LocalizedRootFolderStrings[bookmarkFolder.guid] {
                cell.textLabel?.text = localizedString
            } else {
                cell.textLabel?.text = bookmarkFolder.title
            }
            return cell
        case let bookmarkItem as BookmarkItem:
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
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
                cell.setNeedsLayout()
            }

            return cell
        case is BookmarkSeparator:
            return tableView.dequeueReusableCell(withIdentifier: BookmarkSeparatorCellIdentifier, for: indexPath)
        default:
            return super.tableView(tableView, cellForRowAt: indexPath) // Should not happen.
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if bookmarkNodes[safe: indexPath.row] is BookmarkSeparator {
            return BookmarksPanelUX.SeparatorRowHeight
        }

        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        // Show a full-width border for cells above separators, so they don't have a weird step.
        // Separators themselves already have a full-width border, but let's force the issue
        // just in case.
        let thisBookmarkNode = bookmarkNodes[safe: indexPath.row]
        let nextBookmarkNode = bookmarkNodes[safe: indexPath.row + 1]
        if thisBookmarkNode is BookmarkSeparator || nextBookmarkNode is BookmarkSeparator {
            return true
        }

        return super.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // The only nodes that cannot be deleted are the root folders.
        guard let bookmarkFolder = self.bookmarkFolder, bookmarkFolder.guid != BookmarkRoots.RootGUID else {
            return false
        }

        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if bookmarkNodes[safe: indexPath.row] is BookmarkSeparator {
            return .none
        }

        return .delete
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if bookmarkNodes[safe: indexPath.row] is BookmarkSeparator {
            return nil
        }

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
        guard let bookmarkItem = bookmarkNodes[safe: indexPath.row] as? BookmarkItem else {
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
