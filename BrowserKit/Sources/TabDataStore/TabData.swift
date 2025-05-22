// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A dictionary with as Key the local file directory for a temporary document and its online source URL as value
public typealias TemporaryDocumentSession = [URL: URL]

public struct TabData: Codable {
    public let id: UUID
    public let title: String?
    public let siteUrl: String
    public let faviconURL: String?
    public let isPrivate: Bool
    public let lastUsedTime: Date
    public let createdAtTime: Date
    public let temporaryDocumentSession: TemporaryDocumentSession?

    public init(id: UUID,
                title: String?,
                siteUrl: String,
                faviconURL: String?,
                isPrivate: Bool,
                lastUsedTime: Date,
                createdAtTime: Date,
                temporaryDocumentSession: TemporaryDocumentSession) {
        self.id = id
        self.title = title
        self.siteUrl = siteUrl
        self.faviconURL = faviconURL
        self.isPrivate = isPrivate
        self.lastUsedTime = lastUsedTime
        self.createdAtTime = createdAtTime
        self.temporaryDocumentSession = temporaryDocumentSession
    }
}
