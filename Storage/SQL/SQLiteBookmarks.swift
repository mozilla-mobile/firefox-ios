/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

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

public class SQLiteBookmarks: BookmarksModelFactory {
    let db: BrowserDB
    let favicons: Favicons

    public init(db: BrowserDB, favicons: Favicons) {
        self.db = db
        self.favicons = favicons
    }

    private class func factory(row: SDRow) -> BookmarkNode {
        if let typeCode = row["type"] as? Int, type = BookmarkNodeType(rawValue: typeCode) {

            let id = row["id"] as! Int
            let guid = row["guid"] as! String
            switch type {
            case .Bookmark:
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

            case .Folder:
                let title = row["title"] as? String ??
                NSLocalizedString("Untitled", tableName: "Storage", comment: "The default name for bookmark folders without titles.")
                let folder = BookmarkFolder(guid: guid, title: title)
                folder.id = id
                return folder

            case .DynamicContainer:
                assert(false, "Should never occur.")
            case .Separator:
                assert(false, "Separators not yet supported.")
            }
        }

        assert(false, "Invalid bookmark data.")
    }

    private func getChildrenWhere(whereClause: String, args: Args, includeIcon: Bool) -> Cursor<BookmarkNode> {
        var err: NSError? = nil
        return db.withReadableConnection(&err) { (conn, err) -> Cursor<BookmarkNode> in
            let inner = "SELECT id, type, guid, url, title, faviconID FROM \(TableBookmarks) WHERE \(whereClause)"

            if includeIcon {
                let sql =
                "SELECT bookmarks.id AS id, bookmarks.type AS type, guid, bookmarks.url AS url, title, " +
                "favicons.url AS iconURL, favicons.date AS iconDate, favicons.type AS iconType " +
                "FROM (\(inner)) AS bookmarks " +
                "LEFT OUTER JOIN favicons ON bookmarks.faviconID = favicons.id"
                return conn.executeQuery(sql, factory: SQLiteBookmarks.factory, withArgs: args)
            } else {
                return conn.executeQuery(inner, factory: SQLiteBookmarks.factory, withArgs: args)
            }
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

    private func modelForFolder(guid: String, title: String, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        let children = getChildren(guid)
        if children.status == .Failure {
            failure(children.statusMessage)
            return
        }
        let f = SQLiteBookmarkFolder(guid: guid, title: title, children: children)
        success(BookmarksModel(modelFactory: self, root: f))
    }

    public func modelForFolder(folder: BookmarkFolder, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        self.modelForFolder(folder.guid, title: folder.title, success: success, failure: failure)
    }

    public func modelForFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        self.modelForFolder(guid, title: "", success: success, failure: failure)
    }

    public func modelForRoot(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        let children = getRootChildren()
        if children.status == .Failure {
            failure(children.statusMessage)
            return
        }
        let folder = SQLiteBookmarkFolder(guid: BookmarkRoots.RootGUID, title: "Root", children: children)
        success(BookmarksModel(modelFactory: self, root: folder))
    }

    public var nullModel: BookmarksModel {
        let children = Cursor<BookmarkNode>(status: .Failure, msg: "Null model")
        let folder = SQLiteBookmarkFolder(guid: "Null", title: "Null", children: children)
        return BookmarksModel(modelFactory: self, root: folder)
    }

    public func isBookmarked(url: String, success: (Bool) -> (), failure: (Any) -> ()) {
        var err: NSError?
        let sql = "SELECT id FROM \(TableBookmarks) WHERE url = ? LIMIT 1"
        let args: Args = [url]

        let c = db.withReadableConnection(&err) { (conn, err) -> Cursor<Int> in
            return conn.executeQuery(sql, factory: { $0["id"] as! Int }, withArgs: args)
        }
        if c.status == .Success {
            success(c.count > 0)
        } else {
            failure(err)
        }
    }

    private func runSQL(sql: String, args: Args?, success: (Bool) -> Void, failure: (Any) -> Void) {
        var err: NSError?
        self.db.withWritableConnection(&err) { (connection: SQLiteDBConnection, inout err: NSError?) -> Int in
            if let err = connection.executeChange(sql, withArgs: args) {
                failure(err)
                return 0
            }
            success(true)
            return 1
        }
    }

    public func removeByURL(url: String, success: (Bool) -> Void, failure: (Any) -> Void) {
        log.debug("Removing bookmark \(url).")
        let sql = "DELETE FROM \(TableBookmarks) WHERE url = ?"
        let args: Args = [url]

        self.runSQL(sql, args: args, success: success, failure: failure)
    }

    public func remove(bookmark: BookmarkNode, success: (Bool) -> (), failure: (Any) -> ()) {
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

        self.runSQL(sql, args: args, success: success, failure: failure)
    }
}

extension SQLiteBookmarks: ShareToDestination {
    public func addToMobileBookmarks(url: NSURL, title: String, favicon: Favicon?) -> Success {
        var err: NSError?

        return self.db.withWritableConnection(&err) {  (conn, err) -> Success in
            func insertBookmark(icon: Int) -> Success {
                log.debug("Inserting bookmark with specified icon \(icon).")
                let urlString = url.absoluteString!
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
                    return deferResult(DatabaseError(err: err))
                }
                return succeed()
            }

            // Insert the favicon.
            if let icon = favicon {
                return self.favicons.addFavicon(icon) >>== insertBookmark
            }
            return insertBookmark(-1)
        }
    }

    public func shareItem(item: ShareItem) {
        // We parse here in anticipation of getting real URLs at some point.
        if let url = item.url.asURL {
            let title = item.title ?? url.absoluteString!
            self.addToMobileBookmarks(url, title: title, favicon: item.favicon)
        }
    }
}