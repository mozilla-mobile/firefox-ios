/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let TableNameVisits = "visits"

class VisitsTable: GenericTable {
    override var name: String { return TableNameVisits }
    override var rows: String { return "guid TEXT NOT NULL UNIQUE, " +
                      "siteGuid TEXT NOT NULL, " +
                      "date DATE NOT NULL" }

    override func getInsertAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        let visit = item as Visit
        return ("INSERT INTO \(TableNameVisits) (guid, siteGuid, date) VALUES (?,?,?)",
            [ visit.guid, visit.site.guid, visit.date.timeIntervalSince1970])
    }

    override func getUpdateAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        let visit = item as Visit
        return (nil, [String]());
    }

    override func getDeleteAndArgs<T>(item: T?) -> (String?, [AnyObject?]) {
        if let visit = item as? Visit {
            return ("DELETE FROM \(TableNameVisits) WHERE guid = ?", [visit.guid])
        } else if let site = item as? Site {
            return ("DELETE FROM \(TableNameVisits) WHERE siteGuid = ?", [site.guid])
        } else if item != nil {
            return (nil, [String]())
        }
        return ("DELETE FROM \(TableNameVisits)", [String]())
    }

    override func factory(row: SDRow) -> AnyObject? {
        let site = Site(url: "", title: "")
        site.guid = row["siteGuid"] as? String

        let dt = NSTimeInterval(row["date"] as Int)
        let date = NSDate(timeIntervalSince1970: dt)
        let v = Visit(site: site, date: date)
        v.guid = row["guid"] as String
        return v
    }

    override func getQueryAndArgs(filter: String?) -> (String, [AnyObject?]) {
        if let filter = filter {

        }
        return ("SELECT guid, siteGuid, date FROM \(TableNameVisits)", [String]())
    }
}
