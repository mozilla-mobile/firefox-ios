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

    required public init(files: FileAccessor) {
        self.files = files
        self.db = BrowserDB(files: files)!
    }

    public func clear(filter: String?, options: HistoryOptions?, complete: (success: Bool) -> Void) {
        let s: Site? = nil
        var err: NSError? = nil
        db.delete(TableNameHistory, item: s, err: &err)
        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Clear failed: \(err!.localizedDescription)")
            }
        }
    }

    public func get(filter: String?, options: HistoryOptions?, complete: (data: Cursor) -> Void) {
        let res = db.query(TableNameHistory)
        dispatch_async(dispatch_get_main_queue()) {
            complete(data: res)
        }
    }

    public func addVisit(site: Site, options: HistoryOptions?, complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        db.insert(TableNameHistory, item: site, err: &err)
        // TODO: Track visits in a separate table

        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Add failed: \(err!.localizedDescription)")
            }
            complete(success: err == nil)
        }
    }

    private let debug_enabled = true
    private func debug(msg: String) {
        if debug_enabled {
            println("HistorySqlite: " + msg)
        }
    }
}
