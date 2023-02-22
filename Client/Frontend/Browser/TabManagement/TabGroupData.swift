// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

enum TabGroupTimerState: String, Codable {
    case navSearchLoaded
    case tabNavigatedToDifferentUrl
    case tabSwitched
    case tabSelected
    case newTab
    case openInNewTab
    case openURLOnly
    case none
}

// We have both Codable and NSCoding protocol conformance since we're currently migrating users to
// Codable for TabGroupData. We'll be able to remove NSCoding when adoption rate to v106 and greater is high enough.
class TabGroupData: NSObject, Codable, NSCoding {
    var tabAssociatedSearchTerm: String = ""
    var tabAssociatedSearchUrl: String = ""
    var tabAssociatedNextUrl: String = ""
    var tabHistoryCurrentState = ""

    func tabHistoryMetadatakey() -> HistoryMetadataKey {
        return HistoryMetadataKey(url: tabAssociatedSearchUrl, searchTerm: tabAssociatedSearchTerm, referrerUrl: tabAssociatedNextUrl)
    }

    enum CodingKeys: String, CodingKey {
        case tabAssociatedSearchTerm
        case tabAssociatedSearchUrl
        case tabAssociatedNextUrl
        case tabHistoryCurrentState
    }

    var jsonDictionary: [String: Any] {
        return [
            CodingKeys.tabAssociatedSearchTerm.rawValue: String(self.tabAssociatedSearchTerm),
            CodingKeys.tabAssociatedSearchUrl.rawValue: String(self.tabAssociatedSearchUrl),
            CodingKeys.tabAssociatedNextUrl.rawValue: String(self.tabAssociatedNextUrl),
            CodingKeys.tabHistoryCurrentState.rawValue: String(self.tabHistoryCurrentState),
        ]
    }

    convenience override init() {
        self.init(searchTerm: "",
                  searchUrl: "",
                  nextReferralUrl: "",
                  tabHistoryCurrentState: TabGroupTimerState.none.rawValue)
    }

    init(searchTerm: String, searchUrl: String, nextReferralUrl: String, tabHistoryCurrentState: String = "") {
        self.tabAssociatedSearchTerm = searchTerm
        self.tabAssociatedSearchUrl = searchUrl
        self.tabAssociatedNextUrl = nextReferralUrl
        self.tabHistoryCurrentState = tabHistoryCurrentState
    }

    required public init?(coder: NSCoder) {
        self.tabAssociatedSearchTerm = coder.decodeObject(forKey: CodingKeys.tabAssociatedSearchTerm.rawValue) as? String ?? ""
        self.tabAssociatedSearchUrl = coder.decodeObject(forKey: CodingKeys.tabAssociatedSearchUrl.rawValue) as? String ?? ""
        self.tabAssociatedNextUrl = coder.decodeObject(forKey: CodingKeys.tabAssociatedNextUrl.rawValue) as? String ?? ""
        self.tabHistoryCurrentState = coder.decodeObject(forKey: CodingKeys.tabHistoryCurrentState.rawValue) as? String ?? ""
    }

    public func encode(with coder: NSCoder) {
        coder.encode(tabAssociatedSearchTerm, forKey: CodingKeys.tabAssociatedSearchTerm.rawValue)
        coder.encode(tabAssociatedSearchUrl, forKey: CodingKeys.tabAssociatedSearchUrl.rawValue)
        coder.encode(tabAssociatedNextUrl, forKey: CodingKeys.tabAssociatedNextUrl.rawValue)
        coder.encode(tabHistoryCurrentState, forKey: CodingKeys.tabHistoryCurrentState.rawValue)
    }
}
