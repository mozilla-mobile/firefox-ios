// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// User profile information retrieved from Auth0
public struct UserProfile: Codable, Equatable {
    /// User's display name (falls back to nickname if name is nil)
    public let name: String?

    /// User's email address
    public let email: String?

    /// URL string for user's profile picture
    private let picture: String?

    /// User's unique identifier from Auth0
    public let sub: String

    public init(name: String?, email: String?, picture: String?, sub: String) {
        self.name = name
        self.email = email
        self.picture = picture
        self.sub = sub
    }

    /// Display name with fallback logic
    public var displayName: String? {
        return name ?? email?.components(separatedBy: "@").first
    }

    /// Profile picture URL
    public var pictureURL: URL? {
        guard let picture else { return nil }
        return URL(string: picture)
    }
}
