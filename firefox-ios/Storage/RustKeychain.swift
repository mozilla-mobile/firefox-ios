// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

open class RustKeychain {
    public private(set) var serviceName: String
    public private(set) var accessGroup: String?

    static var sharedClientAppContainerKeychain: RustKeychain {
        let baseBundleIdentifier = AppInfo.baseBundleIdentifier

        guard let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as? String else {
            return RustKeychain(serviceName: baseBundleIdentifier)
        }
        return RustKeychain(serviceName: baseBundleIdentifier,
                            accessGroup: AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix))
    }

    public init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }

    struct KeychainError: Error {
        let errorMessage: String
    }

    func getBaseKeychainQuery(key: String) -> [String: Any] {
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)
        var keychainQueryDictionary: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                       kSecAttrService as String: self.serviceName,
                                                       kSecAttrSynchronizable as String: false]
        keychainQueryDictionary[kSecAttrGeneric as String] = encodedIdentifier
        keychainQueryDictionary[kSecAttrAccount as String] = encodedIdentifier

        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[kSecAttrAccessGroup as String] = accessGroup
        }
        return keychainQueryDictionary
    }

    func queryKeychainForKey(key: String) -> Result<String?, Error> {
        var keychainQueryDictionary = getBaseKeychainQuery(key: key)
        keychainQueryDictionary[kSecMatchLimit as String] = kSecMatchLimitOne
        keychainQueryDictionary[kSecReturnData as String] = kCFBooleanTrue

        var queryResult: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &queryResult)

        guard status == noErr else {
            let errMsg = SecCopyErrorMessageString(status, nil)
            return .failure(KeychainError(errorMessage: errMsg as? String ?? ""))
        }

        guard let data = queryResult as? Data else {
            return .failure(KeychainError(errorMessage: "Unable to encode query result"))
        }

        return .success(String(data: data, encoding: .utf8))
    }

    func addOrUpdateKeychainKey(_ value: String, key: String) -> OSStatus {
        var addQueryDictionary = getBaseKeychainQuery(key: key)
        addQueryDictionary[kSecValueData as String] = value.data(using: String.Encoding.utf8)
        addQueryDictionary[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let addStatus = SecItemAdd(addQueryDictionary as CFDictionary, nil)

        if addStatus == errSecDuplicateItem {
            return SecItemUpdate(getBaseKeychainQuery(key: key) as CFDictionary,
                                 [kSecValueData: value.data(using: String.Encoding.utf8)] as CFDictionary)
        } else {
            return addStatus
        }
    }
}
