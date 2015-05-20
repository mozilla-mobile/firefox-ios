/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

private let LogPII = false

class NoSuchRecordError: ErrorType {
    let guid: GUID
    init(guid: GUID) {
        self.guid = guid
    }
    var description: String {
        return "No such record: \(guid)."
    }
}

func failOrSucceed<T>(err: NSError?, op: String, val: T) -> Deferred<Result<T>> {
    if let err = err {
        log.debug("\(op) failed: \(err.localizedDescription)")
        return deferResult(DatabaseError(err: err))
    }

    return deferResult(val)
}

func failOrSucceed(err: NSError?, op: String) -> Success {
    return failOrSucceed(err, op, ())
}

/*
// Here's the Swift equivalent of the below.
func simulatedFrecency(now: MicrosecondTimestamp, then: MicrosecondTimestamp, visitCount: Int) -> Double {
    let ageMicroseconds = (now - then)
    let ageDays = Double(ageMicroseconds) / 86400000000.0         // In SQL the .0 does the coercion.
    let f = 100 * 225 / ((ageSeconds * ageSeconds) + 225)
    return Double(visitCount) * max(1.0, f)
}
*/

func getMicrosecondFrecencySQL(visitDateColumn: String, visitCountColumn: String) -> String {
    let now = NSDate.nowMicroseconds()
    let microsecondsPerDay = 86_400_000_000.0      // 1000 * 1000 * 60 * 60 * 24
    let ageDays = "(\(now) - (\(visitDateColumn))) / \(microsecondsPerDay)"
    return "\(visitCountColumn) * max(1, 100 * 225 / (\(ageDays) * \(ageDays) + 225))"
}

extension SDRow {
    func getTimestamp(column: String) -> Timestamp? {
        return (self[column] as? NSNumber)?.unsignedLongLongValue
    }

    func getBoolean(column: String) -> Bool {
        if let val = self[column] as? Int {
            return val != 0
        }
        return false
    }
}

/**
 * The sqlite-backed implementation of the history protocol.
 */
public class SQLiteHistory {
    let db: BrowserDB
    let favicons: FaviconsTable<Favicon>

    private var ignoredSchemes = ["about"]

    required public init(db: BrowserDB) {
        self.db = db
        self.favicons = FaviconsTable<Favicon>()
        db.createOrUpdate(self.favicons)

        // BrowserTable exists only to perform create/update etc. operations -- it's not
        // a queryable thing that needs to stick around.
        db.createOrUpdate(BrowserTable())
    }
}

extension SQLiteHistory: BrowserHistory {
    public func removeHistoryForURL(url: String) -> Success {
        let markArgs: Args = [NSDate.nowNumber(), url]
        let markDeleted = "UPDATE \(TableHistory) SET is_deleted = 1, should_upload = 1, local_modified = ? WHERE url = ?"
        let visitArgs: Args = [url]
        let deleteVisits = "DELETE FROM \(TableVisits) WHERE siteID = (SELECT id FROM \(TableHistory) WHERE url = ?)"
        return self.db.run(deleteVisits, withArgs: visitArgs) >>> { self.db.run(markDeleted, withArgs: markArgs) }
    }

    // Note: clearing history isn't really a sane concept in the presence of Sync.
    // This method should be split to do something else.
    public func clearHistory() -> Success {
        let s: Site? = nil
        var err: NSError? = nil

        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            err = conn.executeChange("DELETE FROM \(TableVisits)", withArgs: nil)
            if err == nil {
                err = conn.executeChange("DELETE FROM \(TableFaviconSites)", withArgs: nil)
            }
            if err == nil {
                err = conn.executeChange("DELETE FROM \(TableHistory)", withArgs: nil)
            }
            return 1
        }

