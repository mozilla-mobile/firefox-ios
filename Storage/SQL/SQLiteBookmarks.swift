/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

private let desktopBookmarksLabel = NSLocalizedString("Desktop Bookmarks", tableName: "BookmarkPanel", comment: "The folder name for the virtual folder that contains all desktop bookmarks.")

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
        let title = row["title"] as? String ?? SQLiteBookmarks.defaultFolderTitle
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
        let bookmark = BookmarkItem(guid: guid, title: title, url: url, editable: false)
        bookmark.id = id
        return bookmark
    }

    private class func folderFactory(row: SDRow) -> BookmarkFolder {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let title = row["title"] as? String ?? SQLiteBookmarks.defaultFolderTitle
        let folder = BookmarkFolder(guid: guid, title: title, editable: false)
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

    public func modelForFolder(guid: String, title: String) -> Deferred<Maybe<BookmarksModel>> {
        let children = getChildren(guid)
        if children.status == .Failure {
            return deferMaybe(DatabaseError(description: children.statusMessage))
        }

        let f = SQLiteBookmarkFolder(guid: guid, title: title, children: children)

        // We add some suggested sites to the mobile bookmarks folder.
        if guid == BookmarkRoots.MobileFolderGUID {
            let extended = BookmarkFolderWithDefaults(folder: f, sites: SuggestedSites)
            return deferMaybe(BookmarksModel(modelFactory: self, root: extended))
        } else {
            return deferMaybe(BookmarksModel(modelFactory: self, root: f))
        }
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
        log.debug("Removing bookmark \(url).")
        return self.db.run([
            ("DELETE FROM \(TableBookmarks) WHERE url = ?", [url]),
        ])
    }

    public func remove(bookmark: BookmarkNode) -> Success {
        if let item = bookmark as? BookmarkItem {
            log.debug("Removing bookmark \(item.url).")
        }

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

    public func applyRecords(records: [BookmarkMirrorItem]) -> Success {
        // Within a transaction, we first attempt to update each item.
        // If an update fails, insert instead. TODO: batch the inserts!
        let deferred = Deferred<Maybe<()>>(defaultQueue: dispatch_get_main_queue())

        let values = records.lazy.map { $0.getUpdateOrInsertArgs() }
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

            deferred.fillIfUnfilled(Maybe(failure: DatabaseError(err: err)))
            return err == nil
        }

        return deferred
    }
}

extension SQLiteBookmarkMirrorStorage: BookmarksModelFactory {
    public func modelForFolder(folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(folder.guid)
    }

    public func modelForFolder(guid: String) -> Deferred<Maybe<BookmarksModel>> {
        if guid == BookmarkRoots.MobileFolderGUID {
            return self.modelForRoot()
        }

        let args: Args = [guid]
        let sql =
        "SELECT id, guid, type, bmkUri, title, pos FROM \(TableBookmarksMirror) WHERE " +
        "parentid = ? AND is_deleted = 0 " +
        "ORDER BY pos ASC"
        return self.db.runQuery(sql, args: args, factory: MirrorBookmarkNodeFactory.factory)
    }

    public func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        // Return a virtual model containing "Desktop bookmarks" prepended to the local mobile bookmarks.
        // TODO
        // Shiiiiiit, we need to know the places root. TODO TODO
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

        // TODO: return self.mirror.modelForFolder(folder).
    }

    public func modelForFolder(guid: String) -> Deferred<Maybe<BookmarksModel>> {
        if guid == BookmarkRoots.MobileFolderGUID {
            return self.modelForRoot()
        }
        // TODO: return self.mirror.modelForFolder(guid).
    }

    public func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        // Return a virtual model containing "Desktop bookmarks" prepended to the local mobile bookmarks.
        // TODO
        return self.local.modelForFolder(BookmarkRoots.MobileFolderGUID)
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
