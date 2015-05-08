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

/*
// Here's the Swift equivalent of the below.
func simulatedFrecency(now: MicrosecondTimestamp, then: MicrosecondTimestamp, visitCount: Int) -> Double {
    let ageMicroseconds = (now - then)
    let ageDays = Double(ageMicroseconds) / 86400000000.0         // In SQL the .0 does the coercion.
    let f = 100 * 225 / ((ageSeconds * ageSeconds) + 225)
    return Double(visitCount) * max(1.0, f)
}
*/

func getMicrosecondFrecencySQL(visitDateColumn: String, visitCountColumn: String) -> String {
    let now = NSDate.nowMicroseconds()
    let microsecondsPerDay = 86_400_000_000.0      // 1000 * 1000 * 60 * 60 * 24
    let ageDays = "(\(now) - (\(visitDateColumn))) / \(microsecondsPerDay)"
    return "\(visitCountColumn) * max(1, 100 * 225 / (\(ageDays) * \(ageDays) + 225))"
}

/**
 * The sqlite-backed implementation of the history protocol.
 */
public class SQLiteHistory: BrowserHistory {
    let db: BrowserDB
    let favicons: FaviconsTable<Favicon>

    private var ignoredSchemes = ["about"]

    required public init(db: BrowserDB) {
        self.db = db
        self.favicons = FaviconsTable<Favicon>()
        db.createOrUpdate(self.favicons)

        // BrowserTable exists only to perform create/update etc. operations -- it's not
        // a queryable thing that needs to stick around.
        db.createOrUpdate(BrowserTable())
    }

    public func clearHistory() -> Success {
        let s: Site? = nil
        var err: NSError? = nil

        // TODO: this should happen asynchronously.
        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            err = conn.executeChange("DELETE FROM visits", withArgs: nil)
            if err == nil {
                err = conn.executeChange("DELETE FROM faviconSites", withArgs: nil)
            }
            if err == nil {
                err = conn.executeChange("DELETE FROM history", withArgs: nil)
            }
            return 1
        }

        return failOrSucceed(err, "Clear")
    }

    private func isIgnoredURL(url: String) -> Bool {
        if let url = NSURL(string: url) {
            if let scheme = url.scheme {
                if let index = find(ignoredSchemes, scheme) {
                    return true
                }
            }
        }

        return false
    }

    func recordVisitedSite(site: Site) -> Success {
        var err: NSError? = nil

        // Don't store visits to sites with about: protocols
        if isIgnoredURL(site.url) {
            return deferResult(IgnoredSiteError())
        }

        // TODO: at this point we need to 'shadow' the mirrored site, if the
        // remote is still authoritative.
        // For now, we just update-or-insert on our one and only table.
        // TODO: also set modified times.
        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            let update = "UPDATE history SET title = ? WHERE url = ?"
            let updateArgs: Args? = [site.title, site.url]
            err = conn.executeChange(update, withArgs: updateArgs)
            if err != nil {
                return 0
            }
            if conn.numberOfRowsModified > 0 {
                return conn.numberOfRowsModified
            }

            // Insert instead.
            let insert = "INSERT INTO history (guid, url, title) VALUES (?, ?, ?)"
            let insertArgs: Args? = [Bytes.generateGUID(), site.url, site.title]
            err = conn.executeChange(insert, withArgs: insertArgs)
            if err != nil {
                return 0
            }
            return 1
        }

        return failOrSucceed(err, "Record site")
    }

    // TODO: thread siteID into this to avoid the need to do the lookup.
    func addLocalVisitForExistingSite(visit: SiteVisit) -> Success {
        var err: NSError? = nil
        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            let insert = "INSERT INTO visits (siteID, date, type) VALUES (" +
                         "(SELECT id FROM history WHERE url = ?), ?, ?)"
            let realDate = NSNumber(unsignedLongLong: visit.date)
            let insertArgs: Args? = [visit.site.url, realDate, visit.type.rawValue]
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
        return self.getFilteredSitesWithLimit(limit, whereURLContains: nil, orderBy: orderBy, includeIcon: true)
    }

    public func getSitesByFrecencyWithLimit(limit: Int, whereURLContains filter: String) -> Deferred<Result<Cursor<Site>>> {
        let frecencySQL = getMicrosecondFrecencySQL("visitDate", "visitCount")
        let orderBy = "ORDER BY \(frecencySQL) DESC "
        return self.getFilteredSitesWithLimit(limit, whereURLContains: filter, orderBy: orderBy, includeIcon: true)
    }

    public func getSitesByLastVisit(limit: Int) -> Deferred<Result<Cursor<Site>>> {
        let orderBy = "ORDER BY visitDate DESC "
        return self.getFilteredSitesWithLimit(limit, whereURLContains: nil, orderBy: orderBy, includeIcon: true)
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

    private class func iconHistoryColumnFactory(row: SDRow) -> Site {
        let site = basicHistoryColumnFactory(row)

        let iconURL = row["iconURL"] as? String
        if let iconType = row["iconType"] as? Int,
            let iconURL = iconURL,
            let iconDate = row["iconDate"] as? Double,
            let iconID = row["iconID"] as? Int {
                let date = NSDate(timeIntervalSince1970: iconDate)
                let icon = Favicon(url: iconURL, date: date, type: IconType(rawValue: iconType)!)
                site.icon = icon
        }

        return site
    }

    private func runQuery<T>(sql: String, args: Args?, factory: (SDRow) -> T) -> Deferred<Result<Cursor<T>>> {
        func f(conn: SQLiteDBConnection, inout err: NSError?) -> Cursor<T> {
            return conn.executeQuery(sql, factory: factory, withArgs: args)
        }

        var err: NSError? = nil
        let cursor = db.withReadableConnection(&err, callback: f)

        return deferResult(cursor)
    }

    private func getFilteredSitesWithLimit(limit: Int, whereURLContains filter: String?, orderBy: String, includeIcon: Bool) -> Deferred<Result<Cursor<Site>>> {
        let args: Args?
        let whereClause: String
        if let filter = filter {
            args = ["%\(filter)%", "%\(filter)%"]
            whereClause = " WHERE ((history.url LIKE ?) OR (history.title LIKE ?)) "
        } else {
            args = []
            whereClause = " "
        }

        let historySQL =
        "SELECT history.id AS historyID, history.url AS url, title, guid, " +
        "max(visits.date) AS visitDate, " +
        "count(visits.id) AS visitCount " +
        "FROM history INNER JOIN visits ON visits.siteID = history.id " +
        whereClause +
        "GROUP BY history.id " +
        orderBy
        "LIMIT \(limit) "

        if includeIcon {
            // We select the history items then immediately join to get the largest icon.
            // We do this so that we limit and filter *before* joining against icons.
            let sql = "SELECT " +
                "historyID, url, title, guid, visitDate, visitCount " +
                "iconID, iconURL, iconDate, iconType, iconWidth " +
                "FROM (\(historySQL)) LEFT OUTER JOIN " +
                "view_history_id_favicon ON historyID = view_history_id_favicon.id"
            let factory = SQLiteHistory.iconHistoryColumnFactory
            return self.runQuery(sql, args: args, factory: factory)
        }

        let factory = SQLiteHistory.basicHistoryColumnFactory
        return self.runQuery(historySQL, args: args, factory: factory)
    }
}

