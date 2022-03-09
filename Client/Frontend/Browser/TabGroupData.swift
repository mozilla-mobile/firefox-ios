// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

public enum TabGroupTimerState: String, Codable {
    case navSearchLoaded
    case tabNavigatedToDifferentUrl
    case tabSwitched
    case tabSelected
    case newTab
    case openInNewTab
    case none
}

public class TabGroupData: NSObject, NSCoding {
    var tabAssociatedSearchTerm: String = ""
    var tabAssociatedSearchUrl: String = ""
    var tabAssociatedNextUrl: String = ""
    var tabHistoryCurrentState = ""
    var tabGroupTimerState = ""
    
    // Checks if there is any search term data
    func isEmpty() -> Bool {
        return tabAssociatedSearchTerm.isEmpty && tabAssociatedSearchUrl.isEmpty && tabAssociatedNextUrl.isEmpty
    }

    func tabHistoryMetadatakey() -> HistoryMetadataKey {
        return HistoryMetadataKey(url: tabAssociatedSearchUrl, searchTerm: tabAssociatedSearchTerm, referrerUrl: tabAssociatedNextUrl)
    }
    
    convenience override init() {
        self.init(searchTerm: "",
                  searchUrl: "",
                  nextReferralUrl: "",
                  tabHistoryCurrentState: TabGroupTimerState.none.rawValue,
                  tabGroupTimerState: TabGroupTimerState.none.rawValue)
    }

    init(searchTerm: String, searchUrl: String, nextReferralUrl: String, tabHistoryCurrentState: String, tabGroupTimerState: String) {
        self.tabAssociatedSearchTerm = searchTerm
        self.tabAssociatedSearchUrl = searchUrl
        self.tabAssociatedNextUrl = nextReferralUrl
        self.tabHistoryCurrentState = tabHistoryCurrentState
        self.tabGroupTimerState = tabGroupTimerState
    }

    required public init?(coder: NSCoder) {
        self.tabAssociatedSearchTerm = coder.decodeObject(forKey: "tabAssociatedSearchTerm") as? String ?? ""
        self.tabAssociatedSearchUrl = coder.decodeObject(forKey: "tabAssociatedSearchUrl") as? String ?? ""
        self.tabAssociatedNextUrl = coder.decodeObject(forKey: "tabAssociatedNextUrl") as? String ?? ""
        self.tabHistoryCurrentState = coder.decodeObject(forKey: "tabHistoryCurrentState") as? String ?? ""
        self.tabGroupTimerState = coder.decodeObject(forKey: "tabGroupTimerState") as? String ?? ""
    }

    public func encode(with coder: NSCoder) {
        coder.encode(tabAssociatedSearchTerm, forKey: "tabAssociatedSearchTerm")
        coder.encode(tabAssociatedSearchUrl, forKey: "tabAssociatedSearchUrl")
        coder.encode(tabAssociatedNextUrl, forKey: "tabAssociatedNextUrl")
        coder.encode(tabHistoryCurrentState, forKey: "tabHistoryCurrentState")
        coder.encode(tabGroupTimerState, forKey: "tabGroupTimerState")
    }
}
