/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class BookmarkTable<T> : GenericTable<BookmarkNode> {
    private let favicons = FaviconsTable<Favicon>()
    private let joinedFavicons = JoinedFaviconsHistoryTable<(Site, Favicon)>()
    override var name: String { return "bookmarks" }
    override var version: Int { return 2 }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "guid TEXT NOT NULL UNIQUE, " +
        "url TEXT, " +
        "parent INTEGER, " +
        "faviconId INTEGER, " +
        "title TEXT" }


    override func create(db: SQLiteDBConnection, version: Int) -> Bool {
        return super.create(db, version: version) && favicons.create(db, version: version) && joinedFavicons.create(db, version: version)
    }

    override func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        return super.updateTable(db, from: from, to: to) && favicons.updateTable(db, from: from, to: to) && updateTable(db, from: from, to: to)
    }

    private func setupFavicon(db: SQLiteDBConnection, item: Type?) {
        // If this has an icon attached, try to use it
        if let favicon = item?.favicon {
            if favicon.id == nil {
                favicons.insertOrUpdate(db, obj: favicon)
            }
        } else {
            // Otherwise, lets go look one up for this URL
            if let bookmark = item as? BookmarkItem {
                let options = QueryOptions(filter: bookmark.url, filterType: FilterType.ExactUrl)
                let favicons = joinedFavicons.query(db, options: options)
                if favicons.count > 0 {
                    if let (site, favicon) = favicons[0] as? (Site, Favicon) {
                        bookmark.favicon = favicon
                    }
                }
            }
        }
    }

    override func insert(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        setupFavicon(db, item: item)
        return super.insert(db, item: item, err: &err)
    }

    override func update(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        setupFavicon(db, item: item)
        return super.update(db, item: item, err: &err)
    }

    override func getInsertAndArgs(inout item: BookmarkNode) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.guid)
        if let bookmark = item as? BookmarkItem {
            args.append(bookmark.url)
        } else {
            args.append(nil)
        }

        args.append(item.title)
        args.append(item.favicon?.id)

        return ("INSERT INTO \(name) (guid, url, title, faviconId) VALUES (?,?,?,?)", args)
    }

    override func getUpdateAndArgs(inout item: BookmarkNode) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let bookmark = item as? BookmarkItem {
            args.append(bookmark.url)
        } else {
            args.append(nil)
        }
        args.append(item.title)
        args.append(item.favicon?.id)
        args.append(item.guid)
        return ("UPDATE \(name) SET url = ?, title = ?, faviconId = ? WHERE guid = ?", args)
    }

    override func getDeleteAndArgs(inout item: BookmarkNode?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let bookmark = item as? BookmarkItem {
            if bookmark.guid != "" {
                // If there's a guid, we'll delete entries with it
                args.append(bookmark.guid)
                return ("DELETE FROM \(name) WHERE guid = ?", args)
            } else if bookmark.url != "" {
                // If there's a url, we'll delete ALL entries with it
                args.append(bookmark.url)
                return ("DELETE FROM \(name) WHERE url = ?", args)
            } else {
                // If you passed us something with no url or guid, we'll just have to bail...
                return nil
            }
        }
        return ("DELETE FROM \(name)", args)
    }

    override var factory: ((row: SDRow) -> BookmarkNode)? {
        return { row -> BookmarkNode in
            let bookmark = BookmarkItem(guid: row["guid"] as String,
                title: row["title"] as String,
                url: row["bookmarkUrl"] as String)
            bookmark.id = row["bookmarkId"] as? Int

            if let faviconUrl = row["faviconUrl"] as? String {
                let favicon = Favicon(url: faviconUrl,
                    date: NSDate(timeIntervalSince1970: row["faviconDate"] as Double),
                    type: IconType(rawValue: row["faviconType"] as Int)!)

                bookmark.favicon = favicon
            }
            return bookmark
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        // XXX - This should support querying for a particular bookmark, querying by name/url, and querying
        //       for everything in a folder. Right now it doesn't do any of that :(
        var sql = "SELECT \(name).id as bookmarkId, guid, \(name).url as bookmarkUrl, title, \(favicons.name).url as faviconUrl, date as faviconDate, type as faviconType FROM \(name)" +
                  " LEFT OUTER JOIN \(favicons.name) ON \(favicons.name).id = \(name).faviconId"

        if let filter: AnyObject = options?.filter {
            if let type = options?.filterType {
                switch(type) {
                case .ExactUrl:
                        args.append(filter)
                        return ("\(sql) WHERE bookmarkUrl = ?", args)
                default:
                    break
                }
            }

            // Default to search by guid (i.e. for a folder)
            args.append(filter)
            return ("\(sql) WHERE guid = ?", args)
        }

        return (sql, args)
    }
}

