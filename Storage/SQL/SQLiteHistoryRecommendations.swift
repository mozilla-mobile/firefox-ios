/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

fileprivate let log = Logger.syncLogger

extension SQLiteHistory: HistoryRecommendations {
    public func getHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        let sql = "SELECT * FROM \(AttachedTableHighlights)"
        return self.db.runQuery(sql, args: nil, factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
    }

    public func invalidateHighlights() -> Success {
        return clearHighlights() >>> populateHighlights
    }

    public func removeHighlightForURL(_ url: String) -> Success {
        return self.db.run([("INSERT INTO \(TableActivityStreamBlocklist) (url) VALUES (?)", [url])])
    }

    private func clearHighlights() -> Success {
        return self.db.run("DELETE FROM \(AttachedTableHighlights)", withArgs: nil)
    }

    private func populateHighlights() -> Success {
        let (query, args) = computeHighlightsQuery()
        let sql =
            "INSERT INTO \(AttachedTableHighlights) " +
            "SELECT historyID, url, title, guid, visitCount, visitDate, " +
            "is_bookmarked, iconID, iconURL, iconType, iconDate, iconWidth, " +
            "metadata_title, media_url, type, description, provider_name " +
            "FROM (\(query))"

        return self.db.run(sql, withArgs: args)
    }

    private func computeHighlightsQuery() -> (String, Args) {
        let limit = 8
        let bookmarkLimit = 1
        let historyLimit = limit - bookmarkLimit

        let microsecondsPerMinute: UInt64 = 60_000_000 // 1000 * 1000 * 60
        let now = Date.nowMicroseconds()
        let thirtyMinutesAgo: UInt64 = now - 30 * microsecondsPerMinute
        let threeDaysAgo: UInt64 = now - (60 * microsecondsPerMinute) * 24 * 3

        let blacklistedHosts: Args = [
            "google.com"   ,
            "google.ca"   ,
            "calendar.google.com"   ,
            "mail.google.com"   ,
            "mail.yahoo.com"   ,
            "search.yahoo.com"   ,
            "localhost"   ,
            "t.co"
        ]

        var blacklistSubquery = ""
        if blacklistedHosts.count > 0 {
            blacklistSubquery = "SELECT " + "\(TableDomains).id" +
                " FROM " + "\(TableDomains)" +
                " WHERE " + "\(TableDomains).domain" + " IN " + BrowserDB.varlist(blacklistedHosts.count)
        }

        let removeMultipleDomainsSubquery =
            "   INNER JOIN (SELECT \(ViewHistoryVisits).domain_id AS domain_id, MAX(\(ViewHistoryVisits).visitDate) AS visit_date" +
            "   FROM \(ViewHistoryVisits)" +
            "   GROUP BY \(ViewHistoryVisits).domain_id) AS domains ON domains.domain_id = \(TableHistory).domain_id AND visitDate = domains.visit_date"

        let subQuerySiteProjection = "historyID, url, siteTitle, guid, visitCount, visitDate, is_bookmarked"
        let nonRecentHistory =
            "SELECT \(subQuerySiteProjection) FROM (" +
            "   SELECT \(TableHistory).id as historyID, url, title AS siteTitle, guid, visitDate, \(TableHistory).domain_id," +
            "       (SELECT COUNT(1) FROM \(TableVisits) WHERE s = \(TableVisits).siteID) AS visitCount," +
            "       (SELECT COUNT(1) FROM \(ViewBookmarksLocalOnMirror) WHERE \(ViewBookmarksLocalOnMirror).bmkUri == url) AS is_bookmarked" +
            "   FROM (" +
            "       SELECT siteID AS s, max(date) AS visitDate" +
            "       FROM \(TableVisits)" +
            "       WHERE date < ?" +
            "       GROUP BY siteID" +
            "       ORDER BY visitDate DESC" +
            "   )" +
            "   LEFT JOIN \(TableHistory) ON \(TableHistory).id = s" +
                removeMultipleDomainsSubquery +
            "   WHERE visitCount <= 3 AND title NOT NULL AND title != '' AND is_bookmarked == 0 AND url NOT IN" +
            "       (SELECT \(TableActivityStreamBlocklist).url FROM \(TableActivityStreamBlocklist))" +
            "        AND \(TableHistory).domain_id NOT IN ("
                    + blacklistSubquery + ")" +
            "   LIMIT \(historyLimit)" +
            ")"

        let bookmarkHighlights =
            "SELECT \(subQuerySiteProjection) FROM (" +
            "   SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, \(TableHistory).title AS siteTitle, guid, \(TableHistory).domain_id, NULL AS visitDate, (SELECT count(1) FROM visits WHERE \(TableVisits).siteID = \(TableHistory).id) as visitCount, 1 AS is_bookmarked" +
            "   FROM (" +
            "       SELECT bmkUri" +
            "       FROM \(ViewBookmarksLocalOnMirror)" +
            "       WHERE \(ViewBookmarksLocalOnMirror).server_modified > ? OR \(ViewBookmarksLocalOnMirror).local_modified > ?" +
            "   )" +
            "   LEFT JOIN \(TableHistory) ON \(TableHistory).url = bmkUri" +
                removeMultipleDomainsSubquery +
            "   WHERE visitCount >= 3 AND \(TableHistory).title NOT NULL and \(TableHistory).title != '' AND url NOT IN" +
            "       (SELECT \(TableActivityStreamBlocklist).url FROM \(TableActivityStreamBlocklist))" +
            "   LIMIT \(bookmarkLimit)" +
            ")"

        let siteProjection = subQuerySiteProjection.replacingOccurrences(of: "siteTitle", with: "siteTitle AS title")
        let highlightsQuery =
            "SELECT \(siteProjection), iconID, iconURL, iconType, iconDate, iconWidth, \(AttachedTablePageMetadata).title AS metadata_title, media_url, type, description, provider_name " +
            "FROM ( \(nonRecentHistory) UNION ALL \(bookmarkHighlights) ) " +
            "LEFT JOIN \(ViewHistoryIDsWithWidestFavicons) ON \(ViewHistoryIDsWithWidestFavicons).id = historyID " +
            "LEFT OUTER JOIN \(AttachedTablePageMetadata) ON \(AttachedTablePageMetadata).site_url = url " +
            "GROUP BY url"
        let otherArgs = [threeDaysAgo, threeDaysAgo] as Args
        let args: Args = [thirtyMinutesAgo] + blacklistedHosts + otherArgs
        return (highlightsQuery, args)
    }
}
