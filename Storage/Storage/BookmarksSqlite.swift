

import Foundation

class BookmarkTable<T> : GenericTable<BookmarkNode> {
    override var name: String { return "bookmarks" }
    override var version: Int { return 1 }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "guid TEXT NOT NULL UNIQUE, " +
        "url TEXT, " +
        "parent INTEGER, " +
        "title TEXT" }

    override func getInsertAndArgs(inout item: BookmarkNode) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.guid)
        if let bookmark = item as? Bookmark {
            args.append(bookmark.url)
        } else {
            args.append(nil)
        }
        args.append(item.title)
        return ("INSERT INTO \(name) (guid, url, title) VALUES (?,?,?)", args)
    }

    override func getUpdateAndArgs(inout item: BookmarkNode) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let bookmark = item as? Bookmark {
            args.append(bookmark.url)
        } else {
            args.append(nil)
        }
        args.append(item.title)
        args.append(item.guid)
        return ("UPDATE \(name) SET url = ?, title = ? WHERE guid = ?", args)
    }

    override func getDeleteAndArgs(inout item: BookmarkNode?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let bookmark = item as? Bookmark {
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
                url: row["url"] as String)
            return bookmark
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        // XXX - This should support querying for a particular bookmark, querying by name/url, and querying
        //       for everything in a folder. Right now it doesn't do any of that :(
        var sql = "SELECT id, guid, url, title FROM \(name)"

        if let filter: AnyObject = options?.filter {
            if let type = options?.filterType {
                switch(type) {
                case .ExactUrl:
                        args.append(filter)
                        return ("\(sql) WHERE url = ?", args)
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

@objc
class SqliteBookmarkFolder: BookmarkItem, BookmarkFolder {
    private let cursor: Cursor
    var count: Int {
        return cursor.count
    }

    subscript(index: Int) -> BookmarkNode {
        let bookmark = cursor[index]
        if let item = bookmark as? BookmarkItem {
            return item
        }
        return bookmark as SqliteBookmarkFolder
    }

    init(guid: String, title: String, children: Cursor) {
        self.cursor = children
        super.init(guid: guid, title: title, url: "")
    }
}

public class BookmarksSqliteFactory : BookmarksModelFactory, ShareToDestination {
    let db: BrowserDB
    let table: BookmarkTable<BookmarkNode>

    public init(files: FileAccessor) {
        db = BrowserDB(files: files)!
        table = BookmarkTable<BookmarkNode>()
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
            var bookmark: BookmarkItem!
            bookmark = BookmarkItem(guid: Bytes.generateGUID(), title: item.title ?? "", url: item.url)

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


