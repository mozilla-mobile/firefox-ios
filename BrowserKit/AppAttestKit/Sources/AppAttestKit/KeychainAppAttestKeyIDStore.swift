// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security

/// Keychain-backed implementation of `AppAttestKeyIDStore`.
///
/// Keychain is appropriate because:
/// - persists across launches.
/// - persists across app updates (but not device wipes, which is not desirable for App Attest keys).
/// - supports device-only access classes.
///
/// The `keyId` is stored as a `kSecClassGenericPassword` item with
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` that means:
/// - Available after the first unlock each boot.
/// - Excluded from backups and device migrations (the key is device-specific).
/// NOTE(FXIOS-14838): This closely resembles how we store encryption keys for autofill,
/// but with stricter accessibility values. We should consolidate under one Keychain helper in the future.
public struct KeychainAppAttestKeyIDStore: AppAttestKeyIDStore {
    private enum Constants {
        static let defaultService = "org.mozilla.browserkit.appattest.keyid"
        static let defaultAccount = "default"

        /// Attribute keys for avoiding typos and `as String` when querying keychain items.
        /// See: https://developer.apple.com/documentation/security/searching-for-keychain-items
        static let itemClass = kSecClass as String
        static let service = kSecAttrService as String
        static let account = kSecAttrAccount as String
        static let returnData = kSecReturnData as String
        static let matchLimit = kSecMatchLimit as String
        static let valueData = kSecValueData as String
        static let accessible = kSecAttrAccessible as String

        /// We store the `keyId` as a generic password. 
        /// This is the simplest simplest Keychain class for arbitrary secret strings.
        /// See: https://developer.apple.com/documentation/security/ksecclassgenericpassword
        static let genericPassword = kSecClassGenericPassword as String
        /// Tells `SecItemCopyMatching` to return the stored bytes (`Data`),
        /// not just a success/failure or metadata like creation date.
        /// See: https://developer.apple.com/documentation/security/ksecreturnattributes
        static let returnTrue = true
        /// Return at most one matching item. Without this, Keychain may
        /// return an array via `kSecMatchLimitAll`.
        /// See: https://developer.apple.com/documentation/security/ksecmatchlimit
        static let limitOne = kSecMatchLimitOne as String
        /// Tells keychain to make this value available after first unlock per boot; excluded from backups
        /// and device migrations. This is appropriate since the `keyId` is tied to this device's generated secret keypair.
        /// See: https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility
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

    /// Reads the stored `keyId` from the Keychain, or returns `nil` if absent.
    /// Uses `SecItemCopyMatching` to look up a a keychain item keyed by service and  account.
    /// See: https://developer.apple.com/documentation/security/searching-for-keychain-items
    public func loadKeyID() -> String? {
        // The service + account pair acts as a unique address for the item.
        let query: [String: Any] = [
            Constants.itemClass: Constants.genericPassword,
            Constants.service: service,
            Constants.account: account,
            Constants.returnData: Constants.returnTrue,
            Constants.matchLimit: Constants.limitOne
        ]

        // SecItemCopyMatching writes the result into `item` and returns an OSStatus.
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        // Bail if the item wasn't found, the data is missing, or it's not valid UTF-8.
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    public func saveKeyID(_ keyID: String) throws {
        let data = Data(keyID.utf8)

        let query: [String: Any] = [
            Constants.itemClass: Constants.genericPassword,
            Constants.service: service,
            Constants.account: account
        ]

        let attributes: [String: Any] = [
            Constants.valueData: data,
            Constants.accessible: Constants.accessibleAfterFirstUnlock
        ]

        // Update if the item already exists, otherwise insert.
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

    /// Deletes the stored `keyId` from the Keychain.
    /// This method treats `errSecItemNotFound` as success meaning that clearing an already-absent key is a no-op.
    /// See: https://developer.apple.com/documentation/security/1395547-secitemdelete
    public func clearKeyID() throws {
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
