/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let TableNameHistory = "history"
let NotASiteErrorCode = 100

class HistoryTable: GenericTable {
    override var name: String { return TableNameHistory }
    override var rows: String { return "guid TEXT NOT NULL UNIQUE, " +
                       "url TEXT NOT NULL UNIQUE, " +
                       "title TEXT NOT NULL" }

    override func getInsertAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        let site = item as Site
        return ("INSERT INTO \(TableNameHistory) (guid, url, title) VALUES (?,?,?)",
            [site.guid, site.url, site.title])
    }

    override func getUpdateAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        let site = item as Site
        return ("UPDATE \(TableNameHistory) (guid, url, title) SET title = ? WHERE guid = ? AND url = ?",
            [site.guid, site.url, site.title])
    }

    override func getDeleteAndArgs<T>(item: T?) -> (String, [AnyObject?]) {
        if let site = item as? Site {
            return ("DELETE FROM \(TableNameHistory) WHERE url = ?", [site.url])
        }
        return ("DELETE FROM \(TableNameHistory)", [String]())
    }

    override func factory(result: SDRow) -> AnyObject {
        let site = Site(url: result[1] as String, title: result[2] as String)
        site.guid = result[0] as? String
        return site
    }

    override func getQueryAndArgs(filter: String?) -> (String, [AnyObject?]) {
        if let filter = filter {
            return ("SELECT guid, url, title FROM \(TableNameHistory) WHERE url LIKE ?", [filter])
        }
        return ("SELECT guid, url, title FROM \(TableNameHistory)", [String]())
    }
}
