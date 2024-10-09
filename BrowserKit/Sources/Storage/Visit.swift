// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

import enum MozillaAppServices.VisitType

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
    public let date: MicrosecondTimestamp
    public let type: VisitType

    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(type)
    }

    public init(date: MicrosecondTimestamp, type: VisitType = .link) {
        self.date = date
        self.type = type
    }
}

public func == (lhs: Visit, rhs: Visit) -> Bool {
    return lhs.date == rhs.date &&
           lhs.type == rhs.type
}

open class SiteVisit: Visit {
    var id: Int?
    public let site: Site

    override public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(type)
        hasher.combine(id)
        hasher.combine(site.id)
    }

    public init(site: Site, date: MicrosecondTimestamp, type: VisitType = .link) {
        self.site = site
        super.init(date: date, type: type)
    }
}

public func == (lhs: SiteVisit, rhs: SiteVisit) -> Bool {
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
