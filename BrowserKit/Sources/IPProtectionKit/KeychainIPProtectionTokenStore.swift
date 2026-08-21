// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
import Security

/// Keychain-backed implementation of `IPProtectionTokenStore`.
public struct KeychainIPProtectionTokenStore: IPProtectionTokenStore {
    private enum Constants {
        static let defaultService = "org.mozilla.browserkit.ipprotection.dsj"
        static let defaultAccount = "default"

        static let itemClass = kSecClass as String
        static let service = kSecAttrService as String
        static let account = kSecAttrAccount as String
        static let returnData = kSecReturnData as String
        static let matchLimit = kSecMatchLimit as String
        static let valueData = kSecValueData as String
        static let accessible = kSecAttrAccessible as String

        static let genericPassword = kSecClassGenericPassword as String
        static let returnTrue = true
        static let limitOne = kSecMatchLimitOne as String
        static let accessibleAfterFirstUnlock = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
    }

    private let service: String
    private let account: String

    public init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    public init() {
        self.init(service: Constants.defaultService, account: Constants.defaultAccount)
    }

    public func load() -> IPProtectionDeviceSession? {
        let query: [String: Any] = [
            Constants.itemClass: Constants.genericPassword,
            Constants.service: service,
            Constants.account: account,
            Constants.returnData: Constants.returnTrue,
            Constants.matchLimit: Constants.limitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let session = try? JSONDecoder().decode(IPProtectionDeviceSession.self, from: data) else {
            return nil
        }
        return session
    }

    public func save(_ session: IPProtectionDeviceSession) throws {
        let data = try JSONEncoder().encode(session)

        let query: [String: Any] = [
            Constants.itemClass: Constants.genericPassword,
            Constants.service: service,
            Constants.account: account
        ]

        let attributes: [String: Any] = [
            Constants.valueData: data,
            Constants.accessible: Constants.accessibleAfterFirstUnlock
        ]

        let status: OSStatus
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            var addQuery = query
            attributes.forEach { addQuery[$0.key] = $0.value }
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw AppAttestServiceError.keychain(description: status.description)
        }
    }

    public func clear() throws {
        let query: [String: Any] = [
            Constants.itemClass: Constants.genericPassword,
            Constants.service: service,
            Constants.account: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppAttestServiceError.keychain(description: status.description)
        }
    }
}
