/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

open class FxAKeychain {
    public private(set) var serviceName: String
    public private(set) var accessGroup: String?

    static var baseBundleIdentifier: String {
        let bundle = Bundle.main
        let packageType = bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as? String
        let baseBundleIdentifier = bundle.bundleIdentifier!
        if packageType == "XPC!" {
            let components = baseBundleIdentifier.components(separatedBy: ".")
            return components[0 ..< components.count - 1].joined(separator: ".")
        }
        return baseBundleIdentifier
    }

    static var shared: FxAKeychain?

    static func sharedAppContainerKeychainForFxA(keychainAccessGroup: String?) -> FxAKeychain {
        if let s = shared {
            return s
        }
        let wrapper = FxAKeychain(serviceName: baseBundleIdentifier, accessGroup: keychainAccessGroup)
        shared = wrapper
        return wrapper
    }

    public init(serviceName: String,
                accessGroup: String? = nil)
    {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }

    struct KeychainError: Error {
        let errorMessage: String
    }

    func ensureStringItemAccessibility(
        _ accessibility: FxAKeychainItemAccessibility,
        forKey key: String
    ) {
        if hasValue(key: key) {
            if accessibilityOfKey(key) != accessibility {
                FxALog.info("ensureStringItemAccessibility: updating item \(key) with \(accessibility)")

                guard let value = getKeyValue(key: key) else {
                    FxALog.error("ensureStringItemAccessibility: failed to get item \(key)")
                    return
                }

                if !removeObject(key: key) {
                    FxALog.error("ensureStringItemAccessibility: failed to remove item \(key)")
                }

                if !setKeyValue(value, key: key, accessibility: accessibility) {
                    FxALog.error("ensureStringItemAccessibility: failed to update item \(key)")
                }
            }
        }
    }

    open func accessibilityOfKey(_ key: String) -> FxAKeychainItemAccessibility? {
        var keychainQueryDictionary = getBaseKeychainQuery(key: key)

        // Remove accessibility attribute
        keychainQueryDictionary.removeValue(forKey: kSecAttrAccessible as String)
        // Limit search results to one
        keychainQueryDictionary[kSecMatchLimit as String] = kSecMatchLimitOne

        // Specify we want SecAttrAccessible returned
        keychainQueryDictionary[kSecReturnAttributes as String] = kCFBooleanTrue

        // Search
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &result)

        guard status == noErr,
              let resultsDictionary = result as? [String: AnyObject],
              let accessibilityAttrValue = resultsDictionary[kSecAttrAccessible as String] as? String
        else {
            return nil
        }

        return FxAKeychainItemAccessibility(rawValue: accessibilityAttrValue)
    }

    func setKeyValue(_ value: String, key: String, accessibility: FxAKeychainItemAccessibility? = nil) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }

        var addQueryDictionary = getBaseKeychainQuery(key: key, accessibility: accessibility)

        addQueryDictionary[kSecValueData as String] = data

        if let accessibility = accessibility {
            addQueryDictionary[kSecAttrAccessible as String] = accessibility.secItemValue()
        } else {
            addQueryDictionary[kSecAttrAccessible as String] = FxAKeychainItemAccessibility.whenUnlocked.secItemValue()
        }

        let addStatus = SecItemAdd(addQueryDictionary as CFDictionary, nil)

        if addStatus == errSecSuccess {
            return true
        } else if addStatus == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(getBaseKeychainQuery(key: key) as CFDictionary,
                                             [kSecValueData: data] as CFDictionary)
            return updateStatus == errSecSuccess
        } else {
            return false
        }
    }

    func getKeyValue(key: String, accessibility: FxAKeychainItemAccessibility? = nil) -> String? {
        return getDataFromResult(queryKeychainForKey(key: key, accessibility: accessibility))
    }

    func queryKeychainForKey(key: String,
                             accessibility: FxAKeychainItemAccessibility? = nil) -> Result<String?, Error>
    {
        var keychainQueryDictionary = getBaseKeychainQuery(key: key, accessibility: accessibility)
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

    func removeObject(key: String, accessibility: FxAKeychainItemAccessibility? = nil) -> Bool {
        let keychainQueryDictionary: [String: Any] = getBaseKeychainQuery(key: key, accessibility: accessibility)
        let status = SecItemDelete(keychainQueryDictionary as CFDictionary)
        return status == errSecSuccess
    }

    func hasValue(key: String) -> Bool {
        return getDataFromResult(queryKeychainForKey(key: key)) != nil
    }

    private func getDataFromResult(_ result: Result<String?, Error>) -> String? {
        switch result {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }

    private func getBaseKeychainQuery(key: String,
                                      accessibility: FxAKeychainItemAccessibility? = nil) -> [String: Any]
    {
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)
        var keychainQueryDictionary: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                      kSecAttrService as String: serviceName,
                                                      kSecAttrSynchronizable as String: false]
        keychainQueryDictionary[kSecAttrGeneric as String] = encodedIdentifier
        keychainQueryDictionary[kSecAttrAccount as String] = encodedIdentifier

        if let accessibility = accessibility {
            keychainQueryDictionary[kSecAttrAccessible as String] = accessibility.secItemValue()
        }

        if let accessGroup = accessGroup {
            keychainQueryDictionary[kSecAttrAccessGroup as String] = accessGroup
        }
        return keychainQueryDictionary
    }
}
