/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let TableNameHistory = "history"
let NotASiteErrorCode = 100

class HistoryTable<T>: GenericTable<Site> {
    override var name: String { return TableNameHistory }
    override var rows: String { return "guid TEXT NOT NULL UNIQUE, " +
                       "url TEXT NOT NULL UNIQUE, " +
                       "title TEXT NOT NULL" }

    override func getInsertAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        let site = item as Site
        // Runtime errors happen if we let Swift try to infer the type of this array
        // so we construct it very specifically.
        var args = [AnyObject?]()
        if site.guid == nil {
            site.guid = NSUUID().UUIDString
        }
        args.append(site.guid!)
        args.append(site.url)
        args.append(site.title)
        return ("INSERT INTO \(TableNameHistory) (guid, url, title) VALUES (?,?,?)", args)
    }

    override func getUpdateAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        let site = item as Site
        // Runtime errors happen if we let Swift try to infer the type of this array
        // so we construct it very specifically.
        var args = [AnyObject?]()
        args.append(site.title)
        args.append(site.url)
        return ("UPDATE \(TableNameHistory) SET title = ? WHERE url = ?", args)
    }

    override func getDeleteAndArgs<T>(item: T?) -> (String?, [AnyObject?]) {
        var args = [AnyObject?]()
        if let site = item as? Site {
            args.append(site.url)
            return ("DELETE FROM \(TableNameHistory) WHERE url = ?", args)
        }
        return ("DELETE FROM \(TableNameHistory)", args)
    }

    override var factory: ((row: SDRow) -> Site)? {
        return { row -> Site in
            let site = Site(url: row[1] as String, title: row[2] as String)
            site.guid = row[0] as? String
            return site
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String?, [AnyObject?]) {
        var args = [AnyObject?]()
        if let filter = options?.filter {
            args.append(filter)
            return ("SELECT guid, url, title FROM \(TableNameHistory) WHERE url LIKE ?", args)
        }
        return ("SELECT guid, url, title FROM \(TableNameHistory)", args)
    }
}
