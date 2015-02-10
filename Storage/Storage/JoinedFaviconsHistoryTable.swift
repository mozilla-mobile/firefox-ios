/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let FaviconVisits = "faviconSiteMapping"

// This isn't a real table. Its an abstraction around the history and visits table
// to simpify queries that should join both tables. It also handles making sure that
// inserts/updates/delete update both tables appropriately. i.e.
// 1.) Deleteing a history entry here will also remove all visits to it
// 2.) Adding a visit here will ensure that a site exists for the visit
// 3.) Updates currently only update site information.
class JoinedFaviconsHistoryTable<T>: GenericTable<(site: Site?, icon: Favicon?)> {
    private let favicons: FaviconsTable<Favicon>
    private let history: HistoryTable<Site>

    init(files: FileAccessor) {
        self.favicons = FaviconsTable<Favicon>(files: files)
        self.history = HistoryTable<Site>()
    }

    override var name: String { return FaviconVisits }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "siteId INTEGER NOT NULL, " +
        "faviconId INTEGER NOT NULL" }

    override func getInsertAndArgs(inout item: Type) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.site!.id)
        args.append(item.icon!.id)
        return ("INSERT INTO \(name) (siteId, faviconId) VALUES (?,?)", args)
    }

    override func getUpdateAndArgs(inout item: Type) -> (String, [AnyObject?])? {
        // We don't support updates here...
        return nil
    }

    override func getDeleteAndArgs(inout item: Type?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        var sql = "DELETE FROM \(FaviconVisits)"
        if let item = item {
            sql += " WHERE"
            if let site = item.site {
                args.append(site.id!)
                sql += " siteId = ?"
            }

            if let icon = item.icon {
                args.append(icon.id!)
                sql += " faviconId = ?"
            }
        }
        println("Delete \(sql) \(args)")
        return (sql, args)
    }

    override func create(db: SQLiteDBConnection, version: Int) -> Bool {
        history.create(db, version: version)
        favicons.create(db, version: version)
        return super.create(db, version: version)
    }

    override func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        if history.updateTable(db, from: from, to: to) && favicons.updateTable(db, from: from, to: to) {
            return super.updateTable(db, from: from, to: to)
        }
        return false
    }

    override func insert(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        if let (site, favicon) = item {
            if let site = site {
                history.insertOrUpdate(db, obj: site)
            } else {
                println("Must have a site to insert in \(name)")
                return -1
            }

            if let icon = favicon {
                favicons.insertOrUpdate(db, obj: icon)
            } else {
                println("Must have an icon to insert in \(name)")
                return -1
            }

            let args: [AnyObject?] = [item?.icon?.id, item?.site?.id]
            let c = db.executeQuery("SELECT * FROM \(FaviconVisits) WHERE faviconId = ? AND siteId = ?", factory: {
                (row) -> Type in return (nil, nil)
            }, withArgs: args)
            if c.count > 0 {
                return -1
            }

            return super.insert(db, item: item, err: &err)
        }

        return -1
    }

    override func update(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        if let (site, favicon) = item {
            history.update(db, item: site, err: &err)
            favicons.update(db, item: favicon, err: &err)
            return super.update(db, item: item, err: &err)
        }

        return -1
    }

    func factory(result: SDRow) -> (Site, Favicon) {
        let site = Site(url: result["siteUrl"] as String, title: result["title"] as String)
        site.guid = result["guid"] as? String
        site.id = result["historyId"] as? Int

        let favicon = Favicon(url: result["iconUrl"] as String,
            date: NSDate(timeIntervalSince1970: result["date"] as Double),
            type: IconType(rawValue: result["iconType"] as Int)!)
        favicon.id = result["iconId"] as? Int

        return (site, favicon)
    }

    override func query(db: SQLiteDBConnection, options: QueryOptions?) -> Cursor {
        var args = [AnyObject?]()
        var sql = "SELECT \(history.name).id as historyId, \(history.name).url as siteUrl, title, guid, " +
                  "\(favicons.name).id as iconId, \(favicons.name).url as iconUrl, date, \(favicons.name).type as iconType FROM \(history.name) " +
                  "INNER JOIN \(FaviconVisits) ON \(history.name).id = \(FaviconVisits).siteId " +
                  "INNER JOIN \(favicons.name) ON \(favicons.name).id = \(FaviconVisits).faviconId";

        if let filter: AnyObject = options?.filter {
            sql += " WHERE siteUrl LIKE ?"
            args.append("%\(filter)%")
        }

        println("\(sql) \(args)")
        return db.executeQuery(sql, factory: factory, withArgs: args)
    }
}
