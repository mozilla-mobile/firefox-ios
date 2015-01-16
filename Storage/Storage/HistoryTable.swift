/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

let TableNameHistory = "history"
let NotASiteErrorCode = 100

class HistoryTable: Table {
    let name = "History"
    private let rows = "guid TEXT NOT NULL UNIQUE, " +
                       "url TEXT NOT NULL UNIQUE, " +
                       "title TEXT NOT NULL"

    let debug_enabled = false
    func debug(msg: String) {
        if debug_enabled {
            println("HistoryTable: \(msg)")
        }
    }

    func create(db: SQLiteDBConnection, version: Int) -> Bool {
        db.executeChange("CREATE TABLE IF NOT EXISTS \(name) (\(self.rows))")
        return true
    }

    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        debug("Update table \(name) from \(from) to \(to)")
        // No upgrades yet
        return false
    }

    func insert<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        debug("Insert into \(name) \(item)")
        if let site = item as? Site {
            let query = "INSERT INTO \(self.name) (guid, url, title) VALUES (?,?,?)"
            let args: [AnyObject?] = [site.guid, site.url, site.title]
            if let error = db.executeChange(query, withArgs: args) {
                err = error
                return 0
            }
            return db.lastInsertedRowID
        }

        err = NSError(domain: "mozilla.org", code: NotASiteErrorCode, userInfo: [
            NSLocalizedDescriptionKey: "Tried to save something that isn't a site"
        ])
        return 0
    }

    func update<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        debug("Update into \(name) \(item)")
        if let site = item as? Site {
            let query = "UPDATE \(self.name) SET title = ? WHERE guid = ? AND url = ?"
            let args = [site.title, site.guid, site.url]
            if let error = db.executeChange(query, withArgs: args) {
                println(error.description)
                err = error
                return 0
            }

            return db.numberOfRowsModified
        }

        err = NSError(domain: "mozilla.org", code: NotASiteErrorCode, userInfo: [
            NSLocalizedDescriptionKey: "Tried to save something that isn't a site"
        ])
        return 0
    }

    func delete<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        debug("Delete from \(name) \(item)")
        var numDeleted: Int = 0
        var str = "DELETE FROM \(name)"
        var args = [String]()

        if let site = item as? Site {
            str += " WHERE url = ?"
            args.append(site.url)
        } else if item != nil {
            err = NSError(domain: "org.mozilla", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid object"])
            return numDeleted
        }

        if str != "" {
            if let error = db.executeChange(str, withArgs: args) {
                println(error.description)
                err = error
                return 0
            }
        }

        return db.numberOfRowsModified
    }

    private func fromResult(result: SDRow) -> Site {
        return Site(guid: result[0] as String, url: result[1] as String, title: result[2] as String)
    }

    func factory(row: SDRow) -> Site {
        let url = row["url"] as String
        let title = row["title"] as String
        let guid = row["guid"] as String

        return Site(guid: guid, url: url, title: title)
    }

    func query(db: SQLiteDBConnection) -> Cursor {
        debug("Query \(name)")
        return db.executeQuery("SELECT guid, url, title FROM \(name)", factory: self.factory)
    }
}
