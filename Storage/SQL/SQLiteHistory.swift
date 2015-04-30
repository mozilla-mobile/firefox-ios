/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

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

func getMicrosecondFrecencySQL(visitDateColumn: String, visitCountColumn: String) -> String {
    let now = NSDate().timeIntervalSince1970
    let age = "(\(now) - (\(visitDateColumn) / 1000)) / 86400"
    return "\(visitCountColumn) * MAX(1, 100 * 225 / (\(age) * \(age) + 225))"
}

/**
 * The sqlite-backed implementation of the history protocol.
 */
public class SQLiteHistory: BrowserHistory {
    let db: BrowserDB
    private var ignoredSchemes = ["about"]

    required public init(db: BrowserDB) {
        self.db = db
        db.createOrUpdate(BrowserTable())
    }

    public func clear() -> Success {
        let s: Site? = nil
        var err: NSError? = nil

        // TODO: this should happen asynchronously.
        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            err = conn.executeChange("DELETE FROM visits", withArgs: nil)
            if err == nil {
                err = conn.executeChange("DELETE FROM history", withArgs: nil)
            }
            return 1
        }

        return failOrSucceed(err, "Clear")
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

    private func recordVisitedSite(site: Site) -> Success {
        var err: NSError? = nil

        // Don't store visits to sites with about: protocols
        if !shouldAdd(site.url) {
            return deferResult(IgnoredSiteError())
        }

        // TODO: at this point we need to 'shadow' the mirrored site, if the
        // remote is still authoritative.
        // For now, we just update-or-insert on our one and only table.
        // TODO: also set modified times.
        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            let update = "UPDATE history SET title = ? WHERE url = ?"
            let updateArgs: [AnyObject?]? = [site.title, site.url]
            err = conn.executeChange(update, withArgs: updateArgs)
            if err != nil {
                return 0
            }
            if conn.numberOfRowsModified > 0 {
                return conn.numberOfRowsModified
            }

            // Insert instead.
            let insert = "INSERT INTO history (guid, url, title) VALUES (?, ?, ?)"
            let insertArgs: [AnyObject?]? = [Bytes.generateGUID(), site.url, site.title]
            err = conn.executeChange(insert, withArgs: insertArgs)
            if err != nil {
                return 0
            }
            return 1
        }

        return failOrSucceed(err, "Record site")
    }

    private func addLocalVisitForExistingSite(visit: SiteVisit) -> Success {
        var err: NSError? = nil
        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            let insert = "INSERT INTO visits (siteID, date, type) VALUES (" +
                         "(SELECT id FROM history WHERE url = ?), ?, ?)"
            let realDate = NSNumber(unsignedLongLong: visit.date)
            let insertArgs: [AnyObject?]? = [visit.site.url, realDate, visit.type.rawValue]
            err = conn.executeChange(insert, withArgs: insertArgs)
            if err != nil {
                return 0
            }
            return 1
        }

        return failOrSucceed(err, "Record visit")
    }

    public func addLocalVisit(visit: SiteVisit) -> Success {
        return recordVisitedSite(visit.site)
         >>> { self.addLocalVisitForExistingSite(visit) }
    }

    public func getSitesByFrecencyWithLimit(limit: Int) -> Deferred<Result<Cursor<Site>>> {
        let frecencySQL = getMicrosecondFrecencySQL("visitDate", "visitCount")
        let orderBy = "ORDER BY \(frecencySQL) DESC "
        return self.getFilteredSitesWithLimit(limit, whereURLContains: nil, orderBy: orderBy)
    }

    public func getSitesByFrecencyWithLimit(limit: Int, whereURLContains filter: String) -> Deferred<Result<Cursor<Site>>> {
        let frecencySQL = getMicrosecondFrecencySQL("visitDate", "visitCount")
        let orderBy = "ORDER BY \(frecencySQL) DESC "
        return self.getFilteredSitesWithLimit(limit, whereURLContains: filter, orderBy: orderBy)
    }

    public func getSitesByLastVisit(limit: Int) -> Deferred<Result<Cursor<Site>>> {
        let orderBy = "ORDER BY visitDate DESC "
        return self.getFilteredSitesWithLimit(limit, whereURLContains: nil, orderBy: orderBy)
    }

    private class func basicHistoryColumnFactory(row: SDRow) -> Site {
        let id = row["historyID"] as! Int
        let url = row["url"] as! String
        let title = row["title"] as! String
        let guid = row["guid"] as! String

        let site = Site(url: url, title: title)
        site.guid = guid
        site.id = id

        if let visitDate = (row["visitDate"] as? NSNumber)?.unsignedLongLongValue {
            site.latestVisit = Visit(date: visitDate, type: VisitType.Unknown)
        }

        return site
    }

    private func getFilteredSitesWithLimit(limit: Int, whereURLContains filter: String?, orderBy: String) -> Deferred<Result<Cursor<Site>>> {

        let args: [AnyObject?]?
        let whereClause: String
        if let filter = filter {
            args = ["%\(filter)%", "%\(filter)%"]
            whereClause = " AND ((history.url LIKE ?) OR (history.title LIKE ?)) "
        } else {
            args = []
            whereClause = " "
        }

        let sql =
        "SELECT history.id AS historyID, history.url AS url, title, guid, " +
        "max(visits.date) AS visitDate, " +
        "count(visits.id) AS visitCount " +
        "FROM history, visits " +
        "WHERE history.id = visits.siteID " +
        whereClause +
        "GROUP BY history.id " +
        orderBy
        "LIMIT \(limit) "

        let factory = SQLiteHistory.basicHistoryColumnFactory
        func runQuery(conn: SQLiteDBConnection, inout err: NSError?) -> Cursor<Site> {
            return conn.executeQuery(sql, factory: factory, withArgs: args)
        }

        var err: NSError? = nil
        let cursor = db.withReadableConnection(&err, callback: runQuery)

        return deferResult(cursor)
    }
}
