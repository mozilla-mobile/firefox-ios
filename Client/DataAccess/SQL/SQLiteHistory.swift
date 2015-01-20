/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* The sqlite backed implementation of the history protocol */
class SqliteHistory : History {
    let profile: Profile
    let db: BrowserDB

    required init(profile: Profile) {
        self.profile = profile
        self.db = BrowserDB(profile: profile)!
    }

    func clear(filter: String?, options: HistoryOptions?, complete: (success: Bool) -> Void) {
        let s: Site? = nil
        var err: NSError? = nil
        db.delete(TableNameHistory, item: s, err: &err)
        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Clear failed: \(err!.localizedDescription)")
            }
        }
    }

    func get(filter: String?, options: HistoryOptions?, complete: (data: Cursor) -> Void) {
        var res: Cursor!
        if options?.visits == true {
            res = db.query(TableNameVisits, filter: filter)
        } else {
            res = db.query(TableNameHistory, filter: filter)
        }

        dispatch_async(dispatch_get_main_queue()) {
            complete(data: res)
        }
    }

    private func getGuidFor(site: Site) -> String? {
        let cursor = db.query(TableNameHistory, filter: site.url)
        if (cursor.count != 1) {
            return nil
        }
        return (cursor[0] as Site).guid
    }

    func addVisit(visit: Visit, options: HistoryOptions?, complete: (success: Bool) -> Void) {
        var err: NSError? = nil

        // If our site doesn't have a guid, we need to find one
        if visit.site.guid == nil {
            if let guid = getGuidFor(visit.site) {
                visit.site.guid = guid
                db.update(TableNameHistory, item: visit.site, err: &err)
            } else {
                // Make sure we have a site in the table first
                visit.site.guid = NSUUID().UUIDString
                db.insert(TableNameHistory, item: visit.site, err: &err)
            }
        } else {
            db.update(TableNameHistory, item: visit.site, err: &err)
        }

        // Now add a visit
        db.insert(TableNameVisits, item: visit, err: &err)

        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Add failed: \(err!.localizedDescription)")
            }
            complete(success: err == nil)
        }
    }

    private let debug_enabled = true
    private func debug(msg: String) {
        if debug_enabled {
            println("HistorySqlite: " + msg)
        }
    }
}