        return failOrSucceed(err, "Clear")
    }

    private func isIgnoredURL(url: String) -> Bool {
        if let url = NSURL(string: url) {
            if let scheme = url.scheme {
                if let index = find(ignoredSchemes, scheme) {
                    return true
                }
            }
        }

        return false
    }

    func recordVisitedSite(site: Site) -> Success {
        var error: NSError? = nil

        // Don't store visits to sites with about: protocols
        if isIgnoredURL(site.url) {
            return deferResult(IgnoredSiteError())
        }

        db.withWritableConnection(&error) { (conn, inout err: NSError?) -> Int in
            let now = NSDate.nowNumber()

            // We know we're adding a new visit, so we'll need to upload this record.
            // If we ever switch to per-visit change flags, this should turn into a CASE statement like
            //   CASE WHEN title IS ? THEN max(should_upload, 1) ELSE should_upload END
            // so that we don't flag this as changed unless the title changed.
            let update = "UPDATE \(TableHistory) SET title = ?, local_modified = ?, is_deleted = 0, should_upload = 1 WHERE url = ?"
            let updateArgs: Args? = [site.title, now, site.url]
            if LogPII {
                log.debug("Setting title to \(site.title) for URL \(site.url)")
            }
            error = conn.executeChange(update, withArgs: updateArgs)
            if error != nil {
                log.warning("Update failed with \(err?.localizedDescription)")
                return 0
            }
            if conn.numberOfRowsModified > 0 {
                return conn.numberOfRowsModified
            }

            // Insert instead.
            let insert = "INSERT INTO \(TableHistory) (guid, url, title, local_modified, is_deleted, should_upload) VALUES (?, ?, ?, ?, 0, 1)"
            let insertArgs: Args? = [Bytes.generateGUID(), site.url, site.title, now]
            error = conn.executeChange(insert, withArgs: insertArgs)
            if error != nil {
                log.warning("Insert failed with \(err?.localizedDescription)")
                return 0
            }
            return 1
        }

        return failOrSucceed(error, "Record site")
    }

    // TODO: thread siteID into this to avoid the need to do the lookup.
    func addLocalVisitForExistingSite(visit: SiteVisit) -> Success {
        var error: NSError? = nil
        db.withWritableConnection(&error) { (conn, inout err: NSError?) -> Int in
            // INSERT OR IGNORE because we *might* have a clock error that causes a timestamp
            // collision with an existing visit, and it would really suck to error out for that reason.
            let insert = "INSERT OR IGNORE INTO \(TableVisits) (siteID, date, type, is_local) VALUES (" +
                         "(SELECT id FROM \(TableHistory) WHERE url = ?), ?, ?, 1)"
            let realDate = NSNumber(unsignedLongLong: visit.date)
            let insertArgs: Args? = [visit.site.url, realDate, visit.type.rawValue]
            error = conn.executeChange(insert, withArgs: insertArgs)
            if error != nil {
                log.warning("Insert visit failed with \(err?.localizedDescription)")
                return 0
            }
            return 1
        }

        return failOrSucceed(error, "Record visit")
    }

    public func addLocalVisit(visit: SiteVisit) -> Success {
        return recordVisitedSite(visit.site)
         >>> { self.addLocalVisitForExistingSite(visit) }
    }

    public func getSitesByFrecencyWithLimit(limit: Int) -> Deferred<Result<Cursor<Site>>> {
        let frecencySQL = getMicrosecondFrecencySQL("visitDate", "visitCount")
        let orderBy = "ORDER BY \(frecencySQL) DESC "
        return self.getFilteredSitesWithLimit(limit, whereURLContains: nil, orderBy: orderBy, includeIcon: true)
    }

    public func getSitesByFrecencyWithLimit(limit: Int, whereURLContains filter: String) -> Deferred<Result<Cursor<Site>>> {
        let frecencySQL = getMicrosecondFrecencySQL("visitDate", "visitCount")
        let orderBy = "ORDER BY \(frecencySQL) DESC "
        return self.getFilteredSitesWithLimit(limit, whereURLContains: filter, orderBy: orderBy, includeIcon: true)
    }

    public func getSitesByLastVisit(limit: Int) -> Deferred<Result<Cursor<Site>>> {
        let orderBy = "ORDER BY visitDate DESC "
        return self.getFilteredSitesWithLimit(limit, whereURLContains: nil, orderBy: orderBy, includeIcon: true)
    }

    private class func basicHistoryColumnFactory(row: SDRow) -> Site {
        let id = row["historyID"] as! Int
        let url = row["url"] as! String
        let title = row["title"] as! String
        let guid = row["guid"] as! String

        let site = Site(url: url, title: title)
        site.guid = guid
        site.id = id

        if let visitDate = row.getTimestamp("visitDate") {
            site.latestVisit = Visit(date: visitDate, type: VisitType.Unknown)
        }

        return site
    }

    private class func iconHistoryColumnFactory(row: SDRow) -> Site {
        let site = basicHistoryColumnFactory(row)

        if let iconType = row["iconType"] as? Int,
           let iconURL = row["iconURL"] as? String,
           let iconDate = row["iconDate"] as? Double,
           let iconID = row["iconID"] as? Int {
                let date = NSDate(timeIntervalSince1970: iconDate)
                let icon = Favicon(url: iconURL, date: date, type: IconType(rawValue: iconType)!)
                site.icon = icon
        }

        return site
    }

    private func getFilteredSitesWithLimit(limit: Int, whereURLContains filter: String?, orderBy: String, includeIcon: Bool) -> Deferred<Result<Cursor<Site>>> {
        let args: Args?
        let whereClause: String
        if let filter = filter {
            args = ["%\(filter)%", "%\(filter)%"]
            whereClause = " WHERE ((\(TableHistory).url LIKE ?) OR (\(TableHistory).title LIKE ?)) "
        } else {
            args = []
            whereClause = " "
        }

        let historySQL =
        "SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, title, guid, " +
        "max(\(TableVisits).date) AS visitDate, " +
        "count(\(TableVisits).date) AS visitCount " +
        "FROM \(TableHistory) INNER JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id " +
        whereClause +
        "GROUP BY \(TableHistory).id " +
        orderBy
        "LIMIT \(limit) "

        if includeIcon {
            // We select the history items then immediately join to get the largest icon.
            // We do this so that we limit and filter *before* joining against icons.
            let sql = "SELECT " +
                "historyID, url, title, guid, visitDate, visitCount " +
                "iconID, iconURL, iconDate, iconType, iconWidth " +
                "FROM (\(historySQL)) LEFT OUTER JOIN " +
                "view_history_id_favicon ON historyID = view_history_id_favicon.id"
            let factory = SQLiteHistory.iconHistoryColumnFactory
            return db.runQuery(sql, args: args, factory: factory)
        }

        let factory = SQLiteHistory.basicHistoryColumnFactory
        return db.runQuery(historySQL, args: args, factory: factory)
    }
}

