/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

private let log = Logger.syncLogger
public let TopSiteCacheSize: Int32 = 16

class NoSuchRecordError: MaybeErrorType {
    let guid: GUID
    init(guid: GUID) {
        self.guid = guid
    }
    var description: String {
        return "No such record: \(guid)."
    }
}

private var ignoredSchemes = ["about"]

public func isIgnoredURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme else { return false }

    if let _ = ignoredSchemes.index(of: scheme) {
        return true
    }

    if url.host == "localhost" {
        return true
    }

    return false
}

public func isIgnoredURL(_ url: String) -> Bool {
    if let url = URL(string: url) {
        return isIgnoredURL(url)
    }

    return false
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

// The constants in these functions were arrived at by utterly unscientific experimentation.

func getRemoteFrecencySQL() -> String {
    let visitCountExpression = "remoteVisitCount"
    let now = Date.nowMicroseconds()
    let microsecondsPerDay = 86_400_000_000.0      // 1000 * 1000 * 60 * 60 * 24
    let ageDays = "((\(now) - remoteVisitDate) / \(microsecondsPerDay))"

    return "\(visitCountExpression) * max(1, 100 * 110 / (\(ageDays) * \(ageDays) + 110))"
}

func getLocalFrecencySQL() -> String {
    let visitCountExpression = "((2 + localVisitCount) * (2 + localVisitCount))"
    let now = Date.nowMicroseconds()
    let microsecondsPerDay = 86_400_000_000.0      // 1000 * 1000 * 60 * 60 * 24
    let ageDays = "((\(now) - localVisitDate) / \(microsecondsPerDay))"

    return "\(visitCountExpression) * max(2, 100 * 225 / (\(ageDays) * \(ageDays) + 225))"
}

fileprivate func computeWordsWithFilter(_ filter: String) -> [String] {
    // Split filter on whitespace.
    let words = filter.components(separatedBy: .whitespaces)

    // Remove substrings and duplicates.
    // TODO: this can probably be improved.
    return words.enumerated().filter({ (index: Int, word: String) in
        if word.isEmpty {
            return false
        }

        for i in words.indices where i != index {
            if words[i].range(of: word) != nil && (words[i].count != word.count || i < index) {
                return false
            }
        }

        return true
    }).map({ $0.1 })
}

/**
 * Take input like "foo bar" and a template fragment and produce output like
 *
 *   ((x.y LIKE ?) OR (x.z LIKE ?)) AND ((x.y LIKE ?) OR (x.z LIKE ?))
 *
 * with args ["foo", "foo", "bar", "bar"].
 */
internal func computeWhereFragmentWithFilter(_ filter: String, perWordFragment: String, perWordArgs: (String) -> Args) -> (fragment: String, args: Args) {
    precondition(!filter.isEmpty)

    let words = computeWordsWithFilter(filter)
    return computeWhereFragmentForWords(words, perWordFragment: perWordFragment, perWordArgs: perWordArgs)
}

internal func computeWhereFragmentForWords(_ words: [String], perWordFragment: String, perWordArgs: (String) -> Args) -> (fragment: String, args: Args) {
    assert(!words.isEmpty)

    let fragment = Array(repeating: perWordFragment, count: words.count).joined(separator: " AND ")
    let args = words.flatMap(perWordArgs)
    return (fragment, args)
}

extension SDRow {
    func getTimestamp(_ column: String) -> Timestamp? {
        return (self[column] as? NSNumber)?.uint64Value
    }

    func getBoolean(_ column: String) -> Bool {
        if let val = self[column] as? Int {
            return val != 0
        }
        return false
    }
}

/**
 * The sqlite-backed implementation of the history protocol.
 */
open class SQLiteHistory {
    let db: BrowserDB
    let favicons: SQLiteFavicons
    let prefs: Prefs
    let clearTopSitesQuery: (String, Args?) = ("DELETE FROM \(TableCachedTopSites)", nil)

    required public init(db: BrowserDB, prefs: Prefs) {
        self.db = db
        self.favicons = SQLiteFavicons(db: self.db)
        self.prefs = prefs
    }
}

private let topSitesQuery = "SELECT \(TableCachedTopSites).*, \(TablePageMetadata).provider_name FROM \(TableCachedTopSites) LEFT OUTER JOIN \(TablePageMetadata) ON \(TableCachedTopSites).url = \(TablePageMetadata).site_url ORDER BY frecencies DESC LIMIT (?)"

/**
 * The init for this will perform the heaviest part of the frecency query
 * and create a temporary table that can be queried quickly. Currently this accounts for
 * >75% of the query time.
 * The scope/lifetime of this object is important as the data is 'frozen' until a new instance is created.
 */
fileprivate struct SQLiteFrecentHistory : FrecentHistory {
    private let db: BrowserDB
    private let prefs: Prefs

    init(db: BrowserDB, prefs: Prefs) {
        self.db = db
        self.prefs = prefs

        let empty = "DELETE FROM \(TempTableAwesomebarBookmarks)"
        let create =
            "CREATE TEMP TABLE IF NOT EXISTS \(TempTableAwesomebarBookmarks) (" +
                "guid TEXT, url TEXT, title TEXT, description TEXT, " +
        "faviconID INT, visitDate DATE)"
        let insert =
            "INSERT INTO \(TempTableAwesomebarBookmarks) " +
                "SELECT b.guid AS guid, b.url AS url, b.title AS title, " +
                "b.description AS description, b.faviconID AS faviconID, " +
                "h.visitDate AS visitDate " +
                "FROM \(ViewAwesomebarBookmarks) b " +
        "LEFT JOIN \(ViewHistoryVisits) h ON b.url = h.url"

        let _ = db.transaction { connection in
            try connection.executeChange(create)
            try connection.executeChange(empty)
            try connection.executeChange(insert)
        }
    }

    func getSites(whereURLContains filter: String?, historyLimit limit: Int, bookmarksLimit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        let factory = SQLiteHistory.basicHistoryColumnFactory

        let params = FrecencyQueryParams.urlCompletion(bookmarksLimit: bookmarksLimit, whereURLContains: filter ?? "", groupClause: "GROUP BY historyID ")
        let (query, args) = getFrecencyQuery(historyLimit: limit, params: params)

        return db.runQuery(query, args: args, factory: factory)
    }

    func updateTopSitesCacheQuery() -> (String, Args?) {
        let limit = Int(prefs.intForKey(PrefsKeys.KeyTopSitesCacheSize) ?? TopSiteCacheSize)

        let (whereData, groupBy) = topSiteClauses()
        let params = FrecencyQueryParams.topSites(groupClause: groupBy, whereData: whereData)
        let (frecencyQuery, args) = getFrecencyQuery(historyLimit: limit, params: params)

        // We must project, because we get bookmarks in these results.
        let insertQuery = [
            "WITH siteFrecency AS (\(frecencyQuery))",
            "INSERT INTO \(TableCachedTopSites)",
            "SELECT historyID, url, title, guid, domain_id, domain,",
            "localVisitDate, remoteVisitDate, localVisitCount, remoteVisitCount,",
            "iconID, iconURL, iconDate, iconType, iconWidth, frecencies",
            "FROM (SELECT * FROM",
            "siteFrecency LEFT JOIN view_history_id_favicon ON",
            "siteFrecency.historyID = view_history_id_favicon.id)"
            ].joined(separator: " ")

        // @TODO: remove the LEFT JOIN to fill in the icon columns, it is just there because the code has been doing this historically.
        // Those favicon data columns are not used, and view_history_id_favicon appears to only contain null data.

        return (insertQuery, args)
    }

    private func topSiteClauses() -> (String, String) {
        let whereData = "(\(TableDomains).showOnTopSites IS 1) AND (\(TableDomains).domain NOT LIKE 'r.%') AND (\(TableDomains).domain NOT LIKE 'google.%') "
        let groupBy = "GROUP BY domain_id "
        return (whereData, groupBy)
    }


    enum FrecencyQueryParams {
        case urlCompletion(bookmarksLimit: Int, whereURLContains: String, groupClause: String)
        case topSites(groupClause: String, whereData: String)
    }

    private func getFrecencyQuery(historyLimit: Int, params: FrecencyQueryParams) -> (String, Args?) {
        let bookmarksLimit: Int
        let groupClause: String
        let whereData: String?
        let urlFilter: String?

        switch params {
        case let .urlCompletion(bmLimit, filter, group):
            bookmarksLimit = bmLimit
            urlFilter = filter
            groupClause = group
            whereData = nil
        case let .topSites(group, whereArg):
            bookmarksLimit = 0
            urlFilter = nil
            whereData = whereArg
            groupClause = group
        }

        let includeBookmarks = bookmarksLimit > 0
        let localFrecencySQL = getLocalFrecencySQL()
        let remoteFrecencySQL = getRemoteFrecencySQL()
        let sixMonthsInMicroseconds: UInt64 = 15_724_800_000_000      // 182 * 1000 * 1000 * 60 * 60 * 24
        let sixMonthsAgo = Date.nowMicroseconds() - sixMonthsInMicroseconds

        let args: Args
        let whereClause: String
        let whereFragment = (whereData == nil) ? "" : " AND (\(whereData!))"

        if let urlFilter = urlFilter?.trimmingCharacters(in: .whitespaces), !urlFilter.isEmpty {
            let perWordFragment = "((url LIKE ?) OR (title LIKE ?))"
            let perWordArgs: (String) -> Args = { ["%\($0)%", "%\($0)%"] }
            let (filterFragment, filterArgs) = computeWhereFragmentWithFilter(urlFilter, perWordFragment: perWordFragment, perWordArgs: perWordArgs)

            // No deleted item has a URL, so there is no need to explicitly add that here.
            whereClause = "WHERE (\(filterFragment))\(whereFragment)"

            if includeBookmarks {
                // We'll need them twice: once to filter history, and once to filter bookmarks.
                args = filterArgs + filterArgs
            } else {
                args = filterArgs
            }
        } else {
            whereClause = " WHERE (\(TableHistory).is_deleted = 0)\(whereFragment)"
            args = []
        }

        // Innermost: grab history items and basic visit/domain metadata.
        var ungroupedSQL =
            "SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, \(TableHistory).title AS title, \(TableHistory).guid AS guid, domain_id, domain" +
                ", COALESCE(max(case \(TableVisits).is_local when 1 then \(TableVisits).date else 0 end), 0) AS localVisitDate" +
                ", COALESCE(max(case \(TableVisits).is_local when 0 then \(TableVisits).date else 0 end), 0) AS remoteVisitDate" +
                ", COALESCE(sum(\(TableVisits).is_local), 0) AS localVisitCount" +
                ", COALESCE(sum(case \(TableVisits).is_local when 1 then 0 else 1 end), 0) AS remoteVisitCount" +
                " FROM \(TableHistory) " +
                "INNER JOIN \(TableDomains) ON \(TableDomains).id = \(TableHistory).domain_id " +
        "INNER JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id "

        if includeBookmarks {
            ungroupedSQL.append("LEFT JOIN \(ViewAllBookmarks) on \(ViewAllBookmarks).url = \(TableHistory).url ")
        }
        ungroupedSQL.append(whereClause.replacingOccurrences(of: "url", with: "\(TableHistory).url").replacingOccurrences(of: "title", with: "\(TableHistory).title"))
        if includeBookmarks {
            ungroupedSQL.append(" AND \(ViewAllBookmarks).url IS NULL")
        }
        ungroupedSQL.append(" GROUP BY historyID")

        // Next: limit to only those that have been visited at all within the last six months.
        // (Don't do that in the innermost: we want to get the full count, even if some visits are older.)
        // Discard all but the 1000 most frecent.
        // Compute and return the frecency for all 1000 URLs.
        let frecenciedSQL =
            "SELECT *, (\(localFrecencySQL) + \(remoteFrecencySQL)) AS frecency" +
                " FROM (" + ungroupedSQL + ")" +
                " WHERE (" +
                "((localVisitCount > 0) OR (remoteVisitCount > 0)) AND " +                         // Eliminate dead rows from coalescing.
                "((localVisitDate > \(sixMonthsAgo)) OR (remoteVisitDate > \(sixMonthsAgo)))" +    // Exclude really old items.
                ") ORDER BY frecency DESC" +
        " LIMIT 1000"                                 // Don't even look at a huge set. This avoids work.

        // Next: merge by domain and select the URL with the max frecency of a domain, ordering by that sum frecency and reducing to a (typically much lower) limit.
        // NOTE: When using GROUP BY we need to be explicit about which URL to use when grouping. By using "max(frecency)" the result row
        //       for that domain will contain the projected URL corresponding to the history item with the max frecency, https://sqlite.org/lang_select.html#resultset
        //       This is the behavior we want in order to ensure that the most popular URL for a domain is used for the top sites tile.
        // TODO: make is_bookmarked here accurate by joining against ViewAllBookmarks.
        // TODO: ensure that the same URL doesn't appear twice in the list, either from duplicate
        //       bookmarks or from being in both bookmarks and history.
        let historySQL = [
            "SELECT historyID, url, title, guid, domain_id, domain,",
            "max(localVisitDate) AS localVisitDate,",
            "max(remoteVisitDate) AS remoteVisitDate,",
            "sum(localVisitCount) AS localVisitCount,",
            "sum(remoteVisitCount) AS remoteVisitCount,",
            "max(frecency) AS maxFrecency,",
            "sum(frecency) AS frecencies,",
            "0 AS is_bookmarked",
            "FROM (", frecenciedSQL, ") ",
            groupClause,
            "ORDER BY frecencies DESC",
            "LIMIT \(historyLimit)",
            ].joined(separator: " ")

        let bookmarksSQL = [
            "SELECT NULL AS historyID, url, title, guid, NULL AS domain_id, NULL AS domain,",
            "visitDate AS localVisitDate, 0 AS remoteVisitDate, 0 AS localVisitCount,",
            "0 AS remoteVisitCount,",
            "visitDate AS frecencies,",  // Fake this for ordering purposes.
            "0 as maxFrecency,", // Need this column for UNION
            "1 AS is_bookmarked",
            "FROM \(TempTableAwesomebarBookmarks)",
            whereClause,                  // The columns match, so we can reuse this.
            "GROUP BY url",
            "ORDER BY visitDate DESC LIMIT \(bookmarksLimit)",
            ].joined(separator: " ")

        if !includeBookmarks {
            return (historySQL, args)
        }

        let allSQL = "SELECT * FROM (SELECT * FROM (\(historySQL)) UNION SELECT * FROM (\(bookmarksSQL))) ORDER BY is_bookmarked DESC, frecencies DESC"
        return (allSQL, args)
    }
}

extension SQLiteHistory: BrowserHistory {
    public func removeSiteFromTopSites(_ site: Site) -> Success {
        if let host = (site.url as String).asURL?.normalizedHost {
            return self.removeHostFromTopSites(host)
        }
        return deferMaybe(DatabaseError(description: "Invalid url for site \(site.url)"))
    }

    public func removeFromPinnedTopSites(_ site: Site) -> Success {
        guard let host = (site.url as String).asURL?.normalizedHost else {
            return deferMaybe(DatabaseError(description: "Invalid url for site \(site.url)"))
        }

        //do a fuzzy delete so dupes can be removed
        let query: (String, Args?) = ("DELETE FROM \(TablePinnedTopSites) where domain = ?", [host])
        return db.run([query]) >>== {
            return self.db.run([("UPDATE \(TableDomains) set showOnTopSites = 1 WHERE domain = ?", [host])])
        }
    }

    public func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>> {
        let sql = "SELECT * from  \(TablePinnedTopSites) " +
        "LEFT OUTER JOIN view_history_id_favicon on historyID = view_history_id_favicon.id ORDER BY pinDate DESC"
        return db.runQuery(sql, args: [], factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
    }

    public func addPinnedTopSite(_ site: Site) -> Success { // needs test
        let now = Date.now()
        guard let guid = site.guid, let host = (site.url as String).asURL?.normalizedHost else {
            return deferMaybe(DatabaseError(description: "Invalid site \(site.url)"))
        }

        let args: Args = [site.url, now, site.title, site.id, guid, host]
        let arglist = BrowserDB.varlist(args.count)
        // Prevent the pinned site from being used in topsite calculations
        // We dont have to worry about this when removing a pin because the assumption is that a user probably doesnt want it being recommended as a topsite either
        return self.removeHostFromTopSites(host) >>== {
            return self.db.run([("INSERT OR REPLACE INTO \(TablePinnedTopSites)(url, pinDate, title, historyID, guid, domain) VALUES \(arglist)", args)])
        }
    }

    public func removeHostFromTopSites(_ host: String) -> Success {
        return db.run([("UPDATE \(TableDomains) set showOnTopSites = 0 WHERE domain = ?", [host])])
    }

    public func removeHistoryForURL(_ url: String) -> Success {
        let visitArgs: Args = [url]
        let deleteVisits = "DELETE FROM \(TableVisits) WHERE siteID = (SELECT id FROM \(TableHistory) WHERE url = ?)"

        let markArgs: Args = [Date.nowNumber(), url]
        let markDeleted = "UPDATE \(TableHistory) SET url = NULL, is_deleted = 1, should_upload = 1, local_modified = ? WHERE url = ?"
        //return db.run([(sql: String, args: Args?)])
        let command = [(sql: deleteVisits, args: visitArgs), (sql: markDeleted, args: markArgs), self.favicons.getCleanupFaviconsQuery()] as [(sql: String, args: Args?)]
        return db.run(command)
    }

    // Note: clearing history isn't really a sane concept in the presence of Sync.
    // This method should be split to do something else.
    // Bug 1162778.
    public func clearHistory() -> Success {
        return self.db.run([
            ("DELETE FROM \(TableVisits)", nil),
            ("DELETE FROM \(TableHistory)", nil),
            ("DELETE FROM \(TableDomains)", nil),
            ("DELETE FROM \(TablePageMetadata)", nil),
            self.favicons.getCleanupFaviconsQuery()
            ])
            // We've probably deleted a lot of stuff. Vacuum now to recover the space.
            >>> effect({ self.db.vacuum() })
    }

    func recordVisitedSite(_ site: Site) -> Success {
        // Don't store visits to sites with about: protocols
        if isIgnoredURL(site.url as String) {
            return deferMaybe(IgnoredSiteError())
        }

        return db.withConnection { conn -> Void in
            let now = Date.now()
            
            if self.updateSite(site, atTime: now, withConnection: conn) > 0 {
                return
            }
            
            // Insert instead.
            if self.insertSite(site, atTime: now, withConnection: conn) > 0 {
                return
            }
            
            let err = DatabaseError(description: "Unable to update or insert site; Invalid key returned")
            log.error("recordVisitedSite encountered an error: \(err.localizedDescription)")
            throw err
        }
    }

    func updateSite(_ site: Site, atTime time: Timestamp, withConnection conn: SQLiteDBConnection) -> Int {
        // We know we're adding a new visit, so we'll need to upload this record.
        // If we ever switch to per-visit change flags, this should turn into a CASE statement like
        //   CASE WHEN title IS ? THEN max(should_upload, 1) ELSE should_upload END
        // so that we don't flag this as changed unless the title changed.
        //
        // Note that we will never match against a deleted item, because deleted items have no URL,
        // so we don't need to unset is_deleted here.
        guard let host = (site.url as String).asURL?.normalizedHost else {
            return 0
        }

        let update = "UPDATE \(TableHistory) SET title = ?, local_modified = ?, should_upload = 1, domain_id = (SELECT id FROM \(TableDomains) where domain = ?) WHERE url = ?"
        let updateArgs: Args? = [site.title, time, host, site.url]
        if Logger.logPII {
            log.debug("Setting title to \(site.title) for URL \(site.url)")
        }
        do {
            try conn.executeChange(update, withArgs: updateArgs)
            return conn.numberOfRowsModified
        } catch let error as NSError {
            log.warning("Update failed with error: \(error.localizedDescription)")
            return 0
        }
    }

    fileprivate func insertSite(_ site: Site, atTime time: Timestamp, withConnection conn: SQLiteDBConnection) -> Int {
        if let host = (site.url as String).asURL?.normalizedHost {
            do {
                try conn.executeChange("INSERT OR IGNORE INTO \(TableDomains) (domain) VALUES (?)", withArgs: [host])
            } catch let error as NSError {
                log.warning("Domain insertion failed with \(error.localizedDescription)")
                return 0
            }

            let insert = "INSERT INTO \(TableHistory) " +
                         "(guid, url, title, local_modified, is_deleted, should_upload, domain_id) " +
                         "SELECT ?, ?, ?, ?, 0, 1, id FROM \(TableDomains) WHERE domain = ?"
            let insertArgs: Args? = [site.guid ?? Bytes.generateGUID(), site.url, site.title, time, host]
            do {
                try conn.executeChange(insert, withArgs: insertArgs)
            } catch let error as NSError {
                log.warning("Site insertion failed with \(error.localizedDescription)")
                return 0
            }

            return 1
        }

        if Logger.logPII {
            log.warning("Invalid URL \(site.url). Not stored in history.")
        }
        return 0
    }

    // TODO: thread siteID into this to avoid the need to do the lookup.
    func addLocalVisitForExistingSite(_ visit: SiteVisit) -> Success {
        return db.withConnection { conn -> Void in
            // INSERT OR IGNORE because we *might* have a clock error that causes a timestamp
            // collision with an existing visit, and it would really suck to error out for that reason.
            let insert = "INSERT OR IGNORE INTO \(TableVisits) (siteID, date, type, is_local) VALUES (" +
                         "(SELECT id FROM \(TableHistory) WHERE url = ?), ?, ?, 1)"
            let realDate = visit.date
            let insertArgs: Args? = [visit.site.url, realDate, visit.type.rawValue]

            try conn.executeChange(insert, withArgs: insertArgs)
        }
    }

    public func addLocalVisit(_ visit: SiteVisit) -> Success {
        return recordVisitedSite(visit.site)
         >>> { self.addLocalVisitForExistingSite(visit) }
    }

    public func getFrecentHistory() -> FrecentHistory {
        return SQLiteFrecentHistory(db: db, prefs: prefs)
    }

    public func getTopSitesWithLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        return self.db.runQuery(topSitesQuery, args: [limit], factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
    }

    public func setTopSitesNeedsInvalidation() {
        prefs.setBool(false, forKey: PrefsKeys.KeyTopSitesCacheIsValid)
    }

    public func setTopSitesCacheSize(_ size: Int32) {
        let oldValue = prefs.intForKey(PrefsKeys.KeyTopSitesCacheSize) ?? 0
        if oldValue != size {
            prefs.setInt(size, forKey: PrefsKeys.KeyTopSitesCacheSize)
            setTopSitesNeedsInvalidation()
        }
    }

    public func refreshTopSitesQuery() -> [(String, Args?)] {
        return [clearTopSitesQuery, getFrecentHistory().updateTopSitesCacheQuery()]
    }

    public func clearTopSitesCache() -> Success {
        return self.db.run([clearTopSitesQuery]) >>> {
            self.prefs.removeObjectForKey(PrefsKeys.KeyTopSitesCacheIsValid)
            return succeed()
        }
    }

    public func getSitesByLastVisit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        return self.getFilteredSitesByVisitDateWithLimit(limit, whereURLContains: nil, includeIcon: true)
    }

    fileprivate func getFilteredSitesByVisitDateWithLimit(_ limit: Int,
                                                          whereURLContains filter: String? = nil,
                                                          includeIcon: Bool = true) -> Deferred<Maybe<Cursor<Site>>> {
        let args: Args?
        let whereClause: String
        if let filter = filter?.trimmingCharacters(in: .whitespaces), !filter.isEmpty {
            let perWordFragment = "((\(TableHistory).url LIKE ?) OR (\(TableHistory).title LIKE ?))"
            let perWordArgs: (String) -> Args = { ["%\($0)%", "%\($0)%"] }
            let (filterFragment, filterArgs) = computeWhereFragmentWithFilter(filter, perWordFragment: perWordFragment, perWordArgs: perWordArgs)

            // No deleted item has a URL, so there is no need to explicitly add that here.
            whereClause = "WHERE (\(filterFragment))"
            args = filterArgs
        } else {
            whereClause = "WHERE (\(TableHistory).is_deleted = 0)"
            args = []
        }

        let sql = [
        "SELECT",
            "history.id AS historyID, history.url, title, guid, domain_id, domain,",
            "COALESCE(MAX(CASE visits.is_local WHEN 1 THEN visits.date ELSE 0 END), 0) AS localVisitDate,",
            "COALESCE(MAX(CASE visits.is_local WHEN 0 THEN visits.date ELSE 0 END), 0) AS remoteVisitDate,",
            "COALESCE(COUNT(visits.is_local), 0) AS visitCount",
            includeIcon ? ", iconID, iconURL, iconDate, iconType, iconWidth" : "",
        "FROM",
            "history",
                "INNER JOIN domains ON domains.id = history.domain_id",
                "INNER JOIN visits ON visits.siteID = history.id",
                includeIcon ? "LEFT OUTER JOIN view_history_id_favicon ON view_history_id_favicon.id = history.id" : "",
        whereClause,
        "GROUP BY historyID",
        "HAVING COUNT(visits.is_local) > 0",
        "ORDER BY MAX(localVisitDate, remoteVisitDate) DESC",
        "LIMIT \(limit)",
        ].joined(separator: " ")
        
        let factory = includeIcon ? SQLiteHistory.iconHistoryColumnFactory : SQLiteHistory.basicHistoryColumnFactory
        return db.runQuery(sql, args: args, factory: factory)
    }

}

extension SQLiteHistory: Favicons {
    // These two getter functions are only exposed for testing purposes (and aren't part of the public interface).
    func getFaviconsForURL(_ url: String) -> Deferred<Maybe<Cursor<Favicon?>>> {
        let sql = "SELECT iconID AS id, iconURL AS url, iconDate AS date, iconType AS type, iconWidth AS width FROM " +
            "\(ViewWidestFaviconsForSites), \(TableHistory) WHERE " +
            "\(TableHistory).id = siteID AND \(TableHistory).url = ?"
        let args: Args = [url]
        return db.runQuery(sql, args: args, factory: SQLiteHistory.iconColumnFactory)
    }

    func getFaviconsForBookmarkedURL(_ url: String) -> Deferred<Maybe<Cursor<Favicon?>>> {
        let sql =
        "SELECT " +
        "  \(TableFavicons).id AS id" +
        ", \(TableFavicons).url AS url" +
        ", \(TableFavicons).date AS date" +
        ", \(TableFavicons).type AS type" +
        ", \(TableFavicons).width AS width" +
        " FROM \(TableFavicons), \(ViewBookmarksLocalOnMirror) AS bm" +
        " WHERE bm.faviconID = \(TableFavicons).id AND bm.bmkUri IS ?"
        let args: Args = [url]
        return db.runQuery(sql, args: args, factory: SQLiteHistory.iconColumnFactory)
    }

    public func getSitesForURLs(_ urls: [String]) -> Deferred<Maybe<Cursor<Site?>>> {
        let inExpression = urls.joined(separator: "\",\"")
        let sql = "SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, title, guid, iconID, iconURL, iconDate, iconType, iconWidth FROM " +
            "\(ViewWidestFaviconsForSites), \(TableHistory) WHERE " +
            "\(TableHistory).id = siteID AND \(TableHistory).url IN (\"\(inExpression)\")"
        let args: Args = []
        return db.runQuery(sql, args: args, factory: SQLiteHistory.iconHistoryColumnFactory)
    }

    public func clearAllFavicons() -> Success {
        return db.transaction { conn -> Void in
            try conn.executeChange("DELETE FROM \(TableFaviconSites)")
            try conn.executeChange("DELETE FROM \(TableFavicons)")
        }
    }

    public func addFavicon(_ icon: Favicon) -> Deferred<Maybe<Int>> {
        return self.favicons.insertOrUpdateFavicon(icon)
    }

    /**
     * This method assumes that the site has already been recorded
     * in the history table.
     */
    public func addFavicon(_ icon: Favicon, forSite site: Site) -> Deferred<Maybe<Int>> {
        if Logger.logPII {
            log.verbose("Adding favicon \(icon.url) for site \(site.url).")
        }
        func doChange(_ query: String, args: Args?) -> Deferred<Maybe<Int>> {
            return db.withConnection { conn -> Int in
                // Blind! We don't see failure here.
                let id = self.favicons.insertOrUpdateFaviconInTransaction(icon, conn: conn)

                // Now set up the mapping.
                try conn.executeChange(query, withArgs: args)

                // Try to update the favicon ID column in each bookmarks table. There can be
                // multiple bookmarks with a particular URI, and a mirror bookmark can be
                // locally changed, so either or both of these statements can update multiple rows.
                if let id = id {
                    icon.id = id

                    try? conn.executeChange("UPDATE \(TableBookmarksLocal) SET faviconID = ? WHERE bmkUri = ?", withArgs: [id, site.url])
                    try? conn.executeChange("UPDATE \(TableBookmarksMirror) SET faviconID = ? WHERE bmkUri = ?", withArgs: [id, site.url])

                    return id
                }

                let err = DatabaseError(description: "Error adding favicon. ID = 0")
                log.error("addFavicon(_:, forSite:) encountered an error: \(err.localizedDescription)")
                throw err
            }
        }

        let siteSubselect = "(SELECT id FROM \(TableHistory) WHERE url = ?)"
        let iconSubselect = "(SELECT id FROM \(TableFavicons) WHERE url = ?)"
        let insertOrIgnore = "INSERT OR IGNORE INTO \(TableFaviconSites)(siteID, faviconID) VALUES "
        if let iconID = icon.id {
            // Easy!
            if let siteID = site.id {
                // So easy!
                let args: Args? = [siteID, iconID]
                return doChange("\(insertOrIgnore) (?, ?)", args: args)
            }

            // Nearly easy.
            let args: Args? = [site.url, iconID]
            return doChange("\(insertOrIgnore) (\(siteSubselect), ?)", args: args)

        }

        // Sigh.
        if let siteID = site.id {
            let args: Args? = [siteID, icon.url]
            return doChange("\(insertOrIgnore) (?, \(iconSubselect))", args: args)
        }

        // The worst.
        let args: Args? = [site.url, icon.url]
        return doChange("\(insertOrIgnore) (\(siteSubselect), \(iconSubselect))", args: args)
    }
}

extension SQLiteHistory: SyncableHistory {
    /**
     * TODO:
     * When we replace an existing row, we want to create a deleted row with the old
     * GUID and switch the new one in -- if the old record has escaped to a Sync server,
     * we want to delete it so that we don't have two records with the same URL on the server.
     * We will know if it's been uploaded because it'll have a server_modified time.
     */
    public func ensurePlaceWithURL(_ url: String, hasGUID guid: GUID) -> Success {
        let args: Args = [guid, url, guid]

        // The additional IS NOT is to ensure that we don't do a write for no reason.
        return db.run("UPDATE \(TableHistory) SET guid = ? WHERE url = ? AND guid IS NOT ?", withArgs: args)
    }

    public func deleteByGUID(_ guid: GUID, deletedAt: Timestamp) -> Success {
        let args: Args = [guid]
        // This relies on ON DELETE CASCADE to remove visits.
        return db.run("DELETE FROM \(TableHistory) WHERE guid = ?", withArgs: args)
    }

    // Fails on non-existence.
    fileprivate func getSiteIDForGUID(_ guid: GUID) -> Deferred<Maybe<Int>> {
        let args: Args = [guid]
        let query = "SELECT id FROM history WHERE guid = ?"
        let factory: (SDRow) -> Int = { return $0["id"] as! Int }

        return db.runQuery(query, args: args, factory: factory)
            >>== { cursor in
                if cursor.count == 0 {
                    return deferMaybe(NoSuchRecordError(guid: guid))
                }
                return deferMaybe(cursor[0]!)
        }
    }

    public func storeRemoteVisits(_ visits: [Visit], forGUID guid: GUID) -> Success {
        return self.getSiteIDForGUID(guid)
            >>== { (siteID: Int) -> Success in
            let visitArgs = visits.map { (visit: Visit) -> Args in
                let realDate = visit.date
                let isLocal = 0
                let args: Args = [siteID, realDate, visit.type.rawValue, isLocal]
                return args
            }

            // Magic happens here. The INSERT OR IGNORE relies on the multi-column uniqueness
            // constraint on `visits`: we allow only one row for (siteID, date, type), so if a
            // local visit already exists, this silently keeps it. End result? Any new remote
            // visits are added with only one query, keeping any existing rows.
            return self.db.bulkInsert(TableVisits, op: .InsertOrIgnore, columns: ["siteID", "date", "type", "is_local"], values: visitArgs)
        }
    }

    fileprivate struct HistoryMetadata {
        let id: Int
        let serverModified: Timestamp?
        let localModified: Timestamp?
        let isDeleted: Bool
        let shouldUpload: Bool
        let title: String
    }

    fileprivate func metadataForGUID(_ guid: GUID) -> Deferred<Maybe<HistoryMetadata?>> {
        let select = "SELECT id, server_modified, local_modified, is_deleted, should_upload, title FROM \(TableHistory) WHERE guid = ?"
        let args: Args = [guid]
        let factory = { (row: SDRow) -> HistoryMetadata in
            return HistoryMetadata(
                id: row["id"] as! Int,
                serverModified: row.getTimestamp("server_modified"),
                localModified: row.getTimestamp("local_modified"),
                isDeleted: row.getBoolean("is_deleted"),
                shouldUpload: row.getBoolean("should_upload"),
                title: row["title"] as! String
            )
        }
        return db.runQuery(select, args: args, factory: factory) >>== { cursor in
            return deferMaybe(cursor[0])
        }
    }

    public func insertOrUpdatePlace(_ place: Place, modified: Timestamp) -> Deferred<Maybe<GUID>> {
        // One of these things will be true here.
        // 0. The item is new.
        //    (a) We have a local place with the same URL but a different GUID.
        //    (b) We have never visited this place locally.
        //    In either case, reconcile and proceed.
        // 1. The remote place is not modified when compared to our mirror of it. This
        //    can occur when we redownload after a partial failure.
        //    (a) And it's not modified locally, either. Nothing to do. Ideally we
        //        will short-circuit so we don't need to update visits. (TODO)
        //    (b) It's modified locally. Don't overwrite anything; let the upload happen.
        // 2. The remote place is modified (either title or visits).
        //    (a) And it's not locally modified. Update the local entry.
        //    (b) And it's locally modified. Preserve the title of whichever was modified last.
        //        N.B., this is the only instance where we compare two timestamps to see
        //        which one wins.

        // We use this throughout.
        let serverModified = modified

        // Check to see if our modified time is unchanged, if the record exists locally, etc.
        let insertWithMetadata = { (metadata: HistoryMetadata?) -> Deferred<Maybe<GUID>> in
            if let metadata = metadata {
                // The item exists locally (perhaps originally with a different GUID).
                if metadata.serverModified == modified {
                    log.verbose("History item \(place.guid) is unchanged; skipping insert-or-update.")
                    return deferMaybe(place.guid)
                }

                // Otherwise, the server record must have changed since we last saw it.
                if metadata.shouldUpload {
                    // Uh oh, it changed locally.
                    // This might well just be a visit change, but we can't tell. Usually this conflict is harmless.
                    log.debug("Warning: history item \(place.guid) changed both locally and remotely. Comparing timestamps from different clocks!")
                    if let localModified = metadata.localModified, localModified > modified {
                        log.debug("Local changes overriding remote.")

                        // Update server modified time only. (Though it'll be overwritten again after a successful upload.)
                        let update = "UPDATE \(TableHistory) SET server_modified = ? WHERE id = ?"
                        let args: Args = [serverModified, metadata.id]
                        return self.db.run(update, withArgs: args) >>> always(place.guid)
                    }

                    log.verbose("Remote changes overriding local.")
                    // Fall through.
                }

                // The record didn't change locally. Update it.
                log.verbose("Updating local history item for guid \(place.guid).")
                let update = "UPDATE \(TableHistory) SET title = ?, server_modified = ?, is_deleted = 0 WHERE id = ?"
                let args: Args = [place.title, serverModified, metadata.id]
                return self.db.run(update, withArgs: args) >>> always(place.guid)
            }

            // The record doesn't exist locally. Insert it.
            log.verbose("Inserting remote history item for guid \(place.guid).")
            if let host = place.url.asURL?.normalizedHost {
                if Logger.logPII {
                    log.debug("Inserting: \(place.url).")
                }

                let insertDomain = "INSERT OR IGNORE INTO \(TableDomains) (domain) VALUES (?)"
                let insertHistory = "INSERT INTO \(TableHistory) (guid, url, title, server_modified, is_deleted, should_upload, domain_id) " +
                                    "SELECT ?, ?, ?, ?, 0, 0, id FROM \(TableDomains) where domain = ?"
                return self.db.run([
                    (insertDomain, [host]),
                    (insertHistory, [place.guid, place.url, place.title, serverModified, host])
                ]) >>> always(place.guid)
            } else {
                // This is a URL with no domain. Insert it directly.
                if Logger.logPII {
                    log.debug("Inserting: \(place.url) with no domain.")
                }

                let insertHistory = "INSERT INTO \(TableHistory) (guid, url, title, server_modified, is_deleted, should_upload, domain_id) " +
                                    "VALUES (?, ?, ?, ?, 0, 0, NULL)"
                return self.db.run([
                    (insertHistory, [place.guid, place.url, place.title, serverModified])
                ]) >>> always(place.guid)
            }
        }

        // Make sure that we only need to compare GUIDs by pre-merging on URL.
        return self.ensurePlaceWithURL(place.url, hasGUID: place.guid)
            >>> { self.metadataForGUID(place.guid) >>== insertWithMetadata }
    }

    public func getDeletedHistoryToUpload() -> Deferred<Maybe<[GUID]>> {
        // Use the partial index on should_upload to make this nice and quick.
        let sql = "SELECT guid FROM \(TableHistory) WHERE \(TableHistory).should_upload = 1 AND \(TableHistory).is_deleted = 1"
        let f: (SDRow) -> String = { $0["guid"] as! String }

        return self.db.runQuery(sql, args: nil, factory: f) >>== { deferMaybe($0.asArray()) }
    }

    public func getModifiedHistoryToUpload() -> Deferred<Maybe<[(Place, [Visit])]>> {
        // What we want to do: find all history items that are flagged for upload, then find a number of recent visits for each item.
        // This was originally all in a single SQL query but was seperated into two to save some memory when returning back the cursor.
        return getModifiedHistory(limit: 1000) >>== { self.attachVisitsTo(places: $0, visitLimit: 20) }
    }

    private func getModifiedHistory(limit: Int) -> Deferred<Maybe<[Int: Place]>> {
        let sql =
        "SELECT id, guid, url, title " +
        "FROM \(TableHistory) " +
        "WHERE should_upload = 1 AND NOT is_deleted = 1 " +
        "ORDER BY id " +
        "LIMIT ?"

        var places = [Int: Place]()
        let placeFactory: (SDRow) -> Void = { row in
            let id = row["id"] as! Int
            let guid = row["guid"] as! String
            let url = row["url"] as! String
            let title = row["title"] as! String
            places[id] = Place(guid: guid, url: url, title: title)
        }

        let args: Args = [limit]
        return db.runQuery(sql, args: args, factory: placeFactory) >>> { deferMaybe(places) }
    }

    private func attachVisitsTo(places: [Int: Place], visitLimit: Int) -> Deferred<Maybe<[(Place, [Visit])]>> {
        // A difficulty here: we don't want to fetch *all* visits, only some number of the most recent.
        // (It's not enough to only get new ones, because the server record should contain more.)
        //
        // That's the greatest-N-per-group problem. We used to do this in SQL, joining
        // the visits table to a subselect of visits table, however, ran into OOM issues (Bug 1417034)
        //
        // Now, we want a more dumb approach with no joins in SQL and doing group-by-site and limit-to-N in swift.
        //
        // We do this in a single query, rather than the N+1 that desktop takes.
        //
        // We then need to flatten the cursor. We do that by collecting
        // places as a side-effect of the factory, producing visits as a result, and merging in memory.

        // Turn our lazy collection of integers into a comma-seperated string for the IN clause.
        let historyIDs = Array(places.keys)

        let sql =
                "SELECT siteID, date AS visitDate, type AS visitType " +
                "FROM \(TableVisits) " +
                "WHERE siteID IN (\(historyIDs.map(String.init).joined(separator: ","))) " +
                "ORDER BY siteID DESC, date DESC"

        // We want to get a tuple Visit and Place here. We can either have an explicit tuple factory
        // or we use an identity function, and make do without creating extra data structures.
        // Since we have a known Out Of Memory issue here, let's avoid extra data structures.
        let rowIdentity: (SDRow) -> SDRow = { $0 }

        // We'll need to runQueryUnsafe so we get a LiveSQLiteCursor, i.e. we don't get the cursor
        // contents into memory all at once.
        return db.runQueryUnsafe(sql, args: nil, factory: rowIdentity) { (cursor: Cursor<SDRow>) -> [Int: [Visit]] in
            // Accumulate a mapping of site IDs to list of visits. Each list should be shorter than visitLimit.
            // Seed our accumulator with empty lists since we already know which IDs we will be fetching.
            var visits = [Int: [Visit]]()
            historyIDs.forEach { visits[$0] = [] }

            // We need to iterate through these explicitly, without relying on the
            // factory.
            for row in cursor.makeIterator() {
                guard let row = row, cursor.status == .success else {
                    throw NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: cursor.statusMessage])
                }
                
                guard let id = row["siteID"] as? Int,
                    let existingCount = visits[id]?.count,
                    existingCount < visitLimit else {
                        continue
                }

                guard let date = row.getTimestamp("visitDate"),
                    let visitType = row["visitType"] as? Int,
                    let type = VisitType(rawValue: visitType) else {
                        continue
                }

                let visit = Visit(date: date, type: type)

                // Append the visits in descending date order, so we only get the
                // most recent top N.
                visits[id]?.append(visit)
            }

            return visits
        } >>== { visits in
            // Join up the places map we received as input with our visits map.
            let placesAndVisits: [(Place, [Visit])] = places.flatMap { id, place in
                guard let visitsList = visits[id], !visitsList.isEmpty else {
                    return nil
                }
                return (place, visitsList)
            }

            let recentVisitCount = placesAndVisits.reduce(0) { $0 + $1.1.count }

            log.info("Attaching \(placesAndVisits.count) places to \(recentVisitCount) most recent visits")
            return deferMaybe(placesAndVisits)
        }
    }

    public func markAsDeleted(_ guids: [GUID]) -> Success {
        if guids.isEmpty {
            return succeed()
        }

        log.debug("Wiping \(guids.count) deleted GUIDs.")
        return self.db.run(chunk(guids, by: BrowserDB.MaxVariableNumber).flatMap(markAsDeletedStatementForGUIDs))
    }

    fileprivate func markAsDeletedStatementForGUIDs(_ guids: ArraySlice<String>) -> (String, Args?) {
        // We deliberately don't limit this to records marked as should_upload, just
        // in case a coding error leaves records with is_deleted=1 but not flagged for
        // upload -- this will catch those and throw them away.
        let inClause = BrowserDB.varlist(guids.count)
        let sql = "DELETE FROM \(TableHistory) WHERE is_deleted = 1 AND guid IN \(inClause)"

        let args: Args = guids.map { $0 }
        return (sql, args)
    }

    public func markAsSynchronized(_ guids: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>> {
        if guids.isEmpty {
            return deferMaybe(modified)
        }

        log.debug("Marking \(guids.count) GUIDs as synchronized. Returning timestamp \(modified).")
        return self.db.run(chunk(guids, by: BrowserDB.MaxVariableNumber).flatMap { chunk in
            return markAsSynchronizedStatementForGUIDs(chunk, modified: modified)
        }) >>> always(modified)
    }

    fileprivate func markAsSynchronizedStatementForGUIDs(_ guids: ArraySlice<String>, modified: Timestamp) -> (String, Args?) {
        let inClause = BrowserDB.varlist(guids.count)
        let sql =
        "UPDATE \(TableHistory) SET " +
        "should_upload = 0, server_modified = \(modified) " +
        "WHERE guid IN \(inClause)"

        let args: Args = guids.map { $0 }
        return (sql, args)
    }

    public func doneApplyingRecordsAfterDownload() -> Success {
        self.db.checkpoint()
        return succeed()
    }

    public func doneUpdatingMetadataAfterUpload() -> Success {
        self.db.checkpoint()
        return succeed()
    }
}

extension SQLiteHistory {
    // Returns a deferred `true` if there are rows in the DB that have a server_modified time.
    // Because we clear this when we reset or remove the account, and never set server_modified
    // without syncing, the presence of matching rows directly indicates that a deletion
    // would be synced to the server.
    public func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
        return self.db.queryReturnsResults("SELECT 1 FROM \(TableHistory) WHERE server_modified IS NOT NULL LIMIT 1")
    }
}

extension SQLiteHistory: ResettableSyncStorage {
    // We don't drop deletions when we reset -- we might need to upload a deleted item
    // that never made it to the server.
    public func resetClient() -> Success {
        let flag = "UPDATE \(TableHistory) SET should_upload = 1, server_modified = NULL"
        return self.db.run(flag)
    }
}

extension SQLiteHistory: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        log.info("Clearing history metadata and deleted items after account removal.")
        let discard = "DELETE FROM \(TableHistory) WHERE is_deleted = 1"
        return self.db.run(discard) >>> self.resetClient
    }
}
