// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Action types for authentication state changes
public enum EcosiaAuthActionType: String, CaseIterable {
    case authStateLoaded
    case userLoggedIn
    case userLoggedOut
}

/// Action structure for authentication state changes
public struct AuthStateAction {
    public let type: EcosiaAuthActionType
    public let windowUUID: WindowUUID
    public let isLoggedIn: Bool?
    public let timestamp: Date

    public init(type: EcosiaAuthActionType,
                windowUUID: WindowUUID,
                isLoggedIn: Bool? = nil,
                timestamp: Date = Date()) {
        self.type = type
        self.windowUUID = windowUUID
        self.isLoggedIn = isLoggedIn
        self.timestamp = timestamp
    }
}

/// Window-specific authentication state
public struct AuthWindowState: Equatable {
    public let windowUUID: WindowUUID
    public let isLoggedIn: Bool
    public let authStateLoaded: Bool
    public let lastUpdated: Date

    public init(windowUUID: WindowUUID,
                isLoggedIn: Bool,
                authStateLoaded: Bool,
                lastUpdated: Date = Date()) {
        self.windowUUID = windowUUID
        self.isLoggedIn = isLoggedIn
        self.authStateLoaded = authStateLoaded
        self.lastUpdated = lastUpdated
    }
}
