/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

extension SQLiteHistory: HistoryRecommendations {
    public func getHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        let limit = 20
        let bookmarkLimit = 1
        let historyLimit = limit - bookmarkLimit

        let microsecondsPerMinute: UInt64 = 60_000_000 // 1000 * 1000 * 60
        let now = NSDate.nowMicroseconds()
        let thirtyMinutesAgo = NSNumber(unsignedLongLong: now - 30 * microsecondsPerMinute)
        let threeDaysAgo = NSNumber(unsignedLongLong: now - (60 * microsecondsPerMinute) * 24 * 3)

        let siteProjection = "historyID, url, title, guid, visitCount, visitDate, is_bookmarked"
        let nonRecentHistory =
            "SELECT \(siteProjection) FROM (" +
            "   SELECT \(TableHistory).id as historyID, url, title, guid, visitDate," +
            "       (SELECT COUNT(1) FROM \(TableVisits) WHERE s = \(TableVisits).siteID) AS visitCount," +
            "       (SELECT COUNT(1) FROM \(ViewBookmarksLocalOnMirror) WHERE \(ViewBookmarksLocalOnMirror).bmkUri == url) AS is_bookmarked" +
            "   FROM (" +
            "       SELECT siteID AS s, max(date) AS visitDate" +
            "       FROM \(TableVisits)" +
            "       WHERE date < ?" +
            "       GROUP BY siteID" +
            "   )" +
            "   LEFT JOIN \(TableHistory) ON \(TableHistory).id = s" +
            "   WHERE visitCount <= 3 AND title NOT NULL AND title != '' AND is_bookmarked == 0 AND url NOT IN" +
            "       (SELECT \(TableActivityStreamBlocklist).url FROM \(TableActivityStreamBlocklist))" +
            "   LIMIT \(historyLimit)" +
            ")"

        let bookmarkHighlights =
            "SELECT \(siteProjection) FROM (" +
            "   SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, \(TableHistory).title AS title, guid, NULL AS visitDate, (SELECT count(1) FROM visits WHERE \(TableVisits).siteID = \(TableHistory).id) as visitCount, 1 AS is_bookmarked" +
            "   FROM (" +
            "       SELECT bmkUri" +
            "       FROM \(ViewBookmarksLocalOnMirror)" +
            "       WHERE \(ViewBookmarksLocalOnMirror).server_modified > ? OR \(ViewBookmarksLocalOnMirror).local_modified > ?" +
            "   )" +
            "   LEFT JOIN \(TableHistory) ON \(TableHistory).url = bmkUri" +
            "   WHERE visitCount >= 3 AND \(TableHistory).title NOT NULL and \(TableHistory).title != '' AND url NOT IN" +
            "       (SELECT \(TableActivityStreamBlocklist).url FROM \(TableActivityStreamBlocklist))" +
            "   LIMIT \(bookmarkLimit)" +
            ")"

        let highlightsQuery =
            "SELECT \(siteProjection), iconID, iconURL, iconType, iconDate, iconWidth " +
            "FROM ( \(nonRecentHistory) UNION ALL \(bookmarkHighlights) ) " +
            "LEFT JOIN \(ViewHistoryIDsWithWidestFavicons) ON \(ViewHistoryIDsWithWidestFavicons).id = historyID " +
            "GROUP BY url"

        return self.db.runQuery(highlightsQuery, args: [thirtyMinutesAgo, threeDaysAgo, threeDaysAgo], factory: SQLiteHistory.iconHistoryColumnFactory)
    }

    public func removeHighlightForURL(url: String) -> Success {
        return self.db.run([("INSERT INTO \(TableActivityStreamBlocklist) (url) VALUES (?)", [url])])
    }
}
