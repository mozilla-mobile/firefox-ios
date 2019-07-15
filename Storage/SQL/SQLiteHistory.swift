/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

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

    if let _ = ignoredSchemes.firstIndex(of: scheme) {
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

fileprivate func escapeFTSSearchString(_ search: String) -> String {
    // Remove double-quotes, split search string on whitespace
    // and remove any empty strings
    let words = search.replacingOccurrences(of: "\"", with: "").components(separatedBy: .whitespaces).filter({ !$0.isEmpty })

    // If there's only one word, ensure it is longer than 2
    // characters. Otherwise, form a different type of search
    // string to attempt to match the start of URLs.
    guard words.count > 1 else {
        guard let word = words.first else {
            return ""
        }

        let charThresholdForSearchAll = 2
        if word.count > charThresholdForSearchAll {
            return "\"\(word)*\""
        } else {
            let titlePrefix = "title: \"^"
            let httpPrefix = "url: \"^http://"
            let httpsPrefix = "url: \"^https://"

            return [titlePrefix,
                    httpPrefix,
                    httpsPrefix,
                    httpPrefix + "www.",
                    httpsPrefix + "www.",
                    httpPrefix + "m.",
                    httpsPrefix + "m."]
                .map({ "\($0)\(word)*\"" })
                .joined(separator: " OR ")
        }
    }

    // Remove empty strings, wrap each word in double-quotes, append
    // "*", then join it all back together. For words with fewer than
    // three characters, anchor the search to the beginning of word
    // bounds by prepending "^".
    // Example: "foo bar a b" -> "\"foo*\"\"bar*\"\"^a*\"\"^b*\""
    return words.map({ "\"\($0)*\"" }).joined()
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
    let clearTopSitesQuery: (String, Args?) = ("DELETE FROM cached_top_sites", nil)

    required public init(db: BrowserDB, prefs: Prefs) {
        self.db = db
        self.favicons = SQLiteFavicons(db: self.db)
        self.prefs = prefs
    }

    public func getSites(forURLs urls: [String]) -> Deferred<Maybe<Cursor<Site?>>> {
        let inExpression = urls.joined(separator: "\",\"")
        let sql = """
        SELECT history.id AS historyID, history.url AS url, title, guid, iconID, iconURL, iconDate, iconType, iconWidth
        FROM view_favicons_widest, history
        WHERE history.id = siteID AND history.url IN (\"\(inExpression)\")
        """

        let args: Args = []
        return db.runQueryConcurrently(sql, args: args, factory: SQLiteHistory.iconHistoryColumnFactory)
    }
}

private let topSitesQuery = "SELECT cached_top_sites.*, page_metadata.provider_name FROM cached_top_sites LEFT OUTER JOIN page_metadata ON cached_top_sites.url = page_metadata.site_url ORDER BY frecencies DESC LIMIT (?)"

/**
 * The init for this will perform the heaviest part of the frecency query
 * and create a temporary table that can be queried quickly. Currently this accounts for
 * >75% of the query time.
 * The scope/lifetime of this object is important as the data is 'frozen' until a new instance is created.
 */
fileprivate struct SQLiteFrecentHistory: FrecentHistory {
    private let db: BrowserDB
    private let prefs: Prefs

    init(db: BrowserDB, prefs: Prefs) {
        self.db = db
        self.prefs = prefs

        let empty = "DELETE FROM \(MatViewAwesomebarBookmarksWithFavicons)"

        let insert = """
            INSERT INTO \(MatViewAwesomebarBookmarksWithFavicons)
            SELECT
                guid, url, title, description, visitDate,
                iconID, iconURL, iconDate, iconType, iconWidth
            FROM \(ViewAwesomebarBookmarksWithFavicons)
            """

        _ = db.transaction { connection in
            try connection.executeChange(empty)
            try connection.executeChange(insert)
        }
    }

    func getSites(matchingSearchQuery filter: String?, limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        let factory = SQLiteHistory.iconHistoryColumnFactory

        let params = FrecencyQueryParams.urlCompletion(whereURLContains: filter ?? "", groupClause: "GROUP BY historyID ")
        let (query, args) = getFrecencyQuery(limit: limit, params: params)

        return db.runQueryConcurrently(query, args: args, factory: factory)
    }

    fileprivate func updateTopSitesCacheQuery() -> (String, Args?) {
        let limit = Int(prefs.intForKey(PrefsKeys.KeyTopSitesCacheSize) ?? TopSiteCacheSize)
        let (topSitesQuery, args) = getTopSitesQuery(historyLimit: limit)

        let insertQuery = """
            WITH siteFrecency AS (\(topSitesQuery))
            INSERT INTO cached_top_sites
            SELECT
                historyID, url, title, guid, domain_id, domain,
                localVisitDate, remoteVisitDate, localVisitCount, remoteVisitCount,
                iconID, iconURL, iconDate, iconType, iconWidth, frecencies
            FROM siteFrecency LEFT JOIN view_favicons_widest ON
                siteFrecency.historyID = view_favicons_widest.siteID
            """

        return (insertQuery, args)
    }

    private func topSiteClauses() -> (String, String) {
        let whereData = "(domains.showOnTopSites IS 1) AND (domains.domain NOT LIKE 'r.%') AND (domains.domain NOT LIKE 'google.%') "
        let groupBy = "GROUP BY domain_id "
        return (whereData, groupBy)
    }

    enum FrecencyQueryParams {
        case urlCompletion(whereURLContains: String, groupClause: String)
        case topSites(groupClause: String, whereData: String)
    }

    private func getFrecencyQuery(limit: Int, params: FrecencyQueryParams) -> (String, Args?) {
        let groupClause: String
        let whereData: String?
        let urlFilter: String?

        switch params {
        case let .urlCompletion(filter, group):
            urlFilter = filter
            groupClause = group
            whereData = nil
        case let .topSites(group, whereArg):
            urlFilter = nil
            whereData = whereArg
            groupClause = group
        }

        let localFrecencySQL = getLocalFrecencySQL()
        let remoteFrecencySQL = getRemoteFrecencySQL()
        let sixMonthsInMicroseconds: UInt64 = 15_724_800_000_000      // 182 * 1000 * 1000 * 60 * 60 * 24
        let sixMonthsAgo = Date.nowMicroseconds() - sixMonthsInMicroseconds

        let args: Args
        let ftsWhereClause: String
        let whereFragment = (whereData == nil) ? "" : " AND (\(whereData!))"

        if let urlFilter = urlFilter?.trimmingCharacters(in: .whitespaces), !urlFilter.isEmpty {
            // No deleted item has a URL, so there is no need to explicitly add that here.
            ftsWhereClause = " WHERE (history_fts MATCH ?)\(whereFragment)"
            args = [escapeFTSSearchString(urlFilter)]
        } else {
            ftsWhereClause = " WHERE (history.is_deleted = 0)\(whereFragment)"
            args = []
        }

        // Innermost: grab history items and basic visit/domain metadata.
        let ungroupedSQL = """
            SELECT history.id AS historyID, history.url AS url,
                history.title AS title, history.guid AS guid, domain_id, domain,
                coalesce(max(CASE visits.is_local WHEN 1 THEN visits.date ELSE 0 END), 0) AS localVisitDate,
                coalesce(max(CASE visits.is_local WHEN 0 THEN visits.date ELSE 0 END), 0) AS remoteVisitDate,
                coalesce(sum(visits.is_local), 0) AS localVisitCount,
                coalesce(sum(CASE visits.is_local WHEN 1 THEN 0 ELSE 1 END), 0) AS remoteVisitCount
            FROM history
                INNER JOIN domains ON
                    domains.id = history.domain_id
                INNER JOIN visits ON
                    visits.siteID = history.id
                INNER JOIN history_fts ON
                    history_fts.rowid = history.rowid
            \(ftsWhereClause)
            GROUP BY historyID
            """

        // Next: limit to only those that have been visited at all within the last six months.
        // (Don't do that in the innermost: we want to get the full count, even if some visits are older.)
        // Discard all but the 1000 most frecent.
        // Compute and return the frecency for all 1000 URLs.
        let frecenciedSQL = """
            SELECT *, (\(localFrecencySQL) + \(remoteFrecencySQL)) AS frecency
            FROM (\(ungroupedSQL))
            WHERE (
                -- Eliminate dead rows from coalescing.
                ((localVisitCount > 0) OR (remoteVisitCount > 0)) AND
                -- Exclude really old items.
                ((localVisitDate > \(sixMonthsAgo)) OR (remoteVisitDate > \(sixMonthsAgo)))
            )
            ORDER BY frecency DESC
            -- Don't even look at a huge set. This avoids work.
            LIMIT 1000
            """

        // Next: merge by domain and select the URL with the max frecency of a domain, ordering by that sum frecency and reducing to a (typically much lower) limit.
        // NOTE: When using GROUP BY we need to be explicit about which URL to use when grouping. By using "max(frecency)" the result row
        //       for that domain will contain the projected URL corresponding to the history item with the max frecency, https://sqlite.org/lang_select.html#resultset
        //       This is the behavior we want in order to ensure that the most popular URL for a domain is used for the top sites tile.
        // TODO: make is_bookmarked here accurate by joining against ViewAllBookmarks.
        // TODO: ensure that the same URL doesn't appear twice in the list, either from duplicate
        //       bookmarks or from being in both bookmarks and history.
        let historySQL = """
            SELECT historyID, url, title, guid, domain_id, domain,
                max(localVisitDate) AS localVisitDate,
                max(remoteVisitDate) AS remoteVisitDate,
                sum(localVisitCount) AS localVisitCount,
                sum(remoteVisitCount) AS remoteVisitCount,
                max(frecency) AS maxFrecency,
                sum(frecency) AS frecencies,
                0 AS is_bookmarked
            FROM (\(frecenciedSQL))
            \(groupClause)
            ORDER BY frecencies DESC
            LIMIT \(limit)
            """

        let allSQL = """
            SELECT * FROM (\(historySQL)) AS hb
            LEFT OUTER JOIN view_favicons_widest ON view_favicons_widest.siteID = hb.historyID
            ORDER BY is_bookmarked DESC, frecencies DESC
            """
        return (allSQL, args)
    }

    private func getTopSitesQuery(historyLimit: Int) -> (String, Args?) {
        let localFrecencySQL = getLocalFrecencySQL()
        let remoteFrecencySQL = getRemoteFrecencySQL()

        // Innermost: grab history items and basic visit/domain metadata.
        let ungroupedSQL = """
            SELECT history.id AS historyID, history.url AS url,
                history.title AS title, history.guid AS guid, domain_id, domain,
                coalesce(max(CASE visits.is_local WHEN 1 THEN visits.date ELSE 0 END), 0) AS localVisitDate,
                coalesce(max(CASE visits.is_local WHEN 0 THEN visits.date ELSE 0 END), 0) AS remoteVisitDate,
                coalesce(sum(visits.is_local), 0) AS localVisitCount,
                coalesce(sum(CASE visits.is_local WHEN 1 THEN 0 ELSE 1 END), 0) AS remoteVisitCount
            FROM history
                INNER JOIN (
                    SELECT siteID FROM (
                        SELECT COUNT(rowid) AS visitCount, siteID
                        FROM visits
                        GROUP BY siteID
                        ORDER BY visitCount DESC
                        LIMIT 5000
                    )
                    UNION ALL
                    SELECT siteID FROM (
                        SELECT siteID
                        FROM visits
                        GROUP BY siteID
                        ORDER BY max(date) DESC
                        LIMIT 1000
                    )
                ) AS groupedVisits ON
                    groupedVisits.siteID = history.id
                INNER JOIN domains ON
                    domains.id = history.domain_id
                INNER JOIN visits ON
                    visits.siteID = history.id
            WHERE (history.is_deleted = 0) AND ((domains.showOnTopSites IS 1) AND (domains.domain NOT LIKE 'r.%') AND (domains.domain NOT LIKE 'google.%')) AND (history.url LIKE 'http%')
            GROUP BY historyID
            """

        let frecenciedSQL = """
            SELECT *, (\(localFrecencySQL) + \(remoteFrecencySQL)) AS frecency
            FROM (\(ungroupedSQL))
            """

        let historySQL = """
            SELECT historyID, url, title, guid, domain_id, domain,
                max(localVisitDate) AS localVisitDate,
                max(remoteVisitDate) AS remoteVisitDate,
                sum(localVisitCount) AS localVisitCount,
                sum(remoteVisitCount) AS remoteVisitCount,
                max(frecency) AS maxFrecency,
                sum(frecency) AS frecencies,
                0 AS is_bookmarked
            FROM (\(frecenciedSQL))
            GROUP BY domain_id
            ORDER BY frecencies DESC
            LIMIT \(historyLimit)
            """

        return (historySQL, nil)
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
        let query: (String, Args?) = ("DELETE FROM pinned_top_sites where domain = ?", [host])
        return db.run([query]) >>== {
            return self.db.run([("UPDATE domains SET showOnTopSites = 1 WHERE domain = ?", [host])])
        }
    }

    public func isPinnedTopSite(_ url: String) -> Deferred<Maybe<Bool>> {
        let sql = """
        SELECT * FROM pinned_top_sites
        WHERE url = ?
        LIMIT 1
        """
        let args: Args = [url]
        return self.db.queryReturnsResults(sql, args: args)
    }

    public func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>> {
        let sql = """
            SELECT * FROM pinned_top_sites LEFT OUTER JOIN view_favicons_widest ON
                historyID = view_favicons_widest.siteID
            ORDER BY pinDate DESC
            """
        return db.runQueryConcurrently(sql, args: [], factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
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
            return self.db.run([("INSERT OR REPLACE INTO pinned_top_sites (url, pinDate, title, historyID, guid, domain) VALUES \(arglist)", args)])
        }
    }

    public func removeHostFromTopSites(_ host: String) -> Success {
        return db.run([("UPDATE domains SET showOnTopSites = 0 WHERE domain = ?", [host])])
    }

    public func removeHistoryForURL(_ url: String) -> Success {
        let visitArgs: Args = [url]
        let deleteVisits = "DELETE FROM visits WHERE siteID = (SELECT id FROM history WHERE url = ?)"

        let markArgs: Args = [Date.nowNumber(), url]
        let markDeleted = "UPDATE history SET url = NULL, is_deleted = 1, title = '', should_upload = 1, local_modified = ? WHERE url = ?"

        return db.run([
            (sql: deleteVisits, args: visitArgs),
            (sql: markDeleted, args: markArgs),
            favicons.getCleanupFaviconsQuery(),
            favicons.getCleanupFaviconSiteURLsQuery()
        ])
    }

    public func removeHistoryFromDate(_ date: Date) -> Success {
        let visitTimestamp = date.toMicrosecondTimestamp()

        let historyRemoval = """
            WITH deletionIds as (SELECT history.id from history INNER JOIN visits on history.id = visits.siteID WHERE visits.date > ?)
            UPDATE history SET url = NULL, is_deleted=1, title = '', should_upload = 1, local_modified = ?
            WHERE history.id in deletionIds
        """
        let historyRemovalArgs: Args = [visitTimestamp, Date.nowNumber()]

        let visitRemoval = "DELETE FROM visits WHERE visits.date > ?"
        let visitRemovalArgs: Args = [visitTimestamp]

        return db.run([
            (sql: historyRemoval, args: historyRemovalArgs),
            (sql: visitRemoval, args: visitRemovalArgs),
            favicons.getCleanupFaviconsQuery(),
            favicons.getCleanupFaviconSiteURLsQuery()
        ])
    }

    // Note: clearing history isn't really a sane concept in the presence of Sync.
    // This method should be split to do something else.
    // Bug 1162778.
    public func clearHistory() -> Success {
        return self.db.run([
            ("DELETE FROM visits", nil),
            ("DELETE FROM history", nil),
            ("DELETE FROM domains", nil),
            ("DELETE FROM page_metadata", nil),
            ("DELETE FROM favicon_site_urls", nil),
            ("DELETE FROM favicons", nil),
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

        let update = "UPDATE history SET title = ?, local_modified = ?, should_upload = 1, domain_id = (SELECT id FROM domains where domain = ?) WHERE url = ?"
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
                try conn.executeChange("INSERT OR IGNORE INTO domains (domain) VALUES (?)", withArgs: [host])
            } catch let error as NSError {
                log.warning("Domain insertion failed with \(error.localizedDescription)")
                return 0
            }

            let insert = """
                INSERT INTO history (
                    guid, url, title, local_modified, is_deleted, should_upload, domain_id
                )
                SELECT ?, ?, ?, ?, 0, 1, id FROM domains WHERE domain = ?
                """

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
            let insert = """
                INSERT OR IGNORE INTO visits (
                    siteID, date, type, is_local
                ) VALUES (
                    (SELECT id FROM history WHERE url = ?), ?, ?, 1
                )
                """

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
        return self.db.runQueryConcurrently(topSitesQuery, args: [limit], factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
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

    public func getSitesByLastVisit(limit: Int, offset: Int) -> Deferred<Maybe<Cursor<Site>>> {
        let sql = """
            SELECT
                history.id AS historyID, history.url, title, guid, domain_id, domain,
                coalesce(max(CASE visits.is_local WHEN 1 THEN visits.date ELSE 0 END), 0) AS localVisitDate,
                coalesce(max(CASE visits.is_local WHEN 0 THEN visits.date ELSE 0 END), 0) AS remoteVisitDate,
                coalesce(count(visits.is_local), 0) AS visitCount
                , iconID, iconURL, iconDate, iconType, iconWidth
            FROM history
                INNER JOIN (
                    SELECT siteID, max(date) AS latestVisitDate
                    FROM visits
                    GROUP BY siteID
                    ORDER BY latestVisitDate DESC
                    LIMIT \(limit)
                    OFFSET \(offset)
                ) AS latestVisits ON
                    latestVisits.siteID = history.id
                INNER JOIN domains ON domains.id = history.domain_id
                INNER JOIN visits ON visits.siteID = history.id
                LEFT OUTER JOIN view_favicons_widest ON view_favicons_widest.siteID = history.id
            WHERE (history.is_deleted = 0)
            GROUP BY history.id
            ORDER BY latestVisits.latestVisitDate DESC
            """

        return db.runQueryConcurrently(sql, args: nil, factory: SQLiteHistory.iconHistoryColumnFactory)
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
        return db.run("UPDATE history SET guid = ? WHERE url = ? AND guid IS NOT ?", withArgs: args)
    }

    public func deleteByGUID(_ guid: GUID, deletedAt: Timestamp) -> Success {
        let args: Args = [guid]
        // This relies on ON DELETE CASCADE to remove visits.
        return db.run("DELETE FROM history WHERE guid = ?", withArgs: args)
    }

    // Fails on non-existence.
    fileprivate func getSiteIDForGUID(_ guid: GUID) -> Deferred<Maybe<Int>> {
        let args: Args = [guid]
        let query = "SELECT id FROM history WHERE guid = ?"
        let factory: (SDRow) -> Int = { return $0["id"] as! Int }

        return db.runQueryConcurrently(query, args: args, factory: factory)
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
        let select = "SELECT id, server_modified, local_modified, is_deleted, should_upload, title FROM history WHERE guid = ?"
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
        return db.runQueryConcurrently(select, args: args, factory: factory) >>== { cursor in
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
                        let update = "UPDATE history SET server_modified = ? WHERE id = ?"
                        let args: Args = [serverModified, metadata.id]
                        return self.db.run(update, withArgs: args) >>> always(place.guid)
                    }

                    log.verbose("Remote changes overriding local.")
                    // Fall through.
                }

                // The record didn't change locally. Update it.
                log.verbose("Updating local history item for guid \(place.guid).")
                let update = "UPDATE history SET title = ?, server_modified = ?, is_deleted = 0 WHERE id = ?"
                let args: Args = [place.title, serverModified, metadata.id]
                return self.db.run(update, withArgs: args) >>> always(place.guid)
            }

            // The record doesn't exist locally. Insert it.
            log.verbose("Inserting remote history item for guid \(place.guid).")
            if let host = place.url.asURL?.normalizedHost {
                if Logger.logPII {
                    log.debug("Inserting: \(place.url).")
                }

                let insertDomain = "INSERT OR IGNORE INTO domains (domain) VALUES (?)"
                let insertHistory = """
                    INSERT INTO history (
                        guid, url, title, server_modified, is_deleted, should_upload, domain_id
                    ) SELECT ?, ?, ?, ?, 0, 0, id FROM domains WHERE domain = ?
                    """

                return self.db.run([
                    (insertDomain, [host]),
                    (insertHistory, [place.guid, place.url, place.title, serverModified, host])
                ]) >>> always(place.guid)
            } else {
                // This is a URL with no domain. Insert it directly.
                if Logger.logPII {
                    log.debug("Inserting: \(place.url) with no domain.")
                }

                let insertHistory = """
                    INSERT INTO history (
                        guid, url, title, server_modified, is_deleted, should_upload, domain_id
                    ) VALUES (?, ?, ?, ?, 0, 0, NULL)
                    """

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
        let sql = "SELECT guid FROM history WHERE history.should_upload = 1 AND history.is_deleted = 1"
        let f: (SDRow) -> String = { $0["guid"] as! String }

        return self.db.runQuery(sql, args: nil, factory: f) >>== { deferMaybe($0.asArray()) }
    }

    public func getModifiedHistoryToUpload() -> Deferred<Maybe<[(Place, [Visit])]>> {
        // What we want to do: find all history items that are flagged for upload, then find a number of recent visits for each item.
        // This was originally all in a single SQL query but was seperated into two to save some memory when returning back the cursor.
        return getModifiedHistory(limit: 1000) >>== { self.attachVisitsTo(places: $0, visitLimit: 20) }
    }

    private func getModifiedHistory(limit: Int) -> Deferred<Maybe<[Int: Place]>> {
        let sql = """
            SELECT id, guid, url, title
            FROM history
            WHERE should_upload = 1 AND NOT is_deleted = 1
            ORDER BY id
            LIMIT ?
            """

        var places = [Int: Place]()
        let placeFactory: (SDRow) -> Void = { row in
            let id = row["id"] as! Int
            let guid = row["guid"] as! String
            let url = row["url"] as! String
            let title = row["title"] as! String
            places[id] = Place(guid: guid, url: url, title: title)
        }

        let args: Args = [limit]
        return db.runQueryConcurrently(sql, args: args, factory: placeFactory) >>> { deferMaybe(places) }
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

        let sql = """
            SELECT siteID, date AS visitDate, type AS visitType
            FROM visits
            WHERE siteID IN (\(historyIDs.map(String.init).joined(separator: ",")))
            ORDER BY siteID DESC, date DESC
            """

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
            let placesAndVisits: [(Place, [Visit])] = places.compactMap { id, place in
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
        return self.db.run(chunk(guids, by: BrowserDB.MaxVariableNumber).compactMap(markAsDeletedStatementForGUIDs))
    }

    fileprivate func markAsDeletedStatementForGUIDs(_ guids: ArraySlice<String>) -> (String, Args?) {
        // We deliberately don't limit this to records marked as should_upload, just
        // in case a coding error leaves records with is_deleted=1 but not flagged for
        // upload -- this will catch those and throw them away.
        let inClause = BrowserDB.varlist(guids.count)
        let sql = "DELETE FROM history WHERE is_deleted = 1 AND guid IN \(inClause)"

        let args: Args = guids.map { $0 }
        return (sql, args)
    }

    public func markAsSynchronized(_ guids: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>> {
        if guids.isEmpty {
            return deferMaybe(modified)
        }

        log.debug("Marking \(guids.count) GUIDs as synchronized. Returning timestamp \(modified).")
        return self.db.run(chunk(guids, by: BrowserDB.MaxVariableNumber).compactMap { chunk in
            return markAsSynchronizedStatementForGUIDs(chunk, modified: modified)
        }) >>> always(modified)
    }

    fileprivate func markAsSynchronizedStatementForGUIDs(_ guids: ArraySlice<String>, modified: Timestamp) -> (String, Args?) {
        let inClause = BrowserDB.varlist(guids.count)
        let sql = """
            UPDATE history SET
                should_upload = 0,
                server_modified = \(modified)
            WHERE guid IN \(inClause)
            """

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
        return self.db.queryReturnsResults("SELECT 1 FROM history WHERE server_modified IS NOT NULL LIMIT 1")
    }
}

extension SQLiteHistory: ResettableSyncStorage {
    // We don't drop deletions when we reset -- we might need to upload a deleted item
    // that never made it to the server.
    public func resetClient() -> Success {
        let flag = "UPDATE history SET should_upload = 1, server_modified = NULL"
        return self.db.run(flag)
    }
}

extension SQLiteHistory: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        log.info("Clearing history metadata and deleted items after account removal.")
        let discard = "DELETE FROM history WHERE is_deleted = 1"
        return self.db.run(discard) >>> self.resetClient
    }
}
