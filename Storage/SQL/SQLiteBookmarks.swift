/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

private let log = Logger.syncLogger

private let desktopBookmarksLabel = NSLocalizedString("Desktop Bookmarks", tableName: "BookmarkPanel", comment: "The folder name for the virtual folder that contains all desktop bookmarks.")

func titleForSpecialGUID(guid: GUID) -> String? {
    switch guid {
    case BookmarkRoots.MobileFolderGUID:
        return BookmarksFolderTitleMobile
    case BookmarkRoots.ToolbarFolderGUID:
        return BookmarksFolderTitleToolbar
    case BookmarkRoots.MenuFolderGUID:
        return BookmarksFolderTitleMenu
    case BookmarkRoots.UnfiledFolderGUID:
        return BookmarksFolderTitleUnsorted
    default:
        return nil
    }
}

class SQLiteBookmarkFolder: BookmarkFolder {
    private let cursor: Cursor<BookmarkNode>
    override var count: Int {
        return cursor.count
    }

    override subscript(index: Int) -> BookmarkNode {
        let bookmark = cursor[index]
        if let item = bookmark as? BookmarkItem {
            return item
        }

        // TODO: this is fragile.
        return bookmark as! BookmarkFolder
    }

    init(guid: String, title: String, children: Cursor<BookmarkNode>) {
        self.cursor = children
        super.init(guid: guid, title: title)
    }
}

// Helps with managing rows from the current local bookmarks schema.
// The mirror schema is different, because it's shaped like the Sync object formats.
// This helper will change extensively -- probably going away entirely -- as we add
// bidirectional syncing support.
private class LocalBookmarkNodeFactory {
    private class func itemFactory(row: SDRow) -> BookmarkItem {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let url = row["url"] as! String
        let title = row["title"] as? String ?? url
        let bookmark = BookmarkItem(guid: guid, title: title, url: url)

        // TODO: share this logic with SQLiteHistory.
        if let faviconUrl = row["iconURL"] as? String,
            let date = row["iconDate"] as? Double,
            let faviconType = row["iconType"] as? Int {
                bookmark.favicon = Favicon(url: faviconUrl,
                    date: NSDate(timeIntervalSince1970: date),
                    type: IconType(rawValue: faviconType)!)
        }

        bookmark.id = id
        return bookmark
    }

    private class func folderFactory(row: SDRow) -> BookmarkFolder {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let title = titleForSpecialGUID(guid) ??
                    row["title"] as? String ??
                    SQLiteBookmarks.defaultFolderTitle

        let folder = BookmarkFolder(guid: guid, title: title)
        folder.id = id
        return folder
    }

    private class func nodeFactory(row: SDRow) -> BookmarkNode {
        let guid = row["guid"] as! String
        let title = row["title"] as? String ?? SQLiteBookmarks.defaultItemTitle
        return BookmarkNode(guid: guid, title: title)
    }

    class func factory(row: SDRow) -> BookmarkNode {
        if let typeCode = row["type"] as? Int, type = BookmarkNodeType(rawValue: typeCode) {
            switch type {
            case .Bookmark:
                return itemFactory(row)
            case .Folder:
                return folderFactory(row)
            case .DynamicContainer:
                fallthrough
            case .Separator:
                // TODO
                assert(false, "Separators not yet supported.")
            case .Livemark:
                // TODO
                assert(false, "Livemarks not yet supported.")
            case .Query:
                // TODO
                assert(false, "Queries not yet supported.")
            }
        }

        assert(false, "Invalid bookmark data.")
        return nodeFactory(row)
    }
}

private class MirrorBookmarkNodeFactory {
    private class func itemFactory(row: SDRow) -> BookmarkItem {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let url = row["bmkUri"] as! String
        let title = row["title"] as? String ?? url
        let bookmark = BookmarkItem(guid: guid, title: title, url: url)
        bookmark.id = id
        return bookmark
    }

    private class func folderFactory(row: SDRow) -> BookmarkFolder {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let title = titleForSpecialGUID(guid) ??
                    row["title"] as? String ??
                    SQLiteBookmarks.defaultFolderTitle

