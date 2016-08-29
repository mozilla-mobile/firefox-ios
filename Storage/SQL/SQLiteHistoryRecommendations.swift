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

    private class func iconHistoryColumnFactory(row: SDRow) -> Site {
        let site = basicHistoryColumnFactory(row)
        site.icon = iconColumnFactory(row)
        return site
    }

    private class func basicHistoryColumnFactory(row: SDRow) -> Site {
        let id = row["historyID"] as! Int
        let url = row["url"] as! String
        let title = row["title"] as! String
        let guid = row["guid"] as! String

        // Extract a boolean from the row if it's present.
        let iB = row["is_bookmarked"] as? Int
        let isBookmarked: Bool? = (iB == nil) ? nil : (iB! != 0)

        let site = Site(url: url, title: title, bookmarked: isBookmarked)
        site.guid = guid
        site.id = id

        // Find the most recent visit, regardless of which column it might be in.
        let local = row.getTimestamp("localVisitDate") ?? 0
        let remote = row.getTimestamp("remoteVisitDate") ?? 0
        let either = row.getTimestamp("visitDate") ?? 0

        let latest = max(local, remote, either)
        if latest > 0 {
            site.latestVisit = Visit(date: latest, type: VisitType.Unknown)
        }

        return site
    }

    private class func iconColumnFactory(row: SDRow) -> Favicon? {
        if let iconType = row["iconType"] as? Int,
            let iconURL = row["iconURL"] as? String,
            let iconDate = row["iconDate"] as? Double,
            let _ = row["iconID"] as? Int {
            let date = NSDate(timeIntervalSince1970: iconDate)
            return Favicon(url: iconURL, date: date, type: IconType(rawValue: iconType)!)
        }
        return nil
    }
}