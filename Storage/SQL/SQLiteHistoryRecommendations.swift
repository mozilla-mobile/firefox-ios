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
        let limit = 19
        let microsecondsPerMinute: Timestamp = 60_000_000 // 1000 * 1000 * 60
        let thirtyMinutesAgo = NSDate.nowMicroseconds() - 30 * microsecondsPerMinute
        let threeDaysAgo = NSDate.nowMicroseconds() - (60 * microsecondsPerMinute) * 24 * 3
        let bookmarkLimit = 1
        let historyLimit = limit - bookmarkLimit

        let recentHistory = [
            "SELECT *",
            "FROM (",
            "   SELECT \(TableHistory).id AS historyID, url, title, guid, sum(1) AS visitCount, max(\(TableVisits).date) AS visitDate",
            "   FROM \(TableHistory)",
            "   LEFT JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id",
            "   WHERE title NOT NULL AND title != '' AND is_deleted = 0",
            "   GROUP BY url",
            "   ORDER BY visitDate DESC",
            "   LIMIT \(historyLimit)",
            ")",
            "WHERE visitCount <= 3 AND visitDate < \(thirtyMinutesAgo)",
        ].joinWithSeparator(" ")

        let bookmarkHighlights = [
            "SELECT historyID, url, title, guid, visitCount, visitDate",
            "FROM (",
            "   SELECT *",
            "   FROM (",
                    potentialHighlightsFromBookmarkSource(.Local),
                    "UNION",
                    potentialHighlightsFromBookmarkSource(.Mirror),
            "   )",
            "   WHERE visitCount <= 3 AND modified > \(threeDaysAgo)",
            "   ORDER BY modified DESC",
            "   LIMIT \(bookmarkLimit)",
            ")"
        ].joinWithSeparator(" ")

        let highlightsQuery = [
            "SELECT DISTINCT historyID, url, title, guid, visitCount, visitDate, iconID, iconURL, iconType, iconDate, iconWidth",
            "FROM (",
                bookmarkHighlights,
                "UNION ALL",
                recentHistory,
            ")",
            "LEFT JOIN \(ViewHistoryIDsWithWidestFavicons) ON \(ViewHistoryIDsWithWidestFavicons).id = historyID",
            "GROUP BY url"
        ].joinWithSeparator(" ")

        return self.db.runQuery(highlightsQuery, args: nil, factory: SQLiteHistory.iconHistoryColumnFactory)
    }

    private func potentialHighlightsFromBookmarkSource(source: BookmarkSource) -> String {
        return [
            "SELECT \(TableHistory).id as historyId, bmkUri as url, \(source.tableName).title as title, \(TableHistory).guid as guid,",
            "   sum(1) as visitCount, max(\(TableVisits).date) AS visitDate, \(source.tableName).\(source.modifiedColumn) as modified",
            "FROM \(source.tableName)",
            "LEFT JOIN history ON history.url = \(source.tableName).bmkUri",
            "LEFT JOIN visits ON history.id = visits.siteID",
            "WHERE \(source.tableName).title NOT NULL",
            "AND \(source.tableName).title != ''",
            "AND \(source.tableName).is_deleted = 0",
            source == .Mirror ? "AND \(source.tableName).is_overridden = 0" : "",
            "AND \(source.tableName).type = 1",
            "GROUP BY history.url",
        ].joinWithSeparator(" ")
    }
}