        let folder = BookmarkFolder(guid: guid, title: title)
        folder.id = id
        return folder
    }

    class func factory(row: SDRow) -> BookmarkNode {
        if let typeCode = row["type"] as? Int, type = BookmarkNodeType(rawValue: typeCode) {
            switch type {
            case .Bookmark:
                return itemFactory(row)
            case .Folder:
                return folderFactory(row)
            case .DynamicContainer:
                fallthrough
            case .Separator:
                // TODO
                assert(false, "Separators not yet supported.")
            case .Livemark:
                // TODO
                assert(false, "Livemarks not yet supported.")
            case .Query:
                // TODO
                assert(false, "Queries not yet supported.")
            }
        }

        assert(false, "Invalid bookmark data.")
        return LocalBookmarkNodeFactory.nodeFactory(row)
    }
}

public class SQLiteBookmarks: BookmarksModelFactory {
    let db: BrowserDB
    let favicons: FaviconsTable<Favicon>

    private static let defaultFolderTitle = NSLocalizedString("Untitled", tableName: "Storage", comment: "The default name for bookmark folders without titles.")
    private static let defaultItemTitle = NSLocalizedString("Untitled", tableName: "Storage", comment: "The default name for bookmark nodes without titles.")

    public init(db: BrowserDB) {
        self.db = db
        self.favicons = FaviconsTable<Favicon>()
    }

    private func getChildrenWhere(whereClause: String, args: Args, includeIcon: Bool) -> Cursor<BookmarkNode> {
        var err: NSError? = nil
        return db.withReadableConnection(&err) { (conn, err) -> Cursor<BookmarkNode> in
            let inner = "SELECT id, type, guid, url, title, faviconID FROM \(TableBookmarks) WHERE \(whereClause)"

            let sql: String
            if includeIcon {
                sql =
                "SELECT bookmarks.id AS id, bookmarks.type AS type, guid, bookmarks.url AS url, title, " +
                "favicons.url AS iconURL, favicons.date AS iconDate, favicons.type AS iconType " +
                "FROM (\(inner)) AS bookmarks " +
                "LEFT OUTER JOIN favicons ON bookmarks.faviconID = favicons.id"
            } else {
                sql = inner
            }

            return conn.executeQuery(sql, factory: LocalBookmarkNodeFactory.factory, withArgs: args)
        }
    }

    private func getRootChildren() -> Cursor<BookmarkNode> {
        let args: Args = [BookmarkRoots.RootID, BookmarkRoots.RootID]
        let sql = "parent = ? AND id IS NOT ?"
        return self.getChildrenWhere(sql, args: args, includeIcon: true)
    }

    private func getChildren(guid: String) -> Cursor<BookmarkNode> {
        let args: Args = [guid]
        let sql = "parent IS NOT NULL AND parent = (SELECT id FROM \(TableBookmarks) WHERE guid = ?)"
        return self.getChildrenWhere(sql, args: args, includeIcon: true)
    }

    func folderForGUID(guid: GUID, title: String) -> BookmarkFolder? {
        let children = getChildren(guid)
        if children.status == .Failure {
            log.warning("Couldn't get children: \(children.statusMessage).")
            return nil
        }

        return SQLiteBookmarkFolder(guid: guid, title: title, children: children)
    }

    public func modelForFolder(guid: String, title: String) -> Deferred<Maybe<BookmarksModel>> {
        guard let f = self.folderForGUID(guid, title: title) else {
            return deferMaybe(DatabaseError(description: "Couldn't get children."))
        }

        return deferMaybe(BookmarksModel(modelFactory: self, root: f))
    }

    public func modelForFolder(folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(folder.guid, title: folder.title)
    }

