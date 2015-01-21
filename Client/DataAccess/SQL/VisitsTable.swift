/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let TableNameVisits = "visits"

class VisitsTable<T>: GenericTable<Visit> {
    override var name: String { return TableNameVisits }
    override var rows: String { return "guid TEXT NOT NULL UNIQUE, " +
                      "siteGuid TEXT NOT NULL, " +
                      "date REAL NOT NULL" }

    override func getInsertAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        let visit = item as Visit
        // Runtime errors happen if we let Swift try to infer the type of this array
        // so we construct it very specifically.
        var args = [AnyObject?]()
        args.append(visit.guid)
        args.append(visit.site.guid!)
        args.append(visit.date.timeIntervalSince1970)
        return ("INSERT INTO \(TableNameVisits) (guid, siteGuid, date) VALUES (?,?,?)", args)
    }

    override func getUpdateAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        let visit = item as Visit
        return (nil, [AnyObject?]());
    }

    override func getDeleteAndArgs<T>(item: T?) -> (String?, [AnyObject?]) {
        if let visit = item as? Visit {
            return ("DELETE FROM \(TableNameVisits) WHERE guid = ?", [visit.guid])
        } else if let site = item as? Site {
            return ("DELETE FROM \(TableNameVisits) WHERE siteGuid = ?", [site.guid])
        } else if item != nil {
            return (nil, [String]())
        }
        return ("DELETE FROM \(TableNameVisits)", [AnyObject]())
    }

    override var factory: ((row: SDRow) -> Visit)? {
        return { row -> Visit in
            let site = Site(url: "", title: "")
            site.guid = row["siteGuid"] as? String

            let dt = row["date"] as NSTimeInterval
            let date = NSDate(timeIntervalSince1970: dt)
            let v = Visit(site: site, date: date)
            v.guid = row["guid"] as String
            return v
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String?, [AnyObject?]) {
        if let filter = options?.filter {
            let args : [AnyObject?] = [filter]
            return ("SELECT guid, siteGuid, date FROM \(TableNameVisits) WHERE siteGuid = ?", args)
        }
        return ("SELECT guid, siteGuid, date FROM \(TableNameVisits)", [AnyObject?]())
    }
}
