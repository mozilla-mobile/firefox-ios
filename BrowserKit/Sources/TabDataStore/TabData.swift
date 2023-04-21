// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct TabData: Codable {
    public let id: UUID
    public let title: String?
    public let siteUrl: String
    public let faviconURL: String?
    public let isPrivate: Bool
    public let lastUsedTime: Date
    public let createdAtTime: Date
    public var tabGroupData: TabGroupData?

    public init(id: UUID,
                title: String?,
                siteUrl: String,
                faviconURL: String?,
                isPrivate: Bool,
                lastUsedTime: Date,
                createdAtTime: Date,
                tabGroupData: TabGroupData? = nil) {
        self.id = id
        self.title = title
        self.siteUrl = siteUrl
        self.faviconURL = faviconURL
        self.isPrivate = isPrivate
        self.lastUsedTime = lastUsedTime
        self.createdAtTime = createdAtTime
        self.tabGroupData = tabGroupData
    }
}