extension SQLiteHistory: Favicons {
    public func clearFavicons() -> Success {
        var err: NSError? = nil

        db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            err = conn.executeChange("DELETE FROM \(TableFaviconSites)", withArgs: nil)
            if err == nil {
                err = conn.executeChange("DELETE FROM \(TableFavicons)", withArgs: nil)
            }
            return 1
        }

        return failOrSucceed(err, "Clear favicons")
    }

    public func addFavicon(icon: Favicon) -> Deferred<Result<Int>> {
        var err: NSError?
        let res = db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            // Blind! We don't see failure here.
            let id = self.favicons.insertOrUpdate(conn, obj: icon)
            return id ?? 0
        }
        if err == nil {
            return deferResult(res)
        }
        return deferResult(DatabaseError(err: err))
    }

    /**
     * This method assumes that the site has already been recorded
     * in the history table.
     */
    public func addFavicon(icon: Favicon, forSite site: Site) -> Deferred<Result<Int>> {
        if LogPII {
            log.verbose("Adding favicon \(icon.url) for site \(site.url).")
        }
        func doChange(query: String, args: Args?) -> Deferred<Result<Int>> {
            var err: NSError?
            let res = db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
                // Blind! We don't see failure here.
                let id = self.favicons.insertOrUpdate(conn, obj: icon)

                // Now set up the mapping.
                err = conn.executeChange(query, withArgs: args)
                if let err = err {
                    log.error("Got error adding icon: \(err).")
                    return 0
                }

                return id ?? 0
            }

            if res == 0 {
                return deferResult(DatabaseError(err: err))
            }
            return deferResult(icon.id!)
        }

        let siteSubselect = "(SELECT id FROM \(TableHistory) WHERE url = ?)"
        let iconSubselect = "(SELECT id FROM \(TableFavicons) WHERE url = ?)"
        let insertOrIgnore = "INSERT OR IGNORE INTO \(TableFaviconSites)(siteID, faviconID) VALUES "
        if let iconID = icon.id {
            // Easy!
            if let siteID = site.id {
                // So easy!
                let args: Args? = [siteID, iconID]
                return doChange("\(insertOrIgnore) (?, ?)", args)
            }

            // Nearly easy.
            let args: Args? = [site.url, iconID]
            return doChange("\(insertOrIgnore) (\(siteSubselect), ?)", args)

        }

        // Sigh.
        if let siteID = site.id {
            let args: Args? = [siteID, icon.url]
            return doChange("\(insertOrIgnore) (?, \(iconSubselect))", args)
        }

        // The worst.
        let args: Args? = [site.url, icon.url]
        return doChange("\(insertOrIgnore) (\(siteSubselect), \(iconSubselect))", args)
    }
}

