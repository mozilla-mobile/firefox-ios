/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let TableNameHistory = "history"

// NOTE: If you add a new Table, make sure you update the version number in BrowserDB.swift!

// This is our default history store.
class HistoryTable<T>: GenericTable<Site> {
    override var name: String { return TableNameHistory }
    override var version: Int { return 1 }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                       "guid TEXT NOT NULL UNIQUE, " +
                       "url TEXT NOT NULL UNIQUE, " +
                       "title TEXT NOT NULL" }

    override func getInsertAndArgs(inout item: Site) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if item.guid == nil {
            item.guid = NSUUID().UUIDString
        }
        args.append(item.guid!)
        args.append(item.url)
        args.append(item.title)
        return ("INSERT INTO \(TableNameHistory) (guid, url, title) VALUES (?,?,?)", args)
    }

    override func getUpdateAndArgs(inout item: Site) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.title)
        args.append(item.url)
        return ("UPDATE \(TableNameHistory) SET title = ? WHERE url = ?", args)
    }

    override func getDeleteAndArgs(inout item: Site?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let site = item {
            args.append(site.url)
            return ("DELETE FROM \(TableNameHistory) WHERE url = ?", args)
        }
        return ("DELETE FROM \(TableNameHistory)", args)
    }

    override var factory: ((row: SDRow) -> Site)? {
        return { row -> Site in
            let site = Site(url: row["url"] as! String, title: row["title"] as String ?? "")
            site.id = row["id"] as? Int
            site.guid = row["guid"] as? String
            return site
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let filter: AnyObject = options?.filter {
            args.append("%\(filter)%")
            return ("SELECT id, guid, url, title FROM \(TableNameHistory) WHERE url LIKE ?", args)
        }
        return ("SELECT id, guid, url, title FROM \(TableNameHistory)", args)
    }

    func getIDFor(db: SQLiteDBConnection, obj: Site) -> Int? {
        let opts = QueryOptions()
        opts.filter = obj.url

        let cursor = query(db, options: opts)
        if (cursor.count != 1) {
            return nil
        }
        return (cursor[0] as! Site).id
    }

    func insertOrUpdate(db: SQLiteDBConnection, obj: Site) {
        var err: NSError? = nil
        let id = self.insert(db, item: obj, err: &err)
        if id >= 0 {
            obj.id = id
            return
        }

        if obj.id == nil {
            obj.id = getIDFor(db, obj: obj)
        }
    }
}