    public func modelForFolder(guid: String) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(guid, title: "")
    }

    public func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        let children = getRootChildren()
        if children.status == .Failure {
            return deferMaybe(DatabaseError(description: children.statusMessage))
        }
        let folder = SQLiteBookmarkFolder(guid: BookmarkRoots.RootGUID, title: "Root", children: children)
        return deferMaybe(BookmarksModel(modelFactory: self, root: folder))
    }

    public var nullModel: BookmarksModel {
        let children = Cursor<BookmarkNode>(status: .Failure, msg: "Null model")
        let folder = SQLiteBookmarkFolder(guid: "Null", title: "Null", children: children)
        return BookmarksModel(modelFactory: self, root: folder)
    }

    public func isBookmarked(url: String) -> Deferred<Maybe<Bool>> {
        var err: NSError?
        let sql = "SELECT id FROM \(TableBookmarks) WHERE url = ? LIMIT 1"
        let args: Args = [url]

        let c = db.withReadableConnection(&err) { (conn, err) -> Cursor<Int> in
            return conn.executeQuery(sql, factory: { $0["id"] as! Int }, withArgs: args)
        }

        if c.status == .Success {
            return deferMaybe(c.count > 0)
        }
        return deferMaybe(DatabaseError(err: err))
    }

    public func clearBookmarks() -> Success {
        return self.db.run([
            ("DELETE FROM \(TableBookmarks) WHERE parent IS NOT ?", [BookmarkRoots.RootID]),
            self.favicons.getCleanupCommands()
        ])
    }

    public func removeByURL(url: String) -> Success {
        return self.db.run([
            ("DELETE FROM \(TableBookmarks) WHERE url = ?", [url]),
        ])
    }

    public func remove(bookmark: BookmarkNode) -> Success {
        let sql: String
        let args: Args
        if let id = bookmark.id {
            sql = "DELETE FROM \(TableBookmarks) WHERE id = ?"
            args = [id]
        } else {
            sql = "DELETE FROM \(TableBookmarks) WHERE guid = ?"
            args = [bookmark.guid]
        }

        return self.db.run([
            (sql, args),
        ])
    }
}

extension SQLiteBookmarks: ShareToDestination {
    public func addToMobileBookmarks(url: NSURL, title: String, favicon: Favicon?) -> Success {
        var err: NSError?

        return self.db.withWritableConnection(&err) {  (conn, err) -> Success in
            func insertBookmark(icon: Int) -> Success {
                log.debug("Inserting bookmark with specified icon \(icon).")
                let urlString = url.absoluteString
                var args: Args = [
                    Bytes.generateGUID(),
                    BookmarkNodeType.Bookmark.rawValue,
                    urlString,
                    title,
                    BookmarkRoots.MobileID,
                ]

                // If the caller didn't provide an icon (and they usually don't!),
                // do a reverse lookup in history. We use a view to make this simple.
                let iconValue: String
                if icon == -1 {
                    iconValue = "(SELECT iconID FROM \(ViewIconForURL) WHERE url = ?)"
                    args.append(urlString)
                } else {
                    iconValue = "?"
                    args.append(icon)
                }

                let sql = "INSERT INTO \(TableBookmarks) (guid, type, url, title, parent, faviconID) VALUES (?, ?, ?, ?, ?, \(iconValue))"
                err = conn.executeChange(sql, withArgs: args)
                if let err = err {
                    log.error("Error inserting \(urlString). Got \(err).")
                    return deferMaybe(DatabaseError(err: err))
                }
                return succeed()
            }

            // Insert the favicon.
            if let icon = favicon {
                if let id = self.favicons.insertOrUpdate(conn, obj: icon) {
                	return insertBookmark(id)
                }
            }
            return insertBookmark(-1)
        }
    }

    public func shareItem(item: ShareItem) {
        // We parse here in anticipation of getting real URLs at some point.
        if let url = item.url.asURL {
            let title = item.title ?? url.absoluteString
            self.addToMobileBookmarks(url, title: title, favicon: item.favicon)
        }
    }
}