extension SQLiteHistory: SyncableHistory {
    public func ensurePlaceWithURL(url: String, hasGUID guid: GUID) -> Success {
        let args: Args = [guid, url]
        return db.run("UPDATE \(TableHistory) SET guid = ? WHERE url = ?", withArgs: args)
    }

    public func deleteByGUID(guid: GUID, deletedAt: Timestamp) -> Success {
        let args: Args = [guid]
        // This relies on ON DELETE CASCADE to remove visits.
        return db.run("DELETE FROM \(TableHistory) WHERE guid = ?", withArgs: args)
    }

    // Fails on non-existence.
    private func getSiteIDForGUID(guid: GUID) -> Deferred<Result<Int>> {
        let args: Args = [guid]
        let query = "SELECT id FROM history WHERE guid = ?"
        let factory: SDRow -> Int = { return $0["id"] as! Int }

        return db.runQuery(query, args: args, factory: factory)
            >>== { cursor in
                if cursor.count == 0 {
                    return deferResult(NoSuchRecordError(guid: guid))
                }
                return deferResult(cursor[0]!)
        }
    }

    public func storeRemoteVisits(visits: [Visit], forGUID guid: GUID) -> Success {
        return self.getSiteIDForGUID(guid)
            >>== { (siteID: Int) -> Success in
            let visitArgs = visits.map { (visit: Visit) -> Args in
                let realDate = NSNumber(unsignedLongLong: visit.date)
                let isLocal = 0
                let args: Args = [siteID, realDate, visit.type.rawValue, isLocal]
                return args
            }

            // Magic happens here. The INSERT OR IGNORE relies on the multi-column uniqueness
            // constraint on `visits`: we allow only one row for (siteID, date, type), so if a
            // local visit already exists, this silently keeps it. End result? Any new remote
            // visits are added with only one query, keeping any existing rows.
            return self.db.bulkInsert(TableVisits, op: .InsertOrIgnore, columns: ["siteID", "date", "type", "is_local"], values: visitArgs)
        }
    }

    private struct HistoryMetadata {
        let id: Int
        let serverModified: Timestamp?
        let localModified: Timestamp?
        let isDeleted: Bool
        let shouldUpload: Bool
        let title: String
    }

