// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class LegacySavedTab: Codable {
    var isSelected: Bool
    var title: String?
    var url: URL?
    var isPrivate: Bool
    var sessionData: LegacySessionData?
    var screenshotUUID: UUID?
    var faviconURL: String?
    var UUID: String?
    var tabGroupData: LegacyTabGroupData?
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

    init(
        screenshotUUID: UUID?,
        isSelected: Bool,
        title: String?,
        isPrivate: Bool,
        faviconURL: String?,
        url: URL?,
        sessionData: LegacySessionData?,
        uuid: String,
        tabGroupData: LegacyTabGroupData?,
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
    }
}
