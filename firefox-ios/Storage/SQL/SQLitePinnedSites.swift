// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

private var ignoredSchemes = ["about"]

public func isIgnoredURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme else { return false }

    if ignoredSchemes.contains(scheme) { return true }

    if url.host == "localhost" { return true }

    return false
}

public func isIgnoredURL(_ url: String) -> Bool {
    if let url = URL(string: url, invalidCharacters: false) {
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

extension BrowserDBSQLite: PinnedSites {
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
        return database.runQueryConcurrently(sql, args: [], factory: BrowserDBSQLite.historyMetadataColumnFactory)
    }

    public func addPinnedTopSite(_ site: Site) -> Success { // needs test
        let now = Date.now()
        guard let host = (site.url as String).asURL?.normalizedHost else {
            return deferMaybe(DatabaseError(description: "Invalid site \(site.url)"))
        }

        // We insert a dummy guid for backward compatibility.
        // in the past, the guid was required, but we removed that requirement.
        // if we do not insert a guid, users who downgrade their version of firefox will
        // crash when loading their pinned tabs.
        //
        // We have since allowed the guid to be optional, and should remove this guid
        // once we stop supporting downgrading to any versions less than 110.
        let args: Args = [site.url, now, site.title, site.id, "dummy-guid", host]
        let arglist = BrowserDB.varlist(args.count)

        return self.database.run([("INSERT OR REPLACE INTO pinned_top_sites (url, pinDate, title, historyID, guid, domain) VALUES \(arglist)", args)])
        >>== {
            self.notificationCenter.post(name: .TopSitesUpdated, object: self)
            return succeed()
        }
    }
}
