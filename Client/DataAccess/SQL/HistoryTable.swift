/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let HISTORY_TABLE = "history"

class HistoryTable: Table {
    let NotASiteErrorCode = 100
    private let TableName = "History"
    private let Rows = "guid TEXT NOT NULL UNIQUE, " +
                       "url TEXT NOT NULL UNIQUE, " +
                       "title TEXT NOT NULL"

    func getName() -> String {
        return TableName
    }

    let debug_enabled = false
    func debug(msg: String) {
        if debug_enabled {
            println("HistoryTable: \(msg)")
        }
    }

    func create(db: FMDatabase, version: UInt32) -> Bool {
        db.executeStatements("CREATE TABLE IF NOT EXISTS \(TableName) (\(Rows))")
        return true
    }

    func updateTable(db: FMDatabase, from: UInt32, to: UInt32) -> Bool {
        debug("Update table \(TableName) from \(from) to \(to)")
        // No upgrades yet
        return false
    }

    func insert<T>(db: FMDatabase, item: T?, inout err: NSError?) -> Int64 {
        debug("Insert into \(TableName) \(item)")
        if let site = item as? Site {
            if db.executeUpdate("INSERT INTO \(TableName) (guid, url, title) VALUES (?,?,?)", withArgumentsInArray: [
                    site.guid,
                    site.url,
                    site.title]) {
                return db.lastInsertRowId()
            }
            err = db.lastError()
            return 0
        }
        err = NSError(domain: "mozilla.org", code: NotASiteErrorCode, userInfo: [
            NSLocalizedDescriptionKey: "Tried to save something that isn't a site"
        ])
        return 0
    }

    func update<T>(db: FMDatabase, item: T?, inout err: NSError?) -> Int32 {
        debug("Update into \(TableName) \(item)")
        if let site = item as? Site {
            if db.executeUpdate("UPDATE \(TableName) SET title = ? WHERE guid = ? AND url = ?", withArgumentsInArray: [
                    site.title,
                    site.guid,
                    site.url]) {
                return db.changes()
            }
        }
        err = NSError(domain: "mozilla.org", code: NotASiteErrorCode, userInfo: [
            NSLocalizedDescriptionKey: "Tried to save something that isn't a site"
        ])
        return 0
    }

    func delete<T>(db: FMDatabase, item: T?, inout err: NSError?) -> Int32 {
        debug("Delete from \(TableName) \(item)")
        if let site = item as? Site {
            if db.executeUpdate("DELETE FROM \(TableName) WHERE url = ?", withArgumentsInArray: [ site.url ]) {
                return db.changes()
            }
            err = db.lastError()
            return 0
        } else if item == nil {
            if db.executeUpdate("DELETE FROM \(TableName)", withArgumentsInArray: [ ]) {
                return db.changes()
            }
        }
        err = NSError(domain: "mozilla.org", code: NotASiteErrorCode, userInfo: [
            NSLocalizedDescriptionKey: "Tried to delete something that isn't a site"
        ])
        return 0
    }

    private func fromResult(result: FMResultSet) -> Site {
        let site = Site(url: result.stringForColumn("url"), title: result.stringForColumn("title"))
        site.guid = result.stringForColumn("guid")
        return site
    }

    func query(db: FMDatabase) -> Cursor {
        debug("Query \(TableName)")
        let res = db.executeQuery("SELECT * FROM \(TableName)", withArgumentsInArray: [])

        // XXX - This should do something super smart to avoid paging the entire db into memory. Right now it doesn't.
        //       i.e. return SqliteWindowedCursor(res)
        var resArray = [Site]()
        while res.next() {
            resArray.append(fromResult(res))
        }

        return ArrayCursor(data: resArray)
    }
}
