// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

// We have both Codable and NSCoding protocol conformance since we're currently migrating users to
// Codable for SavedTab. We'll be able to remove NSCoding when adoption rate to v106 and greater is high enough.
class SavedTab: NSObject, Codable, NSCoding {
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

    enum CodingKeys: String, CodingKey {
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
            CodingKeys.title.rawValue: title as AnyObject,
            CodingKeys.isPrivate.rawValue: String(self.isPrivate) as AnyObject,
            CodingKeys.isSelected.rawValue: String(self.isSelected) as AnyObject,
            CodingKeys.faviconURL.rawValue: faviconURL as AnyObject,
            CodingKeys.screenshotUUID.rawValue: uuid as AnyObject,
            CodingKeys.url.rawValue: url as AnyObject,
            CodingKeys.UUID.rawValue: self.UUID as AnyObject,
            CodingKeys.tabGroupData.rawValue: self.tabGroupData as AnyObject,
            CodingKeys.createdAt.rawValue: self.createdAt as AnyObject,
            CodingKeys.hasHomeScreenshot.rawValue: String(self.hasHomeScreenshot) as AnyObject
        ]

        if let sessionDataInfo = self.sessionData?.jsonDictionary {
            json[CodingKeys.sessionData.rawValue] = sessionDataInfo as AnyObject?
        }

        return json
    }

    init?(
        screenshotUUID: UUID?,
        isSelected: Bool,
        title: String?,
        isPrivate: Bool,
        faviconURL: String?,
        url: URL?,
        sessionData: SessionData?,
        uuid: String,
        tabGroupData: TabGroupData?,
        createdAt: Timestamp?,
        hasHomeScreenshot: Bool
    ) {
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
        self.sessionData = coder.decodeObject(forKey: CodingKeys.sessionData.rawValue) as? SessionData
        self.screenshotUUID = coder.decodeObject(forKey: CodingKeys.screenshotUUID.rawValue) as? UUID
        self.isSelected = coder.decodeBool(forKey: CodingKeys.isSelected.rawValue)
        self.title = coder.decodeObject(forKey: CodingKeys.title.rawValue) as? String
        self.isPrivate = coder.decodeBool(forKey: CodingKeys.isPrivate.rawValue)
        self.faviconURL = coder.decodeObject(forKey: CodingKeys.faviconURL.rawValue) as? String
        self.url = coder.decodeObject(forKey: CodingKeys.url.rawValue) as? URL
        self.UUID = coder.decodeObject(forKey: CodingKeys.UUID.rawValue) as? String
        self.tabGroupData = coder.decodeObject(forKey: CodingKeys.tabGroupData.rawValue) as? TabGroupData
        self.createdAt = coder.decodeObject(forKey: CodingKeys.createdAt.rawValue) as? Timestamp
        self.hasHomeScreenshot = coder.decodeBool(forKey: CodingKeys.hasHomeScreenshot.rawValue)
    }

    func encode(with coder: NSCoder) {
        coder.encode(sessionData, forKey: CodingKeys.sessionData.rawValue)
        coder.encode(screenshotUUID, forKey: CodingKeys.screenshotUUID.rawValue)
        coder.encode(isSelected, forKey: CodingKeys.isSelected.rawValue)
        coder.encode(title, forKey: CodingKeys.title.rawValue)
        coder.encode(isPrivate, forKey: CodingKeys.isPrivate.rawValue)
        coder.encode(faviconURL, forKey: CodingKeys.faviconURL.rawValue)
        coder.encode(url, forKey: CodingKeys.url.rawValue)
        coder.encode(UUID, forKey: CodingKeys.UUID.rawValue)
        coder.encode(tabGroupData, forKey: CodingKeys.tabGroupData.rawValue)
        coder.encode(createdAt, forKey: CodingKeys.createdAt.rawValue)
        coder.encode(hasHomeScreenshot, forKey: CodingKeys.hasHomeScreenshot.rawValue)
    }
}
