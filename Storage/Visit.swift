/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

// These are taken from the Places docs
// http://mxr.mozilla.org/mozilla-central/source/toolkit/components/places/nsINavHistoryService.idl#1187
@objc public enum VisitType: Int {
    case unknown = 0

    /**
     * This transition type means the user followed a link and got a new toplevel
     * window.
     */
    case link = 1

    /**
     * This transition type means that the user typed the page's URL in the
     * URL bar or selected it from URL bar autocomplete results, clicked on
     * it from a history query (from the History sidebar, History menu,
     * or history query in the personal toolbar or Places organizer).
     */
    case typed = 2

    case bookmark = 3
    case embed = 4
    case permanentRedirect = 5
    case temporaryRedirect = 6
    case download = 7
    case framedLink = 8
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

open class Visit: Hashable {
    open let date: MicrosecondTimestamp
    open let type: VisitType

    open var hashValue: Int {
        return date.hashValue ^ type.hashValue
    }

    public init(date: MicrosecondTimestamp, type: VisitType = .unknown) {
        self.date = date
        self.type = type
    }

    open class func fromJSON(_ json: [String: Any]) -> Visit? {
        if let type = json["type"] as? Int,
            let typeEnum = VisitType(rawValue: type),
            let date = json["date"] as? Int64, date >= 0 {
                return Visit(date: MicrosecondTimestamp(date), type: typeEnum)
        }
        return nil
    }

    open func toJSON() -> [String: Any] {
        let d = NSNumber(value: self.date)
        let o: [String: Any] = ["type": self.type.rawValue, "date": d]
        return o
    }
}

public func ==(lhs: Visit, rhs: Visit) -> Bool {
    return lhs.date == rhs.date &&
           lhs.type == rhs.type
}

open class SiteVisit: Visit {
    var id: Int?
    open let site: Site

    open override var hashValue: Int {
        return date.hashValue ^ type.hashValue ^ (id?.hashValue ?? 0) ^ (site.id ?? 0)
    }

    public init(site: Site, date: MicrosecondTimestamp, type: VisitType = .unknown) {
        self.site = site
        super.init(date: date, type: type)
    }
}

public func ==(lhs: SiteVisit, rhs: SiteVisit) -> Bool {
    if let lhsID = lhs.id, let rhsID = rhs.id {
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
