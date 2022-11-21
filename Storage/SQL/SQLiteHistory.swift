// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Glean

private let log = Logger.syncLogger

open class IgnoredSiteError: MaybeErrorType {
    open var description: String {
        return "Ignored site."
    }
}


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
    let notificationCenter: NotificationCenter
    
    required public init(database: BrowserDB,
                         prefs: Prefs,
                         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.database = database
        self.favicons = SQLiteFavicons(db: self.database)
        self.prefs = prefs
        self.notificationCenter = notificationCenter
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
    
    func recordVisitedSite(_ site: Site) -> Success {
         // Don't store visits to sites with about: protocols
         if isIgnoredURL(site.url as String) {
             return deferMaybe(IgnoredSiteError())
         }


         return database.withConnection { conn -> Void in
             let now = Date.now()

             if self.updateSite(site, atTime: now, withConnection: conn) > 0 {
                 return
             }

             // Insert instead.
             if self.insertSite(site, atTime: now, withConnection: conn) > 0 {
                 return
             }

             let err = DatabaseError(description: "Unable to update or insert site; Invalid key returned")
             log.error("recordVisitedSite encountered an error: \(err.localizedDescription)")
             throw err
         }
     }

     func updateSite(_ site: Site, atTime time: Timestamp, withConnection conn: SQLiteDBConnection) -> Int {
         // We know we're adding a new visit, so we'll need to upload this record.
         // If we ever switch to per-visit change flags, this should turn into a CASE statement like
         //   CASE WHEN title IS ? THEN max(should_upload, 1) ELSE should_upload END
         // so that we don't flag this as changed unless the title changed.
         //
         // Note that we will never match against a deleted item, because deleted items have no URL,
         // so we don't need to unset is_deleted here.
         guard let host = (site.url as String).asURL?.normalizedHost else {
             return 0
         }

         let update = "UPDATE history SET title = ?, local_modified = ?, should_upload = 1, domain_id = (SELECT id FROM domains where domain = ?) WHERE url = ?"
         let updateArgs: Args? = [site.title, time, host, site.url]
         if Logger.logPII {
             log.debug("Setting title to \(site.title) for URL \(site.url)")
         }
         do {
             try conn.executeChange(update, withArgs: updateArgs)
             return conn.numberOfRowsModified
         } catch let error as NSError {
             log.warning("Update failed with error: \(error.localizedDescription)")
             return 0
         }
     }

     fileprivate func insertSite(_ site: Site, atTime time: Timestamp, withConnection conn: SQLiteDBConnection) -> Int {
         if let host = (site.url as String).asURL?.normalizedHost {
             do {
                 try conn.executeChange("INSERT OR IGNORE INTO domains (domain) VALUES (?)", withArgs: [host])
             } catch let error as NSError {
                 log.warning("Domain insertion failed with \(error.localizedDescription)")
                 return 0
             }

             let insert = """
                 INSERT INTO history (
                     guid, url, title, local_modified, is_deleted, should_upload, domain_id
                 )
                 SELECT ?, ?, ?, ?, 0, 1, id FROM domains WHERE domain = ?
                 """

             let insertArgs: Args? = [site.guid ?? Bytes.generateGUID(), site.url, site.title, time, host]
             do {
                 try conn.executeChange(insert, withArgs: insertArgs)
             } catch let error as NSError {
                 log.warning("Site insertion failed with \(error.localizedDescription)")
                 return 0
             }

             return 1
         }

         if Logger.logPII {
             log.warning("Invalid URL \(site.url). Not stored in history.")
         }
         return 0
     }
}
    
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
        return self.recordVisitedSite(site) >>== {
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

}
