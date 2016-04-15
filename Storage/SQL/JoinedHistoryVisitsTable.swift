/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

let HistoryVisits = "history-visits"

// Helper function for sorting by frecency
func getFrecency() -> String {
    let now = NSDate().timeIntervalSince1970
    let age = "(\(now) - visitDate) / 86400"
    return "visits * MAX(1, 100 * 225 / (\(age) * \(age) + 225))"
}

// This isn't a real table. Its an abstraction around the history and visits table
// to simpify queries that should join both tables. It also handles making sure that
// inserts/updates/delete update both tables appropriately. i.e.
// 1.) Deleteing a history entry here will also remove all visits to it
// 2.) Adding a visit here will ensure that a site exists for the visit
// 3.) Updates currently only update site information.
class JoinedHistoryVisitsTable: Table {
    typealias Type = (site: Site?, visit: Visit?)
    var name: String { return HistoryVisits }
    var version: Int { return 1 }

    private let visits = VisitsTable<Visit>()
    private let history = HistoryTable<Site>()
    private let favicons = FaviconsTable<Favicon>()
    private let faviconSites = JoinedFaviconsHistoryTable<(Site, Favicon)>()

    private func getIDFor(db: SQLiteDBConnection, site: Site) -> Int? {
        let opts = QueryOptions()
        opts.filter = site.url

        let cursor = history.query(db, options: opts)
        if (cursor.count != 1) {
            return nil
        }
        return (cursor[0] as? Site)?.id
    }

    func create(db: SQLiteDBConnection, version: Int) -> Bool {
        return history.create(db, version: version) &&
            visits.create(db, version: version) &&
            favicons.create(db, version: version) &&
            faviconSites.create(db, version: version)
    }

    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        return history.updateTable(db, from: from, to: to) &&
            visits.updateTable(db, from: from, to: to) &&
            favicons.updateTable(db, from: from, to: to) &&
            faviconSites.updateTable(db, from: from, to: to)
    }

    func exists(db: SQLiteDBConnection) -> Bool {
        return history.exists(db) && visits.exists(db)
    }

    func drop(db: SQLiteDBConnection) -> Bool {
        return history.drop(db) && visits.drop(db)
    }

    private func updateSite(db: SQLiteDBConnection, site: Site, inout err: NSError?) -> Int {
        // If our site doesn't have an id, we need to find one
        if site.id == nil {
            if let id = getIDFor(db, site: site) {
                site.id = id
                // Update the page title
                return history.update(db, item: site, err: &err)
            } else {
                // Make sure we have a site in the table first
                site.id = history.insert(db, item: site, err: &err)
                return 1
            }
        }

        // Update the page title
        return history.update(db, item: site, err: &err)
    }

    func insert(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        if let visit = item?.visit {
            if updateSite(db, site: visit.site, err: &err) < 0 {
                return -1;
            }

            // Now add a visit
            return visits.insert(db, item: visit, err: &err)
        } else if let site = item?.site {
            if updateSite(db, site: site, err: &err) < 0 {
                return -1;
            }

            // Now add a visit
            let visit = Visit(site: site, date: NSDate())
            return visits.insert(db, item: visit, err: &err)
        }

        return -1
    }

    func update(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        return visits.update(db, item: item?.visit, err: &err);
    }

    func delete(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        if let visit = item?.visit {
            return visits.delete(db, item: visit, err: &err)
        } else if let site = item?.site {
            let v = Visit(site: site, date: NSDate())
            visits.delete(db, item: v, err: &err)
            return history.delete(db, item: site, err: &err)
        } else if item == nil {
            let site: Site? = nil
            let visit: Visit? = nil
            history.delete(db, item: site, err: &err);
            return visits.delete(db, item: visit, err: &err);
        }
        return -1
    }

    func factory(result: SDRow) -> (site: Site, visit: Visit) {
        let site = Site(url: result["siteUrl"] as! String, title: result["title"] as String ?? "")
        site.guid = result["guid"] as? String
        site.id = result["historyId"] as? Int

        let d = NSDate(timeIntervalSince1970: result["visitDate"] as! Double)

        // This visit is a combination of multiple visits. Type is meaningless.
        let visit = Visit(site: site, date: d, type: VisitType.Unknown)
        visit.id = result["visitId"] as? Int

        site.latestVisit = visit

        if let iconurl = result["iconUrl"] as? String,
           let iconDate = result["iconDate"] as? Double,
           let iconType = result["iconType"] as? Int {

            let icon = Favicon(url: iconurl, date: NSDate(timeIntervalSince1970: iconDate), type: IconType(rawValue: iconType)!)
            icon.id = result["faviconId"] as? Int
            site.icon = icon
        }

        return (site, visit)
    }

    func query(db: SQLiteDBConnection, options: QueryOptions?) -> Cursor {
        var args = [AnyObject?]()
        var sql = "SELECT \(history.name).id as historyId, \(history.name).url as siteUrl, title, guid, max(\(visits.name).date) as visitDate, count(\(visits.name).id) as visits, " +
                  "\(favicons.name).id as faviconId, \(favicons.name).url as iconUrl, \(favicons.name).date as iconDate, \(favicons.name).type as iconType FROM \(visits.name) " +
                  "INNER JOIN \(history.name) ON \(history.name).id = \(visits.name).siteId " +
                  "LEFT JOIN \(faviconSites.name) ON \(faviconSites.name).siteId = \(history.name).id LEFT JOIN \(favicons.name) ON \(faviconSites.name).faviconId = \(favicons.name).id ";

        if let filter: AnyObject = options?.filter {
            sql += "WHERE siteUrl LIKE ? "
            args.append("%\(filter)%")
        }

        sql += "GROUP BY historyId";

        // Trying to do this in one line (i.e. options?.sort == .LastVisit) breaks the Swift compiler
        if let sort = options?.sort {
            if sort == .LastVisit {
                sql += " ORDER BY visitDate DESC"
            } else if sort == .Frecency {
                sql += " ORDER BY \(getFrecency()) DESC"
            }
        }

        return db.executeQuery(sql, factory: factory, withArgs: args)
    }
}
