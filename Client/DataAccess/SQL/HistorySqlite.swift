/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* The sqlite backed implementation of the history protocol */
public class SqliteHistory : History {
    var profile: Profile

    required public init(profile: Profile) {
        self.profile = profile
    }

    public func clear(filter: String?, options: HistoryOptions?, complete: (success: Bool) -> Void) {
        if let wrapper = BrowserDB(profile: profile) {
            let s: Site? = nil
            var err: NSError? = nil
            wrapper.delete(HISTORY_TABLE, item: s, err: &err)
            dispatch_async(dispatch_get_main_queue()) {
                if err != nil {
                    self.debug("Clear failed: \(err!.localizedDescription)")
                }
                complete(success: err == nil)
            }
            return
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.debug("Could not get db")
                complete(success: false)
            }
        }
    }

    public func get(filter: String?, options: HistoryOptions?, complete: (data: Cursor) -> Void) {
        if let wrapper = BrowserDB(profile: profile) {
            let res = wrapper.query(HISTORY_TABLE)
            dispatch_async(dispatch_get_main_queue()) {
                complete(data: res)
            }
            return
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                complete(data: Cursor(status: .Failure, msg: "Could not open database"))
            }
        }
    }

    public func addVisit(site: Site, options: HistoryOptions?, complete: (success: Bool) -> Void) {
        if let wrapper = BrowserDB(profile: profile) {
            var err: NSError? = nil
            wrapper.insert(HISTORY_TABLE, item: site, err: &err)
            // TODO: Track visits in a separate table

            dispatch_async(dispatch_get_main_queue()) {
                if err != nil {
                    self.debug("Add failed: \(err!.localizedDescription)")
                }
                complete(success: err == nil)
            }

            return
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.debug("Could not open database")
                complete(success: false)
            }
        }
    }

    private let debug_enabled = true
    private func debug(msg: String) {
        if debug_enabled {
            println("HistorySqlite: " + msg)
        }
    }
}
