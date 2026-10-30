// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security

public protocol KeychainClient: Sendable {
    func load(query: [String: Any]) -> (OSStatus, CFTypeRef?)
    func update(query: [String: Any], attributes: [String: Any]) -> OSStatus
    func add(attributes: [String: Any]) -> OSStatus
    func delete(query: [String: Any]) -> OSStatus
}

public struct DefaultKeychainClient: KeychainClient {
    public init() {}

    public func load(query: [String: Any]) -> (OSStatus, CFTypeRef?) {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return (status, result)
    }

    public func update(query: [String: Any], attributes: [String: Any]) -> OSStatus {
        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }

    public func add(attributes: [String: Any]) -> OSStatus {
        SecItemAdd(attributes as CFDictionary, nil)
    }

    public func delete(query: [String: Any]) -> OSStatus {
        SecItemDelete(query as CFDictionary)
    }
}
