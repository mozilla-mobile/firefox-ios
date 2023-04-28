// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

public class KeychainStore {
    public static let shared = KeychainStore()

    private let keychainWrapper: MZKeychainWrapper

    public init(keychainWrapper: MZKeychainWrapper = MZKeychainWrapper.sharedClientAppContainerKeychain) {
        self.keychainWrapper = keychainWrapper
    }

    public func setDictionary(_ value: [String: Any]?, forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility = .afterFirstUnlock) {
        setString(value?.asString, forKey: key, withAccessibility: accessibility)
    }

    public func setString(_ value: String?, forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility = .afterFirstUnlock) {
        guard let value = value else {
            keychainWrapper.removeObject(forKey: key, withAccessibility: accessibility)
            return
        }

        keychainWrapper.set(value, forKey: key, withAccessibility: accessibility)
    }

    public func dictionary(forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility = .afterFirstUnlock) -> [String: Any]? {
        guard let stringValue = string(forKey: key, withAccessibility: accessibility),
              let data = stringValue.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
        else { return nil }

        return json
    }

    public func string(forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility = .afterFirstUnlock) -> String? {
        keychainWrapper.ensureStringItemAccessibility(accessibility, forKey: key)

        return keychainWrapper.string(forKey: key, withAccessibility: accessibility)
    }
}
