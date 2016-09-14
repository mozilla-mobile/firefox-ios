/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// These are taken from the Places docs
// http://mxr.mozilla.org/mozilla-central/source/toolkit/components/places/nsINavHistoryService.idl#1187
@objc public enum VisitType: Int {
    case Unknown = 0

    /**
     * This transition type means the user followed a link and got a new toplevel
     * window.
     */
    case Link = 1

    /**
     * This transition type means that the user typed the page's URL in the
     * URL bar or selected it from URL bar autocomplete results, clicked on
     * it from a history query (from the History sidebar, History menu,
     * or history query in the personal toolbar or Places organizer).
     */
    case Typed = 2

    case Bookmark = 3
    case Embed = 4
    case PermanentRedirect = 5
    case TemporaryRedirect = 6
    case Download = 7
    case FramedLink = 8
}

// WKWebView has these:
/*
WKNavigationTypeLinkActivated,
WKNavigationTypeFormSubmitted,
WKNavigationTypeBackForward,
WKNavigationTypeReload,
WKNavigationTypeFormResubmitted,
WKNavigationTypeOther = -1,
*/

/**
 * SiteVisit is a sop to the existing API, which expects to be able to go
 * backwards from a visit to a site, and preserve the ID of the database row.
 * Visit is the model of what lives on the wire: just a date and a type.
 * Ultimately we'll end up with something similar to ClientAndTabs: the tabs
 * don't need to know about the client, and visits don't need to know about
 * the site, because they're bound together.
 *
 * (Furthermore, we probably shouldn't ever need something like SiteVisit
 * to reach the UI: we care about "last visited", "visit count", or just
 * "places ordered by frecency" — we don't care about lists of visits.)
 */
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
               date = json["date"].asInt64 where date >= 0 {
                return Visit(date: MicrosecondTimestamp(date), type: typeEnum)
        }
        return nil
    }

    public func toJSON() -> JSON {
        let d = NSNumber(unsignedLongLong: self.date)
        let o: [String: AnyObject] = ["type": self.type.rawValue, "date": d]
        return JSON(o)
    }
}

public func ==(lhs: Visit, rhs: Visit) -> Bool {
    return lhs.date == rhs.date &&
           lhs.type == rhs.type
}

public class SiteVisit: Visit {
    var id: Int? = nil
    public let site: Site

    public override var hashValue: Int {
        return date.hashValue ^ type.hashValue ^ (id?.hashValue ?? 0) ^ (site.id ?? 0)
    }

    public init(site: Site, date: MicrosecondTimestamp, type: VisitType = .Unknown) {
        self.site = site
        super.init(date: date, type: type)
    }
}

public func ==(lhs: SiteVisit, rhs: SiteVisit) -> Bool {
    if let lhsID = lhs.id, rhsID = rhs.id {
        if lhsID != rhsID {
            return false
        }
    } else {
        if lhs.id != nil || rhs.id != nil {
            return false
        }
    }

    // TODO: compare Site.
    return lhs.date == rhs.date &&
           lhs.type == rhs.type
}