    private func metadataForGUID(guid: GUID) -> Deferred<Result<HistoryMetadata?>> {
        let select = "SELECT id, server_modified, local_modified, is_deleted, should_upload, title FROM \(TableHistory) WHERE guid = ?"
        let args: Args = [guid]
        let factory = { (row: SDRow) -> HistoryMetadata in
            return HistoryMetadata(
                id: row["id"] as! Int,
                serverModified: row.getTimestamp("server_modified"),
                localModified: row.getTimestamp("local_modified"),
                isDeleted: row.getBoolean("is_deleted"),
                shouldUpload: row.getBoolean("should_upload"),
                title: row["title"] as! String
            )
        }
        return db.runQuery(select, args: args, factory: factory) >>== { cursor in
            return deferResult(cursor[0])
        }
    }

    public func insertOrUpdatePlace(place: Place, modified: Timestamp) -> Deferred<Result<GUID>> {
        // One of these things will be true here.
        // 0. The item is new.
        //    (a) We have a local place with the same URL but a different GUID.
        //    (b) We have never visited this place locally.
        //    In either case, reconcile and proceed.
        // 1. The remote place is not modified when compared to our mirror of it. This
        //    can occur when we redownload after a partial failure.
        //    (a) And it's not modified locally, either. Nothing to do. Ideally we
        //        will short-circuit so we don't need to update visits. (TODO)
        //    (b) It's modified locally. Don't overwrite anything; let the upload happen.
        // 2. The remote place is modified (either title or visits).
        //    (a) And it's not locally modified. Update the local entry.
        //    (b) And it's locally modified. Preserve the title of whichever was modified last.
        //        N.B., this is the only instance where we compare two timestamps to see
        //        which one wins.

        // We use this throughout.
        let serverModified = NSNumber(unsignedLongLong: modified)

        // Check to see if our modified time is unchanged, if the record exists locally, etc.
        let insertWithMetadata = { (metadata: HistoryMetadata?) -> Deferred<Result<GUID>> in
            if let metadata = metadata {
                // The item exists locally (perhaps originally with a different GUID).
                if metadata.serverModified == modified {
                    log.debug("History item \(place.guid) is unchanged; skipping insert-or-update.")
                    return deferResult(place.guid)
                }

                // Otherwise, the server record must have changed since we last saw it.
                if metadata.shouldUpload {
                    // Uh oh, it changed locally.
                    // This might well just be a visit change, but we can't tell. Usually this conflict is harmless.
                    log.debug("Warning: history item \(place.guid) changed both locally and remotely. Comparing timestamps from different clocks!")
                    if metadata.localModified > modified {
                        log.debug("Local changes overriding remote.")

                        // Update server modified time only. (Though it'll be overwritten again after a successful upload.)
                        let update = "UPDATE \(TableHistory) SET server_modified = ? WHERE id = ?"
                        let args: Args = [serverModified, metadata.id]
                        return self.db.run(update, withArgs: args) >>> always(place.guid)
                    }

                    log.debug("Remote changes overriding local.")
                    // Fall through.
                }

                // The record didn't change locally. Update it.
                log.debug("Updating local history item for guid \(place.guid).")
                let update = "UPDATE \(TableHistory) SET title = ?, server_modified = ?, is_deleted = 0 WHERE id = ?"
                let args: Args = [place.title, serverModified, metadata.id]
                return self.db.run(update, withArgs: args) >>> always(place.guid)
            }

            // The record doesn't exist locally. Insert it.
            log.debug("Inserting remote history item for guid \(place.guid).")
            if LogPII {
                log.debug("Inserting: \(place.url).")
            }
            let insert = "INSERT INTO \(TableHistory) (guid, url, title, server_modified, is_deleted, should_upload) VALUES (?, ?, ?, ?, 0, 0)"
            let args: Args = [place.guid, place.url, place.title, serverModified]
            return self.db.run(insert, withArgs: args) >>> always(place.guid)
        }

        // Make sure that we only need to compare GUIDs by pre-merging on URL.
        return self.ensurePlaceWithURL(place.url, hasGUID: place.guid)
            >>> { self.metadataForGUID(place.guid) >>== insertWithMetadata }
    }

