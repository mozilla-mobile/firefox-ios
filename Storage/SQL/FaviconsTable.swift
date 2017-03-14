/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// This is our default favicons store.
class FaviconsTable<T>: GenericTable<Favicon> {
    override var name: String { return TableFavicons }
    override var rows: String { return "" }
    override func create(_ db: SQLiteDBConnection) -> Bool {
        // Nothing to do: BrowserTable does it all.
        return true
    }

    override func getInsertAndArgs(_ item: inout Favicon) -> (String, Args)? {
        var args: Args = []
        args.append(item.url)
        args.append(item.width)
        args.append(item.height)
        args.append(item.date)
        args.append(item.type.rawValue)
        return ("INSERT INTO \(TableFavicons) (url, width, height, date, type) VALUES (?,?,?,?,?)", args)
    }

    override func getUpdateAndArgs(_ item: inout Favicon) -> (String, Args)? {
        var args = Args()
        args.append(item.width)
        args.append(item.height)
        args.append(item.date)
        args.append(item.type.rawValue)
        args.append(item.url)
        return ("UPDATE \(TableFavicons) SET width = ?, height = ?, date = ?, type = ? WHERE url = ?", args)
    }

    override func getDeleteAndArgs(_ item: inout Favicon?) -> (String, Args)? {
        var args = Args()
        if let icon = item {
            args.append(icon.url)
            return ("DELETE FROM \(TableFavicons) WHERE url = ?", args)
        }

        // TODO: don't delete icons that are in use. Bug 1161630.
        return ("DELETE FROM \(TableFavicons)", args)
    }

    override var factory: ((_ row: SDRow) -> Favicon)? {
        return { row -> Favicon in
            let icon = Favicon(url: row["url"] as! String, date: Date(timeIntervalSince1970: row["date"] as! Double), type: IconType(rawValue: row["type"] as! Int)!)
            icon.id = row["id"] as? Int
            return icon
        }
    }

    override func getQueryAndArgs(_ options: QueryOptions?) -> (String, Args)? {
        var args = Args()
        if let filter: Any = options?.filter {
            args.append("%\(filter)%")
            return ("SELECT id, url, date, type FROM \(TableFavicons) WHERE url LIKE ?", args)
        }
        return ("SELECT id, url, date, type FROM \(TableFavicons)", args)
    }

    func getIDFor(_ db: SQLiteDBConnection, obj: Favicon) -> Int? {
        let opts = QueryOptions()
        opts.filter = obj.url

        let cursor = query(db, options: opts)
        if cursor.count != 1 {
            return nil
        }
        return cursor[0]?.id
    }

    func insertOrUpdate(_ db: SQLiteDBConnection, obj: Favicon) -> Int? {
        var err: NSError? = nil
        guard let id = self.insert(db, item: obj, err: &err) else {
            return nil
        }

        if id >= 0 {
            obj.id = id
            return id
        }

        if obj.id == nil {
            let id = getIDFor(db, obj: obj)
            obj.id = id
            return id
        }

        return obj.id
    }

    func getCleanupCommands() -> (sql: String, args: Args?) {
        return (sql: "DELETE FROM \(TableFavicons) " +
            "WHERE \(TableFavicons).id NOT IN (" +
                "SELECT faviconID FROM \(TableFaviconSites) " +
                "UNION ALL " +
                "SELECT faviconID FROM \(TableBookmarksLocal) WHERE faviconID IS NOT NULL " +
                "UNION ALL " +
                "SELECT faviconID FROM \(TableBookmarksMirror) WHERE faviconID IS NOT NULL" +
            ")", args: nil)
    }
}