// At present this only searches local bookmarks.
// TODO: also search mirrored bookmarks.
extension SQLiteBookmarks: SearchableBookmarks {
    public func bookmarksByURL(url: NSURL) -> Deferred<Maybe<Cursor<BookmarkItem>>> {
        let inner = "SELECT id, type, guid, url, title, faviconID FROM \(TableBookmarks) WHERE type = \(BookmarkNodeType.Bookmark.rawValue) AND url = ?"
        let sql =
        "SELECT bookmarks.id AS id, bookmarks.type AS type, guid, bookmarks.url AS url, title, " +
        "favicons.url AS iconURL, favicons.date AS iconDate, favicons.type AS iconType " +
        "FROM (\(inner)) AS bookmarks " +
        "LEFT OUTER JOIN favicons ON bookmarks.faviconID = favicons.id"
        let args: Args = [url.absoluteString]
        return db.runQuery(sql, args: args, factory: LocalBookmarkNodeFactory.itemFactory)
    }
}

private extension BookmarkMirrorItem {
    func getChildrenArgs() -> [Args] {
        // Only folders have children, and we manage roots ourselves.
        if self.type != .Folder ||
           self.guid == BookmarkRoots.RootGUID {
            return []
        }
        let parent = self.guid
        var idx = 0
        return self.children?.map { child in
            let ret: Args = [parent, child, idx++]
            return ret
        } ?? []
    }

    func getUpdateOrInsertArgs() -> Args {
        let args: Args = [
            self.type.rawValue,
            NSNumber(unsignedLongLong: self.serverModified),
            self.isDeleted ? 1 : 0,
            self.hasDupe ? 1 : 0,
            self.parentID,
            self.parentName,
            self.feedURI,
            self.siteURI,
            self.pos,
            self.title,
            self.description,
            self.bookmarkURI,
            self.tags,
            self.keyword,
            self.folderName,
            self.queryID,
            self.guid,
        ]

        return args
    }
}

