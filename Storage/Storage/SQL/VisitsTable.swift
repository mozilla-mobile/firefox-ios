/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let TableNameVisits = "visits"

// NOTE: If you add a new Table, make sure you update the version number in BrowserDB.swift!
// This is our default visits store.
class VisitsTable<T>: GenericTable<Visit> {
    override var name: String { return TableNameVisits }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                                       "siteId INTEGER NOT NULL, " +
                                       "date REAL NOT NULL, " +
                                       "type INTEGER NOT NULL" }
    override var version: Int { return 1 }

    override func getInsertAndArgs(inout item: Visit) -> (String, [AnyObject?])? {
        // Runtime errors happen if we let Swift try to infer the type of this array
        // so we construct it very specifically.
        var args = [AnyObject?]()

        // We assume that if you're using this, you've gotten a site from somewhere that has an ID
        // If you don't know if you have an ID, use JoinedHistoryVisitsTable.swift instead.
        args.append(item.site.id!)

        args.append(item.date.timeIntervalSince1970)
        args.append(item.type.rawValue)
        return ("INSERT INTO \(TableNameVisits) (siteId, date, type) VALUES (?,?,?)", args)
    }

    override func getUpdateAndArgs(inout item: Visit) -> (String, [AnyObject?])? {
        return nil
    }

    override func getDeleteAndArgs(inout item: Visit?) -> (String, [AnyObject?])? {
        if let visit = item {
            return ("DELETE FROM \(TableNameVisits) WHERE id = ?", [visit.id])
        }
        return ("DELETE FROM \(TableNameVisits)", [AnyObject]())
    }

    override var factory: ((row: SDRow) -> Visit)? {
        return { row -> Visit in
            let site = Site(url: "", title: "")
            site.id = row["siteId"] as? Int

            let dt = row["date"] as NSTimeInterval
            let date = NSDate(timeIntervalSince1970: dt)
            var type = VisitType(rawValue: row["type"] as Int)
            if type == nil {
                type = VisitType.Unknown
            }
            let visit = Visit(site: site, date: date, type: type!)
            visit.id = row["id"] as? Int
            return visit
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        if let filter: AnyObject = options?.filter {
            let args : [AnyObject?] = [filter]
            return ("SELECT id, siteId, date, type FROM \(TableNameVisits) WHERE siteId = ?", args)
        }
        return ("SELECT id, siteId, date, type FROM \(TableNameVisits)", [AnyObject?]())
    }
}
