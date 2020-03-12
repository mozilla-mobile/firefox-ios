/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class OAuthScope {
    // Necessary to fetch a profile.
    public static let profile: String = "profile"
    // Necessary to obtain sync keys.
    public static let oldSync: String = "https://identity.mozilla.com/apps/oldsync"
    // Necessary to obtain a sessionToken, which gives full access to the account.
    public static let session: String = "https://identity.mozilla.com/tokens/session"
}

public struct ScopedKey {
    public let kty: String
    public let scope: String
    public let k: String
    public let kid: String

    internal init(msg: MsgTypes_ScopedKey) {
        kty = msg.kty
        scope = msg.scope
        k = msg.k
        kid = msg.kid
    }
}

public struct AccessTokenInfo {
    public let scope: String
    public let token: String
    public let key: ScopedKey?
    public let expiresAt: Date

    internal init(msg: MsgTypes_AccessTokenInfo) {
        scope = msg.scope
        token = msg.token
        key = msg.hasKey ? ScopedKey(msg: msg.key) : nil
        expiresAt = Date(timeIntervalSince1970: Double(msg.expiresAt))
    }

    // For testing.
    internal init(
        scope: String,
        token: String,
        key: ScopedKey? = nil,
        expiresAt: Date = Date()
    ) {
        self.scope = scope
        self.token = token
        self.key = key
        self.expiresAt = expiresAt
    }
}

public struct IntrospectInfo {
    public let active: Bool
    public let tokenType: String
    public let scope: String?
    public let exp: Date
    public let iss: String?

    internal init(msg: MsgTypes_IntrospectInfo) {
        active = msg.active
        tokenType = msg.tokenType
        scope = msg.hasScope ? msg.scope : nil
        exp = Date(timeIntervalSince1970: Double(msg.exp))
        iss = msg.hasIss ? msg.iss : nil
    }

    // For testing.
    internal init(
        active: Bool,
        tokenType: String,
        scope: String? = nil,
        exp: Date = Date(),
        iss: String? = nil
    ) {
        self.active = active
        self.tokenType = tokenType
        self.scope = scope
        self.exp = exp
        self.iss = iss
    }
}
