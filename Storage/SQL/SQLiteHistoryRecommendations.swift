/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

fileprivate let log = Logger.syncLogger

extension SQLiteHistory: HistoryRecommendations {
    // Bookmarks Query
    static let removeMultipleDomainsSubquery =
        " INNER JOIN (SELECT \(ViewHistoryVisits).domain_id AS domain_id" +
        " FROM \(ViewHistoryVisits)" +
        " GROUP BY \(ViewHistoryVisits).domain_id) AS domains ON domains.domain_id = \(TableHistory).domain_id"

    static let urisForSimpleSyncedBookmarks =
        "SELECT bmkUri FROM \(TableBookmarksBuffer) WHERE server_modified > ? AND is_deleted = 0 " +
        "UNION ALL " +
        "SELECT bmkUri FROM \(TableBookmarksLocal) WHERE local_modified > ? AND is_deleted = 0"

    static let urisForLocalBookmarks =
        "SELECT bmkUri" +
        "FROM \(ViewBookmarksLocalOnMirror) " +
        "WHERE \(ViewBookmarksLocalOnMirror).server_modified > ? OR " +
            "\(ViewBookmarksLocalOnMirror).local_modified > ?"

    static let bookmarkHighlights =
        "SELECT historyID, url, siteTitle, guid, is_bookmarked FROM (" +
            "   SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, \(TableHistory).title AS siteTitle, guid, \(TableHistory).domain_id, NULL AS visitDate, 1 AS is_bookmarked" +
            "   FROM (" +
                    (AppConstants.MOZ_SIMPLE_BOOKMARKS_SYNCING ? urisForSimpleSyncedBookmarks : urisForLocalBookmarks) +
            "   )" +
            "   LEFT JOIN \(TableHistory) ON \(TableHistory).url = bmkUri" + removeMultipleDomainsSubquery +
            "   WHERE \(TableHistory).title NOT NULL and \(TableHistory).title != '' AND url NOT IN" +
            "       (SELECT \(TableActivityStreamBlocklist).url FROM \(TableActivityStreamBlocklist))" +
            "   LIMIT ?" +
        ")"

    static let bookmarksQuery =
        "SELECT historyID, url, siteTitle AS title, guid, is_bookmarked, iconID, iconURL, iconType, iconDate, iconWidth, \(TablePageMetadata).title AS metadata_title, media_url, type, description, provider_name " +
            "FROM (\(bookmarkHighlights) ) " +
            "LEFT JOIN \(ViewHistoryIDsWithWidestFavicons) ON \(ViewHistoryIDsWithWidestFavicons).id = historyID " +
            "LEFT OUTER JOIN \(TablePageMetadata) ON \(TablePageMetadata).cache_key = url " +
    "GROUP BY url"

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

    static let blacklistSubquery = "SELECT \(TableDomains).id FROM \(TableDomains) WHERE \(TableDomains).domain IN " + BrowserDB.varlist(blacklistedHosts.count)
    static let removeMultipleDomainsSubqueryFromHighlights =
        "   INNER JOIN (SELECT \(ViewHistoryVisits).domain_id AS domain_id, MAX(\(ViewHistoryVisits).visitDate) AS visit_date" +
            "   FROM \(ViewHistoryVisits)" +
    "   GROUP BY \(ViewHistoryVisits).domain_id) AS domains ON domains.domain_id = \(TableHistory).domain_id AND visitDate = domains.visit_date"

