/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

extension SQLiteHistory: HistoryRecommendations {
    public func getHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        let limit = 8
        let bookmarkLimit = 1
        let historyLimit = limit - bookmarkLimit

        let microsecondsPerMinute: UInt64 = 60_000_000 // 1000 * 1000 * 60
        let now = Date.nowMicroseconds()
        let thirtyMinutesAgo: UInt64 = now - 30 * microsecondsPerMinute

        let blacklistedHosts: Args = [
            "google.com",
            "google.ca",
            "calendar.google.com",
            "mail.google.com",
            "mail.yahoo.com",
            "search.yahoo.com",
            "localhost",
            "t.co"
        ]

        let blacklistSubquery = "SELECT \(TableDomains).id FROM \(TableDomains) " +
                "WHERE " + "\(TableDomains).domain" + " IN " + BrowserDB.varlist(blacklistedHosts.count)

        /*
         Lets get some history that we will then rank based on the metadata availible to us
         When grouping by domain. Choose the url with the largest title and largest url.
         We also want to filter out sites that appear in the top sites or are part of the blacklist.
         From these 100 we will show less than a dozen.
         */

        let newquery =
            "SELECT historyID, url, title, guid, visitCount, visitDate, is_bookmarked " +
            "FROM (" +
            "   SELECT url, siteID as historyID, title, guid, visitDate," +
            "       (SELECT COUNT(1) FROM \(TableVisits) WHERE s = \(TableVisits).siteID) AS visitCount," +
            "       (SELECT COUNT(1) FROM \(ViewBookmarksLocalOnMirror) WHERE \(ViewBookmarksLocalOnMirror).bmkUri == url) AS is_bookmarked" +
            "   FROM (SELECT  *, siteID AS s, min(date) AS visitDate, max(title), max(url) FROM visits  LEFT JOIN history ON history.id = s group by domain_id)" +
            "   WHERE visitCount <= 3 AND visitDate < ? AND title NOT NULL AND title != ''" +
            "       AND is_bookmarked == 0 AND domain_id NOT IN (SELECT cached_top_sites.domain_id FROM cached_top_sites) " +
            "       AND domain_id NOT IN (\(blacklistSubquery))" +
            "   ORDER BY visitDate DESC " +
            "   ) " +
            "LIMIT 100"

        /*
         The main query. We perform a join with the metadata and favicon table
         We do some loose ranking based on the metadata availible for each site. If a site has a media_url rank it higher.
         */
        let highlightsQuery =
            "SELECT *, \(AttachedTablePageMetadata).title AS metadata_title " +
            "FROM ( \(newquery) ) " +
            "LEFT JOIN \(ViewHistoryIDsWithWidestFavicons) ON \(ViewHistoryIDsWithWidestFavicons).id = historyID " +
            "LEFT OUTER JOIN \(AttachedTablePageMetadata) ON \(AttachedTablePageMetadata).site_url = url " +
            "GROUP BY url " +
            "ORDER BY COALESCE(iconURL, media_url) NOT NULL DESC " +
            "LIMIT \(historyLimit)"

        let args: Args = [now] + blacklistedHosts
        print(highlightsQuery)
        return self.db.runQuery(highlightsQuery, args: args, factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
    }

    public func removeHighlightForURL(_ url: String) -> Success {
        return self.db.run([("INSERT INTO \(TableActivityStreamBlocklist) (url) VALUES (?)", [url])])
    }
}
