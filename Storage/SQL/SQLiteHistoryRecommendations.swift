/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

/// Small enum to help strength parameter requirements for potential bookmark highlights query below.
private enum BookmarkSource {
    case Mirror
    case Local

    var modifiedColumn: String  {
        switch self {
        case Mirror: return "server_modified"
        case Local: return "local_modified"
        }
    }

    var tableName: String {
        switch self {
        case Mirror: return TableBookmarksMirror
        case Local: return TableBookmarksLocal
        }
    }
}

extension SQLiteHistory: HistoryRecommendations {
    public func getHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        let limit = 20
        let microsecondsPerMinute: Timestamp = 60_000_000 // 1000 * 1000 * 60
        let now = NSDate.nowMicroseconds()
        let thirtyMinutesAgo = now - 30 * microsecondsPerMinute
        let threeDaysAgo = now - (60 * microsecondsPerMinute) * 24 * 3
        let bookmarkLimit = 1
        let historyLimit = limit - bookmarkLimit

        let highlightProjection = "historyID, url, title, guid, visitCount, visitDate, iconID, iconURL, iconType, iconDate, iconWidth"

        let nonRecentHistory = [
            "SELECT * FROM (",
            "   SELECT \(TableHistory).id as historyID, url, title, guid, visitDate, (SELECT COUNT(1) FROM \(TableVisits) WHERE s = \(TableVisits).siteID) AS visitCount",
            "   FROM (",
            "       SELECT siteID AS s, max(date) AS visitDate",
            "       FROM \(TableVisits)",
            "       WHERE date < \(thirtyMinutesAgo)",
            "       GROUP BY siteID",
            "   )",
            "   LEFT JOIN \(TableHistory) ON \(TableHistory).id = s",
            "   WHERE visitCount <= 3 AND title NOT NULL AND title != ''",
            "   LIMIT \(historyLimit)",
            ")"
        ].joinWithSeparator(" ")

        let bookmarkHighlights = [
            "SELECT * FROM (",
            "   SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, \(TableHistory).title AS title, guid, NULL AS visitDate, (SELECT count(1) FROM visits WHERE \(TableVisits).siteID = \(TableHistory).id) as visitCount",
            "   FROM (",
            "       SELECT bmkUri",
            "       FROM \(ViewBookmarksLocalOnMirror)",
            "       WHERE \(ViewBookmarksLocalOnMirror).server_modified > \(threeDaysAgo) OR \(ViewBookmarksLocalOnMirror).local_modified > \(threeDaysAgo)",
            "   )",
            "   LEFT JOIN \(TableHistory) ON \(TableHistory).url = bmkUri",
            "   WHERE visitCount >= 3 AND \(TableHistory).title NOT NULL and \(TableHistory).title != ''",
            "   LIMIT \(bookmarkLimit)",
            ")"
        ].joinWithSeparator(" ")

        let highlightsQuery = [
            "SELECT \(highlightProjection)",
            "FROM (",
                bookmarkHighlights,
                "UNION",
                nonRecentHistory,
            ")",
            "LEFT JOIN \(ViewHistoryIDsWithWidestFavicons) ON \(ViewHistoryIDsWithWidestFavicons).id = historyID",
            "GROUP BY url"
        ].joinWithSeparator(" ")

        return self.db.runQuery(highlightsQuery, args: nil, factory: SQLiteHistory.iconHistoryColumnFactory)
    }
}
