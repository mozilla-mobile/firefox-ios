// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum SiteType: Equatable, Codable, Hashable {
    case basic
    case suggestedSite(SuggestedSiteInfo)
    case sponsoredSite(SponsoredSiteInfo)
    case pinnedSite(PinnedSiteInfo)

    // MARK: - Helpers

    public var isPinnedSite: Bool {
        switch self {
        case .pinnedSite:
            return true
        default:
            return false
        }
    }

    public var isSponsoredSite: Bool {
        switch self {
        case .sponsoredSite:
            return true
        default:
            return false
        }
    }

    public var isSuggestedSite: Bool {
        switch self {
        case .suggestedSite:
            return true
        default:
            return false
        }
    }
}
