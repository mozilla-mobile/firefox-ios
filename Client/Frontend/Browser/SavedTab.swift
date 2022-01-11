// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import WebKit
import Shared
import MozillaAppServices

class SavedTab: NSObject, NSCoding, NSSecureCoding {

    static var supportsSecureCoding: Bool = true

    var isSelected: Bool
    var title: String?
    var url: URL?
    var isPrivate: Bool
    var sessionData: SessionData?
    var screenshotUUID: UUID?
    var faviconURL: String?
    var UUID: String?
    var tabGroupData: TabGroupData?
    var createdAt: Timestamp?
    var hasHomeScreenshot: Bool

    private enum Keys: String {
        case isSelected
        case title
        case url
        case isPrivate
        case sessionData
        case screenshotUUID
        case faviconURL
        case UUID
        case tabGroupData
        case createdAt
        case hasHomeScreenshot
    }

    var jsonDictionary: [String: AnyObject] {
        let title: String = self.title ?? "null"
        let faviconURL: String = self.faviconURL ?? "null"
        let uuid: String = self.screenshotUUID?.uuidString ?? "null"
        
        var json: [String: AnyObject] = [
            Keys.title.rawValue: title as AnyObject,
            Keys.isPrivate.rawValue: String(self.isPrivate) as AnyObject,
            Keys.isSelected.rawValue: String(self.isSelected) as AnyObject,
            Keys.faviconURL.rawValue: faviconURL as AnyObject,
            Keys.screenshotUUID.rawValue: uuid as AnyObject,
            Keys.url.rawValue: url as AnyObject,
            Keys.UUID.rawValue: self.UUID as AnyObject,
            Keys.tabGroupData.rawValue: self.tabGroupData as AnyObject,
            Keys.createdAt.rawValue: self.createdAt as AnyObject,
            Keys.hasHomeScreenshot.rawValue: String(self.hasHomeScreenshot) as AnyObject,
        ]
        
        if let sessionDataInfo = self.sessionData?.jsonDictionary {
            json[Keys.sessionData.rawValue] = sessionDataInfo as AnyObject?
        }
        
        return json
    }

    init?(screenshotUUID: UUID?, isSelected: Bool, title: String?,
          isPrivate: Bool, faviconURL: String?, url: URL?, sessionData: SessionData?,
          uuid: String, tabGroupData: TabGroupData?, createdAt: Timestamp?, hasHomeScreenshot: Bool) {

        self.screenshotUUID = screenshotUUID
        self.isSelected = isSelected
        self.title = title
        self.isPrivate = isPrivate
        self.faviconURL = faviconURL
        self.url = url
        self.sessionData = sessionData
        self.UUID = uuid
        self.tabGroupData = tabGroupData
        self.createdAt = createdAt
        self.hasHomeScreenshot = hasHomeScreenshot

        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.sessionData = coder.decodeObject(forKey: Keys.sessionData.rawValue) as? SessionData
        self.screenshotUUID = coder.decodeObject(forKey: Keys.screenshotUUID.rawValue) as? UUID
        self.isSelected = coder.decodeBool(forKey: Keys.isSelected.rawValue)
        self.title = coder.decodeObject(forKey: Keys.title.rawValue) as? String
        self.isPrivate = coder.decodeBool(forKey: Keys.isPrivate.rawValue)
        self.faviconURL = coder.decodeObject(forKey: Keys.faviconURL.rawValue) as? String
        self.url = coder.decodeObject(forKey: Keys.url.rawValue) as? URL
        self.UUID = coder.decodeObject(forKey: Keys.UUID.rawValue) as? String
        self.tabGroupData = coder.decodeObject(forKey: Keys.tabGroupData.rawValue) as? TabGroupData
        self.createdAt = coder.decodeObject(forKey: Keys.createdAt.rawValue) as? Timestamp
        self.hasHomeScreenshot = coder.decodeBool(forKey: Keys.hasHomeScreenshot.rawValue)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(sessionData, forKey: Keys.sessionData.rawValue)
        coder.encode(screenshotUUID, forKey: Keys.screenshotUUID.rawValue)
        coder.encode(isSelected, forKey: Keys.isSelected.rawValue)
        coder.encode(title, forKey: Keys.title.rawValue)
        coder.encode(isPrivate, forKey: Keys.isPrivate.rawValue)
        coder.encode(faviconURL, forKey: Keys.faviconURL.rawValue)
        coder.encode(url, forKey: Keys.url.rawValue)
        coder.encode(UUID, forKey: Keys.UUID.rawValue)
        coder.encode(tabGroupData, forKey: Keys.tabGroupData.rawValue)
        coder.encode(createdAt, forKey: Keys.createdAt.rawValue)
        coder.encode(hasHomeScreenshot, forKey: Keys.hasHomeScreenshot.rawValue)
    }
}

public class TabGroupData: NSObject, NSCoding {

    private enum Keys: String {
        case tabAssociatedSearchTerm
        case tabAssociatedSearchUrl
        case tabAssociatedNextUrl
        case tabHistoryCurrentState
        case tabGroupTimerState
    }

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
    
    var jsonDictionary: [String: Any] {
        return [
            Keys.tabAssociatedSearchTerm.rawValue: String(self.tabAssociatedSearchTerm),
            Keys.tabAssociatedSearchUrl.rawValue: String(self.tabAssociatedSearchUrl),
            Keys.tabAssociatedNextUrl.rawValue: String(self.tabAssociatedNextUrl),
            Keys.tabHistoryCurrentState.rawValue: String(self.tabHistoryCurrentState),
            Keys.tabGroupTimerState.rawValue: String(self.tabGroupTimerState),
        ]
    }

    init(searchTerm: String, searchUrl: String, nextReferralUrl: String, tabHistoryCurrentState: String, tabGroupTimerState: String) {
        self.tabAssociatedSearchTerm = searchTerm
        self.tabAssociatedSearchUrl = searchUrl
        self.tabAssociatedNextUrl = nextReferralUrl
        self.tabHistoryCurrentState = tabHistoryCurrentState
        self.tabGroupTimerState = tabGroupTimerState
    }

    required public init?(coder: NSCoder) {
        self.tabAssociatedSearchTerm = coder.decodeObject(forKey: Keys.tabAssociatedSearchTerm.rawValue) as? String ?? ""
        self.tabAssociatedSearchUrl = coder.decodeObject(forKey: Keys.tabAssociatedSearchUrl.rawValue) as? String ?? ""
        self.tabAssociatedNextUrl = coder.decodeObject(forKey: Keys.tabAssociatedNextUrl.rawValue) as? String ?? ""
        self.tabHistoryCurrentState = coder.decodeObject(forKey: Keys.tabHistoryCurrentState.rawValue) as? String ?? ""
        self.tabGroupTimerState = coder.decodeObject(forKey: Keys.tabGroupTimerState.rawValue) as? String ?? ""
    }

    public func encode(with coder: NSCoder) {
        coder.encode(tabAssociatedSearchTerm, forKey: Keys.tabAssociatedSearchTerm.rawValue)
        coder.encode(tabAssociatedSearchUrl, forKey: Keys.tabAssociatedSearchUrl.rawValue)
        coder.encode(tabAssociatedNextUrl, forKey: Keys.tabAssociatedNextUrl.rawValue)
        coder.encode(tabHistoryCurrentState, forKey: Keys.tabHistoryCurrentState.rawValue)
        coder.encode(tabGroupTimerState, forKey: Keys.tabGroupTimerState.rawValue)
    }
}
