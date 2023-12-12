// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum FakespotAdsEvent: String {
    case trustedDealsPlacement = "trusted_deals_placement"
    case trustedDealsLinkClicked = "trusted_deals_link_clicked"
    case trustedDealsImpression = "trusted_deals_impression"

    static let eventSource = "firefox_ios"
}
