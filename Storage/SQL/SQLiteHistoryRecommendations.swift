/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

fileprivate let log = Logger.syncLogger

extension SQLiteHistory: HistoryRecommendations {
    // These numbers will likely need additional tweaking in the future.
    // They are currently based on a best-guess as to where performance
    // starts to suffer in a large browser.db. A database with 200,001
    // unique history items with 20 visits each produces a 340MB file.
    // We limit the number of history items to prune at once to 5,000
    // rows to ensure the pruning completes in a timely manner.
    static let MaxHistoryRowCount: UInt = 200000
    static let PruneHistoryRowCount: UInt = 5000

    // Bookmarks Query
    static let urisForSimpleSyncedBookmarks = """
        SELECT bmkUri FROM bookmarksBuffer WHERE server_modified > ? AND is_deleted = 0
        UNION ALL
        SELECT bmkUri FROM bookmarksLocal WHERE local_modified > ? AND is_deleted = 0
        """

    static let urisForLocalBookmarks = """
        SELECT bmkUri
        FROM view_bookmarksLocal_on_mirror
        WHERE view_bookmarksLocal_on_mirror.server_modified > ? OR view_bookmarksLocal_on_mirror.local_modified > ?
        """

    static let bookmarkHighlights = """
        SELECT historyID, url, siteTitle, guid, is_bookmarked
        FROM (
            SELECT history.id AS historyID, history.url AS url, history.title AS siteTitle, guid, history.domain_id, NULL AS visitDate, 1 AS is_bookmarked
            FROM (\(urisForSimpleSyncedBookmarks))
                LEFT JOIN history ON history.url = bmkUri
            WHERE
                history.title NOT NULL AND
                history.title != '' AND
                url NOT IN (SELECT activity_stream_blocklist.url FROM activity_stream_blocklist)
            LIMIT ?
        )
        """

    static let bookmarksQuery = """
        SELECT historyID, url, siteTitle AS title, guid, is_bookmarked, iconID, iconURL, iconType, iconDate, iconWidth, page_metadata.title AS metadata_title, media_url, type, description, provider_name
        FROM (\(bookmarkHighlights))
            LEFT JOIN view_favicons_widest ON
                view_favicons_widest.siteID = historyID
            LEFT OUTER JOIN page_metadata ON
                page_metadata.cache_key = url
        GROUP BY url
        """

    // Highlights Query
    static let highlightsLimit = 8
    static let blacklistedHosts: Args = [
        "google.com",
        "google.ca",
        "calendar.google.com",
        "mail.google.com",
        "mail.yahoo.com",
        "search.yahoo.com",
        "localhost",
        "t.co"
    ]

    static let blacklistSubquery =
        "SELECT domains.id FROM domains WHERE domains.domain IN " +
        BrowserDB.varlist(blacklistedHosts.count)

    static let removeMultipleDomainsSubqueryFromHighlights = """
        INNER JOIN (
            SELECT view_history_visits.domain_id AS domain_id, max(view_history_visits.visitDate) AS visit_date
            FROM view_history_visits
            GROUP BY view_history_visits.domain_id
        ) AS domains ON
            domains.domain_id = history.domain_id AND
            visitDate = domains.visit_date
        """

    static let nonRecentHistory = """
        SELECT historyID, url, siteTitle, guid, visitCount, visitDate, is_bookmarked, visitCount * icon_url_score * media_url_score AS score
        FROM (
            SELECT history.id AS historyID, url, history.title AS siteTitle, guid, visitDate, history.domain_id,
                (SELECT count(1) FROM visits WHERE s = visits.siteID) AS visitCount,
                (SELECT count(1) FROM view_bookmarksLocal_on_mirror WHERE view_bookmarksLocal_on_mirror.bmkUri == url) AS is_bookmarked,
                CASE WHEN iconURL IS NULL THEN 1 ELSE 2 END AS icon_url_score,
                CASE WHEN media_url IS NULL THEN 1 ELSE 4 END AS media_url_score
            FROM (
                SELECT siteID AS s, max(date) AS visitDate
                FROM visits
                WHERE date < ?
                GROUP BY siteID
                ORDER BY visitDate DESC
            )
            LEFT JOIN history ON
                history.id = s
            \(removeMultipleDomainsSubqueryFromHighlights)
            LEFT OUTER JOIN view_history_id_favicon ON
                view_history_id_favicon.id = history.id
            LEFT OUTER JOIN page_metadata ON
                page_metadata.site_url = history.url
            WHERE
                visitCount <= 3 AND
                history.title NOT NULL AND
                history.title != '' AND
                is_bookmarked == 0 AND
                url NOT IN (SELECT url FROM activity_stream_blocklist) AND
                history.domain_id NOT IN (\(blacklistSubquery))
        )
        """

    public func getHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        let highlightsProjection = [
            "historyID",
            "highlights.cache_key AS cache_key",
            "url",
            "highlights.title AS title",
            "guid",
            "visitCount",
            "visitDate",
            "is_bookmarked"
        ]
        let faviconsProjection = ["iconID", "iconURL", "iconType", "iconDate", "iconWidth"]
        let metadataProjections = [
            "page_metadata.title AS metadata_title",
            "media_url",
            "type",
            "description",
            "provider_name"
        ]