public class SQLiteBookmarkMirrorStorage: BookmarkMirrorStorage {
    private let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
    }

    /**
     * Remove child records for any folders that've been deleted or are empty.
     */
    private func deleteChildrenInTransactionWithGUIDs(guids: [GUID], connection: SQLiteDBConnection, withMaxVars maxVars: Int=BrowserDB.MaxVariableNumber) -> NSError? {
        log.debug("Deleting \(guids.count) parents from structure table.")
        let chunks = chunk(guids, by: maxVars)
        for chunk in chunks {
            let inList = Array<String>(count: chunk.count, repeatedValue: "?").joinWithSeparator(", ")
            let delStructure = "DELETE FROM \(TableBookmarksMirrorStructure) WHERE parent IN (\(inList))"

            let args: Args = chunk.flatMap { $0 as AnyObject }
            if let error = connection.executeChange(delStructure, withArgs: args) {
                log.error("Updating mirror structure: \(error.description).")
                return error
            }
        }
        return nil
    }

    /**
     * This is a little gnarly because our DB access layer is rough.
     * Within a single transaction, we walk the list of items, attempting to update
     * and inserting if the update failed. (TODO: batch the inserts!)
     * Once we've added all of the records, we flatten all of their children
     * into big arg lists and hard-update the structure table.
     */
    public func applyRecords(records: [BookmarkMirrorItem]) -> Success {
        return self.applyRecords(records, withMaxVars: BrowserDB.MaxVariableNumber)
    }

    public func applyRecords(records: [BookmarkMirrorItem], withMaxVars maxVars: Int) -> Success {
        let deferred = Deferred<Maybe<()>>(defaultQueue: dispatch_get_main_queue())

        let deleted = records.filter { $0.isDeleted }.map { $0.guid }
        let values = records.map { $0.getUpdateOrInsertArgs() }
        let children = records.filter { !$0.isDeleted }.flatMap { $0.getChildrenArgs() }
        let folders = records.filter { $0.type == BookmarkNodeType.Folder }.map { $0.guid }

        var err: NSError?
        self.db.transaction(&err) { (conn, err) -> Bool in
            // These have the same values in the same order.
            let update =
            "UPDATE \(TableBookmarksMirror) SET " +
            "type = ?, server_modified = ?, is_deleted = ?, " +
            "hasDupe = ?, parentid = ?, parentName = ?, " +
            "feedUri = ?, siteUri = ?, pos = ?, title = ?, " +
            "description = ?, bmkUri = ?, tags = ?, keyword = ?, " +
            "folderName = ?, queryId = ? " +
            "WHERE guid = ?"

            let insert =
            "INSERT OR IGNORE INTO \(TableBookmarksMirror) " +
            "(type, server_modified, is_deleted, hasDupe, parentid, parentName, " +
             "feedUri, siteUri, pos, title, description, bmkUri, tags, keyword, folderName, queryId, guid) " +
            "VALUES " +
            "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

            for args in values {
                if let error = conn.executeChange(update, withArgs: args) {
                    log.error("Updating mirror: \(error.description).")
                    err = error
                    deferred.fill(Maybe(failure: DatabaseError(err: error)))
                    return false
                }

                if conn.numberOfRowsModified > 0 {
                    continue
                }

                if let error = conn.executeChange(insert, withArgs: args) {
                    log.error("Inserting mirror: \(error.description).")
                    err = error
                    deferred.fill(Maybe(failure: DatabaseError(err: error)))
                    return false
                }
            }

            // Delete existing structure for any folders we've seen. We always trust the folders,
            // not the children's parent pointers, so we do this here: we'll insert their current
            // children right after, when we process the child structure rows.
            // We only drop the child structure for deleted folders, not the record itself.
            // Deleted records stay in the mirror table so that we know about the deletion
            // when we do a real sync!

            log.debug("\(folders.count) folders and \(deleted.count) deleted maybe-folders to drop from structure table.")

            if let error = self.deleteChildrenInTransactionWithGUIDs(folders + deleted, connection: conn) {
                deferred.fill(Maybe(failure: DatabaseError(err: error)))
                return false
            }

            // (Re-)insert children in chunks.
            log.debug("Inserting \(children.count) children.")
            if !children.isEmpty {
                // Insert the new structure rows. This uses three vars per row.
                let maxRowsPerInsert: Int = maxVars / 3
                let chunks = chunk(children, by: maxRowsPerInsert)
                for chunk in chunks {
                    log.verbose("Inserting \(chunk.count)…")
                    let childArgs: Args = chunk.flatMap { $0 }   // Flatten [[a, b, c], [...]] into [a, b, c, ...].
                    let ins = "INSERT INTO \(TableBookmarksMirrorStructure) (parent, child, idx) VALUES " +
                              Array<String>(count: chunk.count, repeatedValue: "(?, ?, ?)").joinWithSeparator(", ")
                    log.debug("Inserting \(chunk.count) records (out of \(children.count)).")
                    if let error = conn.executeChange(ins, withArgs: childArgs) {
                        log.error("Updating mirror structure: \(error.description).")
                        err = error
                        deferred.fill(Maybe(failure: DatabaseError(err: error)))
                        return false
                    }
                }
            }

            if err == nil {
                deferred.fillIfUnfilled(Maybe(success: ()))
                return true
            }

            deferred.fillIfUnfilled(Maybe(failure: DatabaseError(err: err)))
            return false
        }

        return deferred
    }

    public func doneApplyingRecordsAfterDownload() -> Success {
        self.db.checkpoint()
        return succeed()
    }
}

extension SQLiteBookmarkMirrorStorage: BookmarksModelFactory {
    private func getDesktopRoots() -> Deferred<Maybe<Cursor<BookmarkNode>>> {
        let args: Args = [BookmarkRoots.RootGUID]
        let folderType = BookmarkNodeType.Folder.rawValue
        let sql =
        "SELECT id, guid, type, title FROM \(TableBookmarksMirror) WHERE " +
        "parentid = ? AND " +
        "is_deleted = 0 AND " +
        "type = \(folderType) AND " +
        "title IS NOT '' " +
        "ORDER BY guid ASC"
        return self.db.runQuery(sql, args: args, factory: MirrorBookmarkNodeFactory.factory)
    }

