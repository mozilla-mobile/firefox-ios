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

    func getBaseKeychainQuery(key: String) -> [String: Any?] {
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)
        let keychainQueryDictionary: [String: Any?] = [kSecClass as String: kSecClassGenericPassword,
                                                       kSecAttrAccessGroup as String: self.accessGroup,
                                                       kSecAttrService as String: self.serviceName,
                                                       kSecAttrGeneric as String: encodedIdentifier,
                                                       kSecAttrAccount as String: encodedIdentifier,
                                                       kSecAttrSynchronizable as String: false]
        return keychainQueryDictionary
    }

    func queryKeychainForKey(key: String) -> Result<Data?, Error> {
        var keychainQueryDictionary = getBaseKeychainQuery(key: key)
        keychainQueryDictionary[kSecMatchLimit as String] = kSecMatchLimitOne
        keychainQueryDictionary[kSecReturnData as String] = kCFBooleanTrue

        var queryResult: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &queryResult)

        guard status == noErr else {
            let errMsg = SecCopyErrorMessageString(status, nil)
            return .failure(KeychainError(errorMessage: errMsg as? String ?? ""))
        }
        return .success(queryResult as? Data)
    }

    func updateKeychainKey(_ data: Data, key: String) -> OSStatus {
        return SecItemUpdate(getBaseKeychainQuery(key: key) as CFDictionary,
                             [kSecValueData: data] as CFDictionary)
    }

    func setKeychainKey(_ data: Data, key: String) -> OSStatus {
        var keychainQueryDictionary = getBaseKeychainQuery(key: key)
        keychainQueryDictionary[kSecValueData as String] = data
        keychainQueryDictionary[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        return SecItemAdd(keychainQueryDictionary as CFDictionary, nil)
    }
}
