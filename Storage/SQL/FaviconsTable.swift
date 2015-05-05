/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let TableNameFavicons = "favicons"

// NOTE: If you add a new Table, make sure you update the version number in BrowserDB.swift!

// This is our default favicons store.
class FaviconsTable<T>: GenericTable<Favicon> {
    override var name: String { return TableNameFavicons }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                       "url TEXT NOT NULL UNIQUE, " +
                       "width INTEGER, " +
                       "height INTEGER, " +
                       "type INTEGER NOT NULL, " +
                       "date REAL NOT NULL" }

    override func getInsertAndArgs(inout item: Favicon) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.url)
        args.append(item.width)
        args.append(item.height)
        args.append(item.date)
        args.append(item.type.rawValue)
        return ("INSERT INTO \(TableNameFavicons) (url, width, height, date, type) VALUES (?,?,?,?,?)", args)
    }

    override func getUpdateAndArgs(inout item: Favicon) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.width)
        args.append(item.height)
        args.append(item.date)
        args.append(item.type.rawValue)
        args.append(item.url)
        return ("UPDATE \(TableNameFavicons) SET width = ?, height = ?, date = ?, type = ? WHERE url = ?", args)
    }

    override func getDeleteAndArgs(inout item: Favicon?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let icon = item {
            args.append(icon.url)
            return ("DELETE FROM \(TableNameFavicons) WHERE url = ?", args)
        }

        // TODO: don't delete icons that are in use. Bug 1161630.
        return ("DELETE FROM \(TableNameFavicons)", args)
    }

    override var factory: ((row: SDRow) -> Favicon)? {
        return { row -> Favicon in
            let icon = Favicon(url: row["url"] as! String, date: NSDate(timeIntervalSince1970: row["date"] as! Double), type: IconType(rawValue: row["type"] as! Int)!)
            icon.id = row["id"] as? Int
            return icon
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let filter: AnyObject = options?.filter {
            args.append("%\(filter)%")
            return ("SELECT id, url, date, type FROM \(TableNameFavicons) WHERE url LIKE ?", args)
        }
        return ("SELECT id, url, date, type FROM \(TableNameFavicons)", args)
    }

    func getIDFor(db: SQLiteDBConnection, obj: Favicon) -> Int? {
        let opts = QueryOptions()
        opts.filter = obj.url

        let cursor = query(db, options: opts)
        if (cursor.count != 1) {
            return nil
        }
        return cursor[0]?.id
    }

    func insertOrUpdate(db: SQLiteDBConnection, obj: Favicon) -> Int? {
        var err: NSError? = nil
        let id = self.insert(db, item: obj, err: &err)
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
}