extension SQLiteHistory: Favicons {
    public func clearFavicons() -> Success {
        var err: NSError? = nil

        // TODO: this should happen asynchronously.
        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            err = conn.executeChange("DELETE FROM faviconSites", withArgs: nil)
            if err == nil {
                err = conn.executeChange("DELETE FROM favicons", withArgs: nil)
            }
            return 1
        }

        return failOrSucceed(err, "Clear favicons")
    }

    public func addFavicon(icon: Favicon) -> Deferred<Result<Int>> {
        var err: NSError?
        let res = db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            // Blind!
            let id = self.favicons.insertOrUpdate(conn, obj: icon)
            return id ?? 0
        }
        if err == nil {
            return deferResult(res)
        }
        return deferResult(DatabaseError(err: err))
    }

    /**
     * This method assumes that the site has already been recorded
     * in the history table.
     */
    public func addFavicon(icon: Favicon, forSite site: Site) -> Deferred<Result<Int>> {
        log.verbose("Adding favicon \(icon.url) for site \(site.url).")
        func doChange(query: String, args: Args?) -> Deferred<Result<Int>> {
            var err: NSError?
            let res = db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
                // Blind!
                let id = self.favicons.insertOrUpdate(conn, obj: icon)

                // Now set up the mapping.
                err = conn.executeChange(query, withArgs: args)
                if let err = err {
                    log.error("Got error adding icon: \(err).")
                    return 0
                }

                return id ?? 0
            }

            if res == 0 {
                return deferResult(DatabaseError(err: err))
            }
            return deferResult(icon.id!)
        }

        let siteSubselect = "(SELECT id FROM history WHERE url = ?)"
        let iconSubselect = "(SELECT id FROM favicons WHERE url = ?)"
        let insertOrIgnore = "INSERT OR IGNORE INTO faviconSites(siteID, faviconID) VALUES "
        if let iconID = icon.id {
            // Easy!
            if let siteID = site.id {
                // So easy!
                let args: Args? = [siteID, iconID]
                return doChange("\(insertOrIgnore) (?, ?)", args)
            }

            // Nearly easy.
            let args: Args? = [site.url, iconID]
            return doChange("\(insertOrIgnore) (\(siteSubselect), ?)", args)

        }

        // Sigh.
        if let siteID = site.id {
            let args: Args? = [siteID, icon.url]
            return doChange("\(insertOrIgnore) (?, \(iconSubselect))", args)
        }

        // The worst.
        let args: Args? = [site.url, icon.url]
        return doChange("\(insertOrIgnore) (\(siteSubselect), \(iconSubselect))", args)
    }
}