        let allProjection = highlightsProjection + faviconsProjection + metadataProjections

        let highlightsHistoryIDs = "SELECT historyID FROM highlights"

        // Search the history/favicon view with our limited set of highlight IDs
        // to avoid doing a full table scan on history
        let faviconSearch =
            "SELECT * FROM view_favicons_widest WHERE siteID IN (\(highlightsHistoryIDs))"

        let sql = """
            SELECT \(allProjection.joined(separator: ","))
            FROM highlights
            LEFT JOIN (\(faviconSearch)) AS f1 ON
                f1.siteID = historyID
            LEFT OUTER JOIN page_metadata ON
                page_metadata.cache_key = highlights.cache_key
            """

        return self.db.runQuery(sql, args: nil, factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
    }

    public func removeHighlightForURL(_ url: String) -> Success {
        return self.db.run([("INSERT INTO activity_stream_blocklist (url) VALUES (?)", [url])])
    }

    private func repopulateHighlightsQuery() -> [(String, Args?)] {
        let (query, args) = computeHighlightsQuery()
        let clearHighlightsQuery = "DELETE FROM highlights"

        let sql = """
            INSERT INTO highlights
            SELECT historyID, url as cache_key, url, title, guid, visitCount, visitDate, is_bookmarked
            FROM (\(query))
            """

        return [(clearHighlightsQuery, nil), (sql, args)]
    }

    // Checks if there are more than the specified number of rows in the
    // `history` table. This is used as an indicator that `cleanupOldHistory()`
    // needs to run.
    func checkIfCleanupIsNeeded(maxHistoryRows: UInt) -> Deferred<Maybe<Bool>> {
        let sql = "SELECT COUNT(rowid) > \(maxHistoryRows) AS cleanup FROM \(TableHistory)"
        return self.db.runQuery(sql, args: nil, factory: IntFactory) >>== { cursor in
            guard let cleanup = cursor[0], cleanup > 0 else {
                return deferMaybe(false)
            }

            return deferMaybe(true)
        }
    }

    // Deletes the specified number of items from the `history` table and
    // their corresponding items in the `visits` table. This only gets run
    // when the `checkIfCleanupIsNeeded()` method returns `true`. It is possible
    // that a single clean-up operation may not remove enough rows to drop below
    // the threshold used in `checkIfCleanupIsNeeded()` and therefore, this may
    // end up running several times until that threshold is crossed.
    func cleanupOldHistory(numberOfRowsToPrune: UInt) -> [(String, Args?)] {
        let sql = """
            DELETE FROM \(TableHistory) WHERE id IN (
                SELECT siteID
                FROM \(TableVisits)
                GROUP BY siteID
                ORDER BY max(date) ASC
                LIMIT \(numberOfRowsToPrune)
            )
            """
        return [(sql, nil)]
    }

    public func repopulate(invalidateTopSites shouldInvalidateTopSites: Bool, invalidateHighlights shouldInvalidateHighlights: Bool) -> Success {
        var queries: [(String, Args?)] = []

        func runQueries() -> Success {
            if shouldInvalidateTopSites {
                queries.append(contentsOf: self.refreshTopSitesQuery())
            }
            if shouldInvalidateHighlights {
                queries.append(contentsOf: self.repopulateHighlightsQuery())
            }

            return self.db.run(queries)
        }

        // Only check for and perform cleanup operation if we're already invalidating a cache.
        if shouldInvalidateTopSites || shouldInvalidateHighlights {
            return checkIfCleanupIsNeeded(maxHistoryRows: SQLiteHistory.MaxHistoryRowCount) >>== { doCleanup in
                if doCleanup {
                    queries.append(contentsOf: self.cleanupOldHistory(numberOfRowsToPrune: SQLiteHistory.PruneHistoryRowCount))
                }
                return runQueries()
            }
        } else {
            return runQueries()
        }
    }

    public func getRecentBookmarks(_ limit: Int = 3) -> Deferred<Maybe<Cursor<Site>>> {
        let fiveDaysAgo: UInt64 = Date.now() - (OneDayInMilliseconds * 5) // The data is joined with a millisecond not a microsecond one. (History)
        let args = [fiveDaysAgo, fiveDaysAgo, limit] as Args
        return self.db.runQuery(SQLiteHistory.bookmarksQuery, args: args, factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
    }

    private func computeHighlightsQuery() -> (String, Args) {
        let microsecondsPerMinute: UInt64 = 60_000_000 // 1000 * 1000 * 60
        let now = Date.nowMicroseconds()
        let thirtyMinutesAgo: UInt64 = now - 30 * microsecondsPerMinute

        let highlightsQuery = """
            SELECT historyID, url, siteTitle AS title, guid, visitCount, visitDate, is_bookmarked, score
            FROM (\(SQLiteHistory.nonRecentHistory))
            GROUP BY url
            ORDER BY score DESC
            LIMIT \(SQLiteHistory.highlightsLimit)
            """

        let args: Args = [thirtyMinutesAgo] + SQLiteHistory.blacklistedHosts
        return (highlightsQuery, args)
    }
}
