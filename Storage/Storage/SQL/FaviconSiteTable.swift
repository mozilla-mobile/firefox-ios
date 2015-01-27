/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

let TableNameFaviconSites = "faviconSites"

class FaviconSiteTable: Table {
    typealias Type = (site: Site?, icon: SavedFavicon?)
    var name:String { return TableNameFaviconSites }
    var rows: String { return "faviconGuid TEXT NOT NULL, " +
                              "siteGuid TEXT NOT NULL"
    }
    let files: FileAccessor
    

    private let favicons: FaviconsTable<SavedFavicon>
    private let history = HistoryTable<Site>()

    init(files: FileAccessor) {
        self.files = files
        self.favicons = FaviconsTable<SavedFavicon>(files: files)
    }

    func create(db: SQLiteDBConnection, version: Int) -> Bool {
        let success = favicons.create(db, version: version)
        if !success {
            println("Error creating the favicons table")
            return false
        }

        // XXX - smelly? The history table is created in multiple places, so I don't care if it fails here...
        if !history.create(db, version: version) {
            println("Error creating the history table")
        }

        db.executeChange("CREATE TABLE IF NOT EXISTS \(name) (\(rows))")
        return true
    }

    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        return history.updateTable(db, from: from, to: to) && favicons.updateTable(db, from: from, to: to)
    }

    private func getGuidFor(db: SQLiteDBConnection, site: Site) -> String? {
        let opts = QueryOptions()
        opts.filter = site.url

        let cursor = history.query(db, options: opts)
        if (cursor.count != 1) {
            return nil
        }
        return (cursor[0] as Site).guid
    }

    private func getGuidFor(db: SQLiteDBConnection, icon: Favicon) -> String? {
        let opts = QueryOptions()
        opts.filter = icon.url

        let cursor = favicons.query(db, options: opts)
        if (cursor.count != 1) {
            return nil
        }
        return (cursor[0] as Favicon).guid
    }

    private func updateSite(db: SQLiteDBConnection, site: Site, inout err: NSError?) -> Int {
        // If our site doesn't have a guid, we need to find one
        if site.guid == nil {
            if let guid = getGuidFor(db, site: site) {
                return history.update(db, item: site, err: &err)
            } else {
                site.guid = NSUUID().UUIDString
                return history.insert(db, item: site, err: &err)
            }
        }
        return 0
    }

    private func updateFavicon(db: SQLiteDBConnection, icon: SavedFavicon, inout err: NSError?) -> Int {
        // If our site doesn't have a guid, we need to find one
        if icon.guid == nil {
            if let guid = getGuidFor(db, icon: icon) {
                return favicons.update(db, item: icon, err: &err)
            } else {
                icon.guid = NSUUID().UUIDString
                return favicons.insert(db, item: icon, err: &err)
            }
        }

        return 0
    }

    func insert(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        if let fs = item {
            if updateSite(db, site: fs.site!, err: &err) < 0 {
                return -1
            }

            if updateFavicon(db, icon: fs.icon!, err: &err) < 0 {
                return -1
            }

            let query = "INSERT INTO \(TableNameFaviconSites) (faviconGuid, siteGuid) VALUES (?, ?)"
            let args: [AnyObject?] = [fs.icon!.guid, fs.site!.guid]
            if let error = db.executeChange(query, withArgs: args) {
                err = error
                return -1
            }

            return db.lastInsertedRowID
        }

        return -1
    }

    func update(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        return -1
    }

    func delete(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int {
        if let favicon = item?.icon {
            favicons.delete(db, item: favicon, err: &err)
            var args: [AnyObject?] = [favicon.guid]
            if let error = db.executeChange("DELETE FROM \(TableNameFaviconSites) WHERE faviconGuid = ?", withArgs: args) {
                return -1
            }
            return db.numberOfRowsModified
        } else if let site = item?.site {
            // This doesn't delete the site. It just removes all favicon references to it
            var args: [AnyObject?] = [site.guid]
            if let error = db.executeChange("DELETE FROM \(TableNameFaviconSites) WHERE siteGuid = ?", withArgs: args) {
                return -1
            }
            return db.numberOfRowsModified
        } else if item == nil {
            // Clear all favicons
            let item: SavedFavicon? = nil
            favicons.delete(db, item: item, err: &err)
            if let error = db.executeChange("DELETE FROM \(TableNameFaviconSites)", withArgs: nil) {
                return -1
            }
            return db.numberOfRowsModified
        }
        return -1
    }

    func factory(result: SDRow) -> AnyObject {
        //let site = Site(url: result[0] as String, title: result[1] as String)
        //site.guid = result[2] as? String
        let date = NSDate(timeIntervalSince1970: result[4] as Double)
        let icon = Favicon(url: result[3] as String, image: nil, date: date)
        icon.guid = result[6] as? String
        let saved = SavedFavicon(favicon: icon, name: result[5] as String)
        saved.download(files)
        return saved
        //return FaviconSite(site: site, icon: saved)
    }

    func query(db: SQLiteDBConnection, options: QueryOptions?) -> Cursor {
        var args = [AnyObject?]()
        var sql = "SELECT \(TableNameHistory).url as siteUrl, title, \(TableNameHistory).guid as siteGuid, \(TableNameFavicons).url as faviconUrl, " +
                          "updatedDate, file, \(TableNameFavicons).guid as faviconGuid "
        sql += "FROM \(TableNameHistory), \(TableNameFavicons), \(TableNameFaviconSites) " +
               "WHERE \(TableNameFaviconSites).faviconGuid = \(TableNameFavicons).guid " +
               "AND \(TableNameFaviconSites).siteGuid = \(TableNameHistory).guid"

        if let filter = options?.filter {
            // For now this just queries for all the favicons for this site
            sql += " AND \(TableNameHistory).url LIKE ?"
            args.append("\(filter)")
        }

        return db.executeQuery(sql, factory: factory, withArgs: args)
    }
}