class SqliteBookmarkFolder: BookmarkFolder {
    private let cursor: Cursor
    override var count: Int {
        return cursor.count
    }

    override subscript(index: Int) -> BookmarkNode {
        let bookmark = cursor[index]
        if let item = bookmark as? BookmarkItem {
            return item
        }
        return bookmark as SqliteBookmarkFolder
    }

    init(guid: String, title: String, children: Cursor) {
        self.cursor = children
        super.init(guid: guid, title: title)
    }
}

public class BookmarksSqliteFactory : BookmarksModelFactory, ShareToDestination {
    let db: BrowserDB
    let table = BookmarkTable<BookmarkNode>()

    public init(files: FileAccessor) {
        db = BrowserDB(files: files)!
        db.createOrUpdate(table)
    }

    private func getChildren(guid: String) -> Cursor {
        var err: NSError? = nil
        return db.query(&err, callback: { (connection, err) -> Cursor in
            return self.table.query(connection, options: QueryOptions(filter: guid))
        })
    }

    public func modelForFolder(folder: BookmarkFolder, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        let children = getChildren(folder.guid)
        if children.status == .Failure {
            failure(children.statusMessage)
            return
        }
        let f = SqliteBookmarkFolder(guid: folder.guid, title: folder.title, children: children)
        success(BookmarksModel(modelFactory: self, root: f))
    }

    public func modelForFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        var err: NSError? = nil
        let children = db.query(&err, callback: { (connection, err) -> Cursor in
            return self.table.query(connection, options: QueryOptions(filter: guid))
        })
        let folder = SqliteBookmarkFolder(guid: guid, title: "", children: children)
        success(BookmarksModel(modelFactory: self, root: folder))
    }

    public func modelForRoot(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        var err: NSError? = nil
        let children = db.query(&err, callback: { (connection, err) -> Cursor in
            return self.table.query(connection, options: QueryOptions(filter: nil))
        })
        let folder = SqliteBookmarkFolder(guid: BookmarkRoots.PLACES_FOLDER_GUID, title: "Root", children: children)
        success(BookmarksModel(modelFactory: self, root: folder))
    }

    public var nullModel: BookmarksModel {
        let children = Cursor(status: .Failure, msg: "Null model")
        let folder = SqliteBookmarkFolder(guid: "Null", title: "Null", children: children)
        return BookmarksModel(modelFactory: self, root: folder)
    }

    public func shareItem(item: ShareItem) {
        var err: NSError? = nil
        let inserted = db.insert(&err, callback: { (connection, err) -> Int in
            var bookmark = BookmarkItem(guid: Bytes.generateGUID(), title: item.title ?? "", url: item.url)
            bookmark.favicon = item.favicon
            return self.table.insert(connection, item: bookmark, err: &err)
        })
    }

    public func findForUrl(url: String, success: (Cursor) -> (), failure: (Any) -> ()) {
        var err: NSError? = nil
        let children = db.query(&err, callback: { (connection, err) -> Cursor in
            let opts = QueryOptions(filter: url, filterType: FilterType.ExactUrl, sort: QuerySort.None)
            return self.table.query(connection, options: opts)
        })

        if children.status == .Failure {
            failure(children.statusMessage)
            return
        }
        return success(children)
    }

    public func isBookmarked(url: String, success: (Bool) -> (), failure: (Any) -> ()) {
        findForUrl(url, success: { children in
            success(children.count > 0)
        }, failure: failure)
    }

    public func remove(bookmark: BookmarkNode, success: (Bool) -> (), failure: (Any) -> ()) {
        var err: NSError? = nil
        let numDeleted = self.db.delete(&err) { (connection, err) -> Int in
            return self.table.delete(connection, item: bookmark, err: &err)
        }

        if let err = err {
            failure(err)
            return
        }

        success(numDeleted > 0)
    }
}


