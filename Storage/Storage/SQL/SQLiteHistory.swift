/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * The sqlite-backed implementation of the history protocol.
 */
public class SQLiteHistory : History {
    let files: FileAccessor
    let db: BrowserDB
    let table = JoinedHistoryVisitsTable()

    required public init(files: FileAccessor) {
        self.files = files
        self.db = BrowserDB(files: files)!
        db.create(table)
    }

    public func clear(complete: (success: Bool) -> Void) {
        let s: Site? = nil
        var err: NSError? = nil
        db.delete(&err) { connection, err in
            return self.table.delete(connection, item: nil, err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Clear failed: \(err!.localizedDescription)")
                complete(success: false)
            } else {
                complete(success: true)
            }
        }
    }

    public func get(options: QueryOptions?, complete: (data: Cursor) -> Void) {
        var err: NSError? = nil
        let res = db.query(&err) { connection, err in
            return self.table.query(connection, options: options)
        }

        dispatch_async(dispatch_get_main_queue()) {
            complete(data: res)
        }
    }

    public func addVisit(visit: Visit, complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        let inserted = db.insert(&err) { connection, err in
            return self.table.insert(connection, item: (site: visit.site, visit: visit), err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Add failed: \(err!.localizedDescription)")
            }
            complete(success: err == nil)
        }
    }

    private let debug_enabled = false
    private func debug(msg: String) {
        if debug_enabled {
            println("HistorySqlite: " + msg)
        }
    }
}