    private func cursorForGUID(guid: GUID) -> Deferred<Maybe<Cursor<BookmarkNode>>> {
        let args: Args = [guid]
        let sql =
        "SELECT m.id AS id, m.guid AS guid, m.type AS type, m.bmkUri AS bmkUri, m.title AS title, " +
        "s.idx AS idx FROM " +
        "\(TableBookmarksMirror) AS m JOIN \(TableBookmarksMirrorStructure) AS s " +
        "ON s.child = m.guid " +
        "WHERE s.parent = ? AND " +
        "m.is_deleted = 0 AND " +
        "m.type <= 2 " +                // Bookmark or folder.
        "ORDER BY idx ASC"
        return self.db.runQuery(sql, args: args, factory: MirrorBookmarkNodeFactory.factory)
    }

    /**
     * Prepend the provided mobile bookmarks folder with a single folder.
     * The prepended folder is "Desktop Bookmarks". It contains mirrored folders.
     * We also *append* suggested sites.
     */
    public func extendWithDesktopBookmarksFolder(mobile: BookmarkFolder, factory: BookmarksModelFactory) -> Deferred<Maybe<BookmarksModel>> {

        return self.getDesktopRoots() >>== { cursor in
            if cursor.count == 0 {
                // No desktop bookmarks.
                log.debug("No desktop bookmarks. Only showing mobile.")
                return deferMaybe(BookmarksModel(modelFactory: factory, root: mobile))
            }

            let desktop = self.folderForDesktopBookmarksCursor(cursor)
            let prepended = PrependedBookmarkFolder(main: mobile, prepend: desktop)
            return deferMaybe(BookmarksModel(modelFactory: factory, root: prepended))
        }
    }

    private func modelForDesktopBookmarks() -> Deferred<Maybe<BookmarksModel>> {
        return self.getDesktopRoots() >>== { cursor in
            let desktop = self.folderForDesktopBookmarksCursor(cursor)
            return deferMaybe(BookmarksModel(modelFactory: self, root: desktop))
        }
    }

    private func folderForDesktopBookmarksCursor(cursor: Cursor<BookmarkNode>) -> SQLiteBookmarkFolder {
        return SQLiteBookmarkFolder(guid: BookmarkRoots.FakeDesktopFolderGUID, title: desktopBookmarksLabel, children: cursor)
    }

    private func modelForCursor(guid: GUID, title: String)(cursor: Cursor<BookmarkNode>) -> Deferred<Maybe<BookmarksModel>> {
        let folder = SQLiteBookmarkFolder(guid: guid, title: title, children: cursor)
        return deferMaybe(BookmarksModel(modelFactory: self, root: folder))
    }

    public func modelForFolder(folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(folder.guid, title: folder.title)
    }

    public func modelForFolder(guid: GUID) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(guid, title: "")
    }

    public func modelForFolder(guid: GUID, title: String) -> Deferred<Maybe<BookmarksModel>> {
        if guid == BookmarkRoots.FakeDesktopFolderGUID {
            return self.modelForDesktopBookmarks()
        }

        let outputTitle = titleForSpecialGUID(guid) ?? title
        return self.cursorForGUID(guid) >>== self.modelForCursor(guid, title: outputTitle)
    }

    public func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(BookmarkRoots.RootGUID)
    }

    public var nullModel: BookmarksModel {
        let children = Cursor<BookmarkNode>(status: .Failure, msg: "Null model")
        let folder = SQLiteBookmarkFolder(guid: "Null", title: "Null", children: children)
        return BookmarksModel(modelFactory: self, root: folder)
    }

    public func isBookmarked(url: String) -> Deferred<Maybe<Bool>> {
        return deferMaybe(false)        // TODO
    }

    public func remove(bookmark: BookmarkNode) -> Success {
        return deferMaybe(DatabaseError(description: "Can't remove records from the mirror."))
    }

    public func removeByURL(url: String) -> Success {
        return deferMaybe(DatabaseError(description: "Can't remove records from the mirror."))
    }

    public func clearBookmarks() -> Success {
        // This doesn't make sense for synced data just yet.
        log.debug("Mirror ignoring clearBookmarks.")
        return deferMaybe(DatabaseError(description: "Can't remove records from the mirror."))
    }

    // Used for resetting.
    public func wipeBookmarks() -> Success {
        return self.db.run("DELETE FROM \(TableBookmarksMirror)")
            >>> { self.db.run("DELETE FROM \(TableBookmarksMirrorStructure)") }
    }
}

