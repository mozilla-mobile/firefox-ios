// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Glean

private let log = Logger.syncLogger
public let TopSiteCacheSize: Int32 = 16

private var ignoredSchemes = ["about"]

public func isIgnoredURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme else { return false }

    if ignoredSchemes.contains(scheme) { return true }

    if url.host == "localhost" { return true }

    return false
}

public func isIgnoredURL(_ url: String) -> Bool {
    if let url = URL(string: url) {
        return isIgnoredURL(url)
    }

    return false
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
    let database: BrowserDB
    let favicons: SQLiteFavicons
    let prefs: Prefs
    let clearTopSitesQuery: (String, Args?) = ("DELETE FROM cached_top_sites", nil)
    let notificationCenter: NotificationCenter

    required public init(database: BrowserDB,
                         prefs: Prefs,
                         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.database = database
        self.favicons = SQLiteFavicons(db: self.database)
        self.prefs = prefs
        self.notificationCenter = notificationCenter

        // We report the number of visits a user has
        // this is helpful in determining what the size of users' history visits
        // is like, to help guide testing the migration to the
        // application-services implementation and testing the
        // performance of the awesomebar.
        self.countVisits { numVisits in
            if let numVisits = numVisits {
                GleanMetrics.History.numVisits.set(Int64(numVisits))
            }
        }
    }

    public func getSites(forURLs urls: [String]) -> Deferred<Maybe<Cursor<Site?>>> {
        let inExpression = urls.joined(separator: "\",\"")
        let sql = """
        SELECT history.id AS historyID, history.url AS url, title, guid
        FROM history
        WHERE history.url IN (\"\(inExpression)\")
        """

        let args: Args = []
        return database.runQueryConcurrently(sql, args: args, factory: SQLiteHistory.iconHistoryColumnFactory)
    }

    public func countVisits(callback: @escaping (Int?) -> Void) {
        let sql = "SELECT COUNT(*) FROM visits"
        database.runQueryConcurrently(sql, args: nil, factory: SQLiteHistory.countAllVisitsFactory).uponQueue(.main) { result in
            guard result.isSuccess else {
                callback(nil)
                return
            }
            // The result of a count query is only one row
            if let res = result.successValue?.asArray().first {
                if let res = res {
                    callback(res)
                    return
                }
            }
            callback(nil)
        }
    }
}

private let topSitesQuery = """
        SELECT cached_top_sites.*, page_metadata.provider_name \
        FROM cached_top_sites \
        LEFT OUTER JOIN page_metadata ON cached_top_sites.url = page_metadata.site_url \
        ORDER BY frecencies DESC LIMIT (?)
        """

extension SQLiteHistory: PinnedSites {
    public func removeFromPinnedTopSites(_ site: Site) -> Success {
        guard let host = (site.url as String).asURL?.normalizedHost else {
            return deferMaybe(DatabaseError(description: "Invalid url for site \(site.url)"))
        }

        // do a fuzzy delete so dupes can be removed
        let query: (String, Args?) = ("DELETE FROM pinned_top_sites where domain = ?", [host])
        return database.run([query]) >>== {
            self.notificationCenter.post(name: .TopSitesUpdated, object: self)
            return self.database.run([("UPDATE domains SET showOnTopSites = 1 WHERE domain = ?", [host])])
        }
    }

    public func isPinnedTopSite(_ url: String) -> Deferred<Maybe<Bool>> {
        let sql = """
        SELECT * FROM pinned_top_sites
        WHERE url = ?
        LIMIT 1
        """
        let args: Args = [url]
        return self.database.queryReturnsResults(sql, args: args)
    }

    public func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>> {
        let sql = """
            SELECT * FROM pinned_top_sites
            ORDER BY pinDate DESC
            """
        return database.runQueryConcurrently(sql, args: [], factory: SQLiteHistory.iconHistoryMetadataColumnFactory)
    }

    public func addPinnedTopSite(_ site: Site) -> Success { // needs test
        let now = Date.now()
        guard let host = (site.url as String).asURL?.normalizedHost else {
            return deferMaybe(DatabaseError(description: "Invalid site \(site.url)"))
        }

        let args: Args = [site.url, now, site.title, site.id, host]
        let arglist = BrowserDB.varlist(args.count)

        return self.database.run([("INSERT OR REPLACE INTO pinned_top_sites (url, pinDate, title, historyID, domain) VALUES \(arglist)", args)])
        >>== {
            self.notificationCenter.post(name: .TopSitesUpdated, object: self)
            return Success()
        }
    }

}
