/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

public class IgnoredSiteError: ErrorType {
    public var description: String {
        return "Ignored site."
    }
}


func failOrSucceed<T>(err: NSError?, op: String, val: T) -> Deferred<Result<T>> {
    if let err = err {
        log.debug("\(op) failed: \(err.localizedDescription)")
        return deferResult(DatabaseError(err: err))
    }

    return deferResult(val)
}

func failOrSucceed(err: NSError?, op: String) -> Success {
    return failOrSucceed(err, op, ())
}

/**
 * The sqlite-backed implementation of the history protocol.
 */
public class SQLiteHistory: BrowserHistory {
    let db: BrowserDB
    private let table = JoinedHistoryVisitsTable()
    private var ignoredSchemes = ["about"]

    required public init(db: BrowserDB) {
        self.db = db
        db.createOrUpdate(table)
    }

    public func clear() -> Success {
        let s: Site? = nil
        var err: NSError? = nil

        // TODO: this should happen asynchronously.
        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            return self.table.delete(conn, item: nil, err: &err)
        }

        return failOrSucceed(err, "Clear")
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

    public func get(options: QueryOptions?) -> Deferred<Result<Cursor>> {
        var err: NSError? = nil
        let res = db.withReadableConnection(&err) { (connection, inout err: NSError?) -> Cursor in
            return WrappedCursor(cursor: self.table.query(connection, options: options))
        }

        if let err = err {
            log.debug("Query failed: \(err.localizedDescription)")
            return deferResult(DatabaseError(err: err))
        }

        if res.status != .Success {
            log.warning("Got cursor but status != Success: \(res.statusMessage).")
            return deferResult(DatabaseError(err: nil))
        }

        return deferResult(res)
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

    public func addVisit(visit: SiteVisit) -> Success {
        var err: NSError? = nil

        // Don't store visits to sites with about: protocols
        if !shouldAdd(visit.site.url) {
            return deferResult(IgnoredSiteError())
        }

        let inserted = db.insert(&err) { (conn, inout err: NSError?) -> Int in
            return self.table.insert(conn, item: (site: visit.site, visit: visit), err: &err)
        }

        return failOrSucceed(err, "Add")
    }
}
