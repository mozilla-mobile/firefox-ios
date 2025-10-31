// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

private let ignoredSchemes = ["about"]

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

extension BrowserDBSQLite: PinnedSites {
    // Methods for new homepage that complies with Swift 6 Migration
    public func remove(pinnedSite site: Site) async throws {
        guard let host = (site.url as String).asURL?.normalizedHost else {
            throw DatabaseError(description: "Invalid url for site \(site.url)")
        }

        try await awaitDatabaseRun(for: [("DELETE FROM pinned_top_sites where domain = ?", [host])])
        self.notificationCenter.post(name: .TopSitesUpdated, object: nil)
        try await awaitDatabaseRun(for: [("UPDATE domains SET showOnTopSites = 1 WHERE domain = ?", [host])])
    }

    /// Helper method that converts using the deferred types to result
    /// and adopts modern swift concurrency to avoid refactoring the database level
    private func awaitDatabaseRun(for commands: [(String, Args)]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            database.run(commands).upon { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // Legacy methods that use deferred
    public func removeFromPinnedTopSites(_ site: Site) -> Success {
        guard let host = (site.url as String).asURL?.normalizedHost else {
            return deferMaybe(DatabaseError(description: "Invalid url for site \(site.url)"))
        }

        // do a fuzzy delete so dupes can be removed
        let query: (String, Args?) = ("DELETE FROM pinned_top_sites where domain = ?", [host])
        return database.run([query])
            .bind { result in
                if let failureValue = result.failureValue {
                    return deferMaybe(failureValue)
                }

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

        let args: Args = [site.url, now, site.title, host]
        let arglist = BrowserDB.varlist(args.count)

        return self.database
            .run([("INSERT OR REPLACE INTO pinned_top_sites (url, pinDate, title, domain) VALUES \(arglist)", args)])
            .bind { result in
                if let error = result.failureValue {
                    return deferMaybe(error)
                }
                self.notificationCenter.post(name: .TopSitesUpdated, object: self)
                return succeed()
            }
    }

    public func addPinnedTopSite(_ site: Site, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        addPinnedTopSite(site).upon { result in
            if result.successValue != nil {
                completion(.success(()))
            } else if let error = result.failureValue {
                completion(.failure(error))
            }
        }
    }
}