public class MergedSQLiteBookmarks {
    let local: SQLiteBookmarks
    let mirror: SQLiteBookmarkMirrorStorage

    public init(db: BrowserDB) {
        self.local = SQLiteBookmarks(db: db)
        self.mirror = SQLiteBookmarkMirrorStorage(db: db)
    }
}

extension MergedSQLiteBookmarks: BookmarkMirrorStorage {
    public func applyRecords(records: [BookmarkMirrorItem]) -> Success {
        return self.mirror.applyRecords(records)
    }

    public func doneApplyingRecordsAfterDownload() -> Success {
        // It doesn't really matter which one we checkpoint -- they're both backed by the same DB.
        return self.mirror.doneApplyingRecordsAfterDownload()
    }
}

extension MergedSQLiteBookmarks: ShareToDestination {
    public func shareItem(item: ShareItem) {
        self.local.shareItem(item)
    }
}

extension MergedSQLiteBookmarks: BookmarksModelFactory {
    public func modelForFolder(folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        if folder.guid == BookmarkRoots.MobileFolderGUID {
            return self.modelForRoot()
        }

        return self.mirror.modelForFolder(folder)
    }

    public func modelForFolder(guid: String) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(guid, title: "")
    }

    public func modelForFolder(guid: String, title: String) -> Deferred<Maybe<BookmarksModel>> {
        if guid == BookmarkRoots.MobileFolderGUID {
            return self.modelForRoot()
        }

        return self.mirror.modelForFolder(guid, title: title)
    }

    public func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        // Return a virtual model containing "Desktop bookmarks" prepended to the local mobile bookmarks.

        guard let mobile = self.local.folderForGUID(BookmarkRoots.MobileFolderGUID, title: BookmarksFolderTitleMobile) else {
            return deferMaybe(DatabaseError(description: "Unable to fetch mobile bookmarks."))
        }

        return self.mirror.extendWithDesktopBookmarksFolder(mobile, factory: self)
    }

    // Whenever async construction is necessary, we fall into a pattern of needing
    // a placeholder that behaves correctly for the period between kickoff and set.
    public var nullModel: BookmarksModel {
        return self.local.nullModel
    }

    // TODO: we really want to know 'isRemovable', too.
    // For now we simply treat remote URLs as non-bookmarked.
    public func isBookmarked(url: String) -> Deferred<Maybe<Bool>> {
        return self.local.isBookmarked(url)
    }

    public func remove(bookmark: BookmarkNode) -> Success {
        return self.local.remove(bookmark)
    }

    public func removeByURL(url: String) -> Success {
        return self.local.removeByURL(url)
    }

    public func clearBookmarks() -> Success {
        return self.local.clearBookmarks()
    }
}

extension MergedSQLiteBookmarks: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        return self.resetClient()
    }
}

extension MergedSQLiteBookmarks: ResettableSyncStorage {
    /**
     * Right now our mirror is simply a mirror of server contents. That means we should
     * be very willing to drop it and re-populate it from the server whenever we might
     * be out of sync. See Bug 1212431 Comment 2.
     */
    public func resetClient() -> Success {
        return self.mirror.wipeBookmarks()
    }
}

extension SQLiteBookmarks: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        log.debug("SQLiteBookmarks doesn't yet store any data that needs to be discarded on account removal.")
        return succeed()
    }
}

extension SQLiteBookmarks: ResettableSyncStorage {
    public func resetClient() -> Success {
        log.debug("SQLiteBookmarks doesn't yet store any data that needs to be reset.")
        return succeed()
    }
}