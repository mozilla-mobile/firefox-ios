/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public class Visit {
    var guid: String
    let site: Site
    let date: NSDate
    // TODO: Store other info about the visit. i.e. Previous visit, reason for visit
    //       (clicking link, typing url, search), device, etc.

    init(site: Site, date: NSDate) {
        self.guid = NSUUID().UUIDString
        self.site = site
        self.date = date
    }
}