    static let nonRecentHistory =
        "SELECT historyID, url, siteTitle, guid, visitCount, visitDate, is_bookmarked, visitCount * icon_url_score * media_url_score AS score FROM (" +
            "   SELECT \(TableHistory).id as historyID, url, \(TableHistory).title AS siteTitle, guid, visitDate, \(TableHistory).domain_id," +
            "       (SELECT COUNT(1) FROM \(TableVisits) WHERE s = \(TableVisits).siteID) AS visitCount," +
            "       (SELECT COUNT(1) FROM \(ViewBookmarksLocalOnMirror) WHERE \(ViewBookmarksLocalOnMirror).bmkUri == url) AS is_bookmarked," +
            "     CASE WHEN iconURL IS NULL THEN 1 ELSE 2 END AS icon_url_score," +
            "     CASE WHEN media_url IS NULL THEN 1 ELSE 4 END AS media_url_score" +
            "   FROM (" +
            "       SELECT siteID AS s, MAX(date) AS visitDate" +
            "       FROM \(TableVisits)" +
            "       WHERE date < ?" +
            "       GROUP BY siteID" +
            "       ORDER BY visitDate DESC" +
            "   )" +
            "   LEFT JOIN \(TableHistory) ON \(TableHistory).id = s" +
            removeMultipleDomainsSubqueryFromHighlights +
            "   LEFT OUTER JOIN \(ViewHistoryIDsWithWidestFavicons) ON" +
            "       \(ViewHistoryIDsWithWidestFavicons).id = \(TableHistory).id" +
            "   LEFT OUTER JOIN \(TablePageMetadata) ON" +
            "       \(TablePageMetadata).site_url = \(TableHistory).url" +
            "   WHERE visitCount <= 3 AND \(TableHistory).title NOT NULL AND \(TableHistory).title != '' AND is_bookmarked == 0 AND url NOT IN" +
            "       (SELECT url FROM \(TableActivityStreamBlocklist))" +
            "        AND \(TableHistory).domain_id NOT IN ("
            + blacklistSubquery + ")" +
    ")"

    public func getHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        let highlightsProjection = [
            "historyID",
            "\(TableHighlights).cache_key AS cache_key",
            "url",
            "\(TableHighlights).title AS title",
            "guid",
            "visitCount",
            "visitDate",
            "is_bookmarked"
        ]
        let faviconsProjection = ["iconID", "iconURL", "iconType", "iconDate", "iconWidth"]
        let metadataProjections = [
            "\(TablePageMetadata).title AS metadata_title",
            "media_url",
            "type",
            "description",
            "provider_name"
        ]

        let allProjection = highlightsProjection + faviconsProjection + metadataProjections

        let highlightsHistoryIDs =
        "SELECT historyID FROM \(TableHighlights)"

        // Search the history/favicon view with our limited set of highlight IDs
        // to avoid doing a full table scan on history
        let faviconSearch =
        "SELECT * FROM \(ViewHistoryIDsWithWidestFavicons) WHERE id IN (\(highlightsHistoryIDs))"

        let sql =
        "SELECT \(allProjection.joined(separator: ",")) " +
        "FROM \(TableHighlights) " +
        "LEFT JOIN (\(faviconSearch)) AS f1 ON f1.id = historyID " +
        "LEFT OUTER JOIN \(TablePageMetadata) ON " +
        "\(TablePageMetadata).cache_key = \(TableHighlights).cache_key"

        return self.db.runQuery(sql, args: nil, factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
    }

    public func removeHighlightForURL(_ url: String) -> Success {
        return self.db.run([("INSERT INTO \(TableActivityStreamBlocklist) (url) VALUES (?)", [url])])
    }

    private func repopulateHighlightsQuery() -> [(String, Args?)] {
        let (query, args) = computeHighlightsQuery()
        let clearHighlightsQuery = "DELETE FROM \(TableHighlights)"

        let sql = "INSERT INTO \(TableHighlights) " +
            "SELECT historyID, url as cache_key, url, title, guid, visitCount, visitDate, is_bookmarked " +
            "FROM (\(query))"
        return [(clearHighlightsQuery, nil), (sql, args)]
    }

    public func repopulate(invalidateTopSites shouldInvalidateTopSites: Bool, invalidateHighlights shouldInvalidateHighlights: Bool) -> Success {
        var queries: [(String, Args?)] = []
        if shouldInvalidateTopSites {
            queries.append(contentsOf: self.refreshTopSitesQuery())
        }
        if shouldInvalidateHighlights {
            queries.append(contentsOf: self.repopulateHighlightsQuery())
        }
        return self.db.run(queries)
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

        let highlightsQuery =
            "SELECT historyID, url, siteTitle AS title, guid, visitCount, visitDate, is_bookmarked, score " +
            "FROM ( \(SQLiteHistory.nonRecentHistory) ) " +
            "GROUP BY url " +
            "ORDER BY score DESC " +
            "LIMIT \(SQLiteHistory.highlightsLimit)"
        let args: Args = [thirtyMinutesAgo] + SQLiteHistory.blacklistedHosts
        return (highlightsQuery, args)
    }
}
