/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let HistoryVisits = "history-visits"

class JoinedHistoryVisitsTable: Table {
    var name: String { return HistoryVisits }

    private let visits = VisitsTable<Visit>()
    private let history = HistoryTable<Site>()

    private func getGuidFor(db: SQLiteDBConnection, site: Site) -> String? {
        let opts = QueryOptions()
        opts.filter = site.url

        let cursor = history.query(db, options: opts)
        if (cursor.count != 1) {
            return nil
        }
        return (cursor[0] as Site).guid
    }

    func create(db: SQLiteDBConnection, version: Int) -> Bool {
        return history.create(db, version: version) && visits.create(db, version: version)
    }

    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        return history.updateTable(db, from: from, to: to) && visits.updateTable(db, from: from, to: to)
    }

    private func updateSite(db: SQLiteDBConnection, site: Site, inout err: NSError?) -> Int {
        // If our site doesn't have a guid, we need to find one
        if site.guid == nil {
            if let guid = getGuidFor(db, site: site) {
                site.guid = guid
                // Update the page title
                return history.update(db, item: site, err: &err)
            } else {
                // Make sure we have a site in the table first
                site.guid = NSUUID().UUIDString
                return history.insert(db, item: site, err: &err)
            }
        }

        // Update the page title
        return history.update(db, item: site, err: &err)
    }

    func insert<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        if let visit = item as? Visit {
            if updateSite(db, site: visit.site, err: &err) < 0 {
                return -1;
            }

            // Now add a visit
            return visits.insert(db, item: visit, err: &err)
        } else if let site = item as? Site {
            if updateSite(db, site: site, err: &err) < 0 {
                return -1;
            }

            // Now add a visit
            let visit = Visit(site: site, date: NSDate())
            return visits.insert(db, item: visit, err: &err)
        }

        return -1
    }

    func update<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        return visits.update(db, item: item, err: &err);
    }

    func delete<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        if let visit = item as? Visit {
            return visits.delete(db, item: visit, err: &err)
        } else if let site = item as? Site {
            visits.delete(db, item: site, err: &err)
            return history.delete(db, item: site, err: &err)
        } else if item == nil {
            let site: Site? = nil
            let visit: Visit? = nil
            history.delete(db, item: site, err: &err);
            return visits.delete(db, item: visit, err: &err);
        }
        return -1
    }

    func factory(result: SDRow) -> AnyObject {
        let site = Site(url: result[1] as String, title: result[2] as String)
        site.guid = result[0] as? String
        return site
    }

    func query(db: SQLiteDBConnection, options: QueryOptions?) -> Cursor {
        var args = [AnyObject?]()
        var sql = "SELECT siteGuid as guid, url, title FROM \(TableNameVisits) " +
                  "INNER JOIN \(TableNameHistory) ON \(TableNameHistory).guid = \(TableNameVisits).siteGuid ";

        if let filter = options?.filter {
            sql += "WHERE url LIKE ? "
            args.append("%\(filter)%")
        }

        sql += "GROUP BY siteGuid";

        // Trying to do this in one line (i.e. options?.sort == .LastVisit) breaks the Swift compiler
        if let sort = options?.sort {
            if sort == .LastVisit {
                sql += " ORDER BY date DESC"
            }
        }

        return db.executeQuery(sql, factory: factory, withArgs: args)
    }
}
