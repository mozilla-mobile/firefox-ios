/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// These are taken from the Places docs
// http://mxr.mozilla.org/mozilla-central/source/toolkit/components/places/nsINavHistoryService.idl#1187
public enum VisitType : Int {
    case Unknown = 0
    case Link = 1
    case Typed = 2
    case Bookmark = 3
    case Embed = 4
    case PermanentRedirect = 5
    case TemporaryRedirect = 6
    case Download = 7
    case FramedLink = 8
}

public class Visit {
    var id: Int? = nil
    public let site: Site
    public let date: NSDate
    public let type: VisitType

    public init(site: Site, date: NSDate, type: VisitType = .Unknown) {
        self.site = site
        self.date = date
        self.type = type
    }
}
