// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import struct MozillaAppServices.HistoryMetadataKey

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

// Ecosia: Tabs architecture implementation from ~v112 to ~116
// class LegacyTabGroupData: Codable {
class LegacyTabGroupData: NSObject, Codable, NSCoding {

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

    // Ecosia: Tabs architecture implementation from ~v112 to ~116
    // convenience init() {
    override convenience init() {
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

    // Ecosia: Tabs architecture implementation from ~v112 to ~116
    // This is temprorary in order to fix a migration error, can be removed after our Ecosia 10.0.0 has been well adopted

    var jsonDictionary: [String: Any] {
        return [
            CodingKeys.tabAssociatedSearchTerm.rawValue: String(self.tabAssociatedSearchTerm),
            CodingKeys.tabAssociatedSearchUrl.rawValue: String(self.tabAssociatedSearchUrl),
            CodingKeys.tabAssociatedNextUrl.rawValue: String(self.tabAssociatedNextUrl),
            CodingKeys.tabHistoryCurrentState.rawValue: String(self.tabHistoryCurrentState),
        ]
    }

    public required init?(coder: NSCoder) {
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
