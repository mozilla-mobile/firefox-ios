/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

enum HistoryOptions {
}

/* The base history protocol */
protocol History {
    init(profile: Profile)

    func clear(filter: String?, options: HistoryOptions?, complete: (success: Bool) -> Void)
    func get(filter: String?, options: HistoryOptions?, complete: (data: Cursor) -> Void)
    func addVisit(site: Site, options: HistoryOptions?, complete: (success: Bool) -> Void)
}
