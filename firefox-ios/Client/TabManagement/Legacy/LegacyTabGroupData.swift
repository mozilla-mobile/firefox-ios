// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

enum LegacyTabGroupTimerState: String, Codable {
    case navSearchLoaded
    case tabNavigatedToDifferentUrl
    case tabSwitched
    case tabSelected
    case newTab
    case openInNewTab
    case openURLOnly
    case none
}

class LegacyTabGroupData: Codable {
    var tabAssociatedSearchTerm: String = ""
    var tabAssociatedSearchUrl: String = ""
    var tabAssociatedNextUrl: String = ""
    var tabHistoryCurrentState = ""

    func tabHistoryMetadatakey() -> HistoryMetadataKey {
        return HistoryMetadataKey(
            url: tabAssociatedSearchUrl,
            searchTerm: tabAssociatedSearchTerm,
            referrerUrl: tabAssociatedNextUrl
        )
    }

    enum CodingKeys: String, CodingKey {
        case tabAssociatedSearchTerm
        case tabAssociatedSearchUrl
        case tabAssociatedNextUrl
        case tabHistoryCurrentState
    }

    convenience init() {
        self.init(searchTerm: "",
                  searchUrl: "",
                  nextReferralUrl: "",
                  tabHistoryCurrentState: LegacyTabGroupTimerState.none.rawValue)
    }

    init(searchTerm: String, searchUrl: String, nextReferralUrl: String, tabHistoryCurrentState: String = "") {
        self.tabAssociatedSearchTerm = searchTerm
        self.tabAssociatedSearchUrl = searchUrl
        self.tabAssociatedNextUrl = nextReferralUrl
        self.tabHistoryCurrentState = tabHistoryCurrentState
    }
}