    public func getHistoryToUpload() -> Deferred<Result<[(Place, [Visit])]>> {
        // What we want to do: find all items flagged for update, selecting some number of their
        // visits alongside.
        //
        // A difficulty here: we don't want to fetch *all* visits, only some number of the most recent.
        // (It's not enough to only get new ones, because the server record should contain more.)
        //
        // That's the greatest-N-per-group problem in SQL. Please read and understand the solution
        // to this (particularly how the LEFT OUTER JOIN/HAVING clause works) before changing this query!
        //
        // We can do this in a single query, rather than the N+1 that desktop takes.
        // We then need to flatten the cursor. We do that by collecting
        // places as a side-effect of the factory, producing visits as a result, and merging in memory.

        let args: Args = [
            20,                 // Maximum number of visits to retrieve.
        ]

        // Exclude 'unknown' visits, because they're not syncable.
        let filter = "history.should_upload = 1 AND v1.type IS NOT 0"

        let sql =
        "SELECT " +
        "history.id AS siteID, history.guid AS guid, history.url AS url, history.title AS title, " +
        "v1.siteID AS siteID, v1.date AS visitDate, v1.type AS visitType " +
        "FROM " +
        "visits AS v1 " +
        "JOIN history ON history.id = v1.siteID AND \(filter) " +
        "LEFT OUTER JOIN " +
        "visits AS v2 " +
        "ON v1.siteID = v2.siteID AND v1.date < v2.date " +
        "GROUP BY v1.date " +
        "HAVING COUNT(*) < ? " +
        "ORDER BY v1.siteID, v1.date DESC"

        var places = [Int: Place]()
        var visits = [Int: [Visit]]()

        // Add a place to the accumulator, prepare to accumulate visits, return the ID.
        let ensurePlace: SDRow -> Int = { row in
            let id = row["siteID"] as! Int
            if places[id] == nil {
                let guid = row["guid"] as! String
                let url = row["url"] as! String
                let title = row["title"] as! String
                places[id] = Place(guid: guid, url: url, title: title)
                visits[id] = Array()
            }
            return id
        }

        // Store the place and the visit.
        let factory: SDRow -> Int = { row in
            let date = row.getTimestamp("visitDate")!
            let type = VisitType(rawValue: row["visitType"] as! Int)!
            let visit = Visit(date: date, type: type)
            let id = ensurePlace(row)
            visits[id]?.append(visit)
            return id
        }

        return db.runQuery(sql, args: args, factory: factory)
            >>== { c in

                // Consume every row, with the side effect of populating the places
                // and visit accumulators.
                let count = c.count
                var ids = Set<Int>()
                for row in c {
                    // Collect every ID first, so that we're guaranteed to have
                    // fully populated the visit lists, and we don't have to
                    // worry about only collecting each place once.
                    ids.insert(row!)
                }

                // Now we're done with the cursor. Close it.
                c.close()

                // Now collect the return value.
                return deferResult(map(ids, { return (places[$0]!, visits[$0]!) }))
        }
    }

    public func markAsSynchronized(guids: [GUID], modified: Timestamp) -> Deferred<Result<Timestamp>> {
        // TODO: support longer GUID lists.
        assert(guids.count < 99)

        if guids.isEmpty {
            return deferResult(modified)
        }

        log.debug("Marking \(guids.count) GUIDs as synchronized. Returning timestamp \(modified).")

        let inClause = BrowserDB.varlist(guids.count)
        let sql =
        "UPDATE \(TableHistory) SET " +
        "should_upload = 0, server_modified = \(modified) " +
        "WHERE guid IN \(inClause)"

        let args: Args = guids.map { $0 as AnyObject }
        return self.db.run(sql, withArgs: args) >>> always(modified)
    }
}
