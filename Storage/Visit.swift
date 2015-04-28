/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

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

public class Visit: Hashable {
    public let date: MicrosecondTimestamp
    public let type: VisitType

    public var hashValue: Int {
        return date.hashValue ^ type.hashValue
    }

    public init(date: MicrosecondTimestamp, type: VisitType = .Unknown) {
        self.date = date
        self.type = type
    }

    public class func fromJSON(json: JSON) -> Visit? {
        if let type = json["type"].asInt,
               typeEnum = VisitType(rawValue: type),
               date = json["date"].asInt64 {
            return Visit(date: MicrosecondTimestamp(date), type: typeEnum)
        }
        return nil
    }
}

public func ==(lhs: Visit, rhs: Visit) -> Bool {
    return lhs.date == rhs.date &&
           lhs.type == rhs.type
}

public class SiteVisit: Visit {
    var id: Int? = nil
    public let site: Site

    public init(site: Site, date: MicrosecondTimestamp, type: VisitType = .Unknown) {
        self.site = site
        super.init(date: date, type: type)
    }
}
