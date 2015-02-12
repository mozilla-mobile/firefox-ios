/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * The SQLite-backed implementation of the ReadingList protocol.
 */

public class SQLiteReadingList: ReadingList {
    let files: FileAccessor
    let db: BrowserDB
    let table = ReadingListTable<ReadingListItem>()

    required public init(files: FileAccessor) {
        self.files = files
        self.db = BrowserDB(files: files)!
        db.createOrUpdate(table)
    }

    public func clear(complete: (success: Bool) -> Void) {
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

    public func get(complete: (data: Cursor) -> Void) {
        var err: NSError? = nil
        let res = db.query(&err) { connection, err in
            return self.table.query(connection, options: nil)
        }
        dispatch_async(dispatch_get_main_queue()) {
            complete(data: res)
        }
    }

    public func add(#item: ReadingListItem, complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        let inserted = db.insert(&err) { connection, err in
            return self.table.insert(connection, item: item, err: &err)
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
            println("SQLiteReadingList: " + msg)
        }
    }
}
