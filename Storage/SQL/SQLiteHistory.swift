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
    private let table = JoinedHistoryVisitsTable()
    private var ignoredSchemes = ["about"]

    required public init(files: FileAccessor) {
        self.files = files
        self.db = BrowserDB(files: files)!
        db.createOrUpdate(table)
    }

    public func clear(complete: (success: Bool) -> Void) {
        let s: Site? = nil
        var err: NSError? = nil
        db.delete(&err) { (conn, inout err: NSError?) -> Int in
            return self.table.delete(conn, item: nil, err: &err)
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

    public class WrappedCursor : Cursor {
        private let cursor: Cursor
        override public var count: Int {
            get { return cursor.count }
        }

        init(cursor: Cursor) {
            self.cursor = cursor
            super.init(status: cursor.status, msg: cursor.statusMessage)
        }

        // Collection iteration and access functions
        public override subscript(index: Int) -> Any? {
            get {
                if let (site, visit) = cursor[index] as? (Site, Visit) {
                    return site
                }
                return nil
            }
        }

        public override func close() {
            cursor.close()
        }
    }

    public func get(options: QueryOptions?, complete: (data: Cursor) -> Void) {
        var err: NSError? = nil
        let res = db.query(&err) { (connection, inout err: NSError?) -> Cursor in
            return WrappedCursor(cursor: self.table.query(connection, options: options))
        }

        dispatch_async(dispatch_get_main_queue()) {
            complete(data: res)
        }
    }

    private func shouldAdd(url: String) -> Bool {
        if let url = NSURL(string: url) {
            if let scheme = url.scheme {
                if let index = find(ignoredSchemes, scheme) {
                    return false
                }
            }
        }

        return true
    }

    public func addVisit(visit: Visit, complete: (success: Bool) -> Void) {
        var err: NSError? = nil

        // Don't store visits to sites with about: protocols
        if !shouldAdd(visit.site.url) {
            dispatch_async(dispatch_get_main_queue()) {
                complete(success: false)
            }
            return
        }

        let inserted = db.insert(&err) { (conn, inout err: NSError?) -> Int in
            return self.table.insert(conn, item: (site: visit.site, visit: visit), err: &err)
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
