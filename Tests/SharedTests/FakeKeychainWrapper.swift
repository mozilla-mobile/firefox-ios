// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

public class FakeKeychainWrapper: MZKeychainWrapper {
    private var fakeDictionary: [String: Any] = [:]

    override public func set(_ value: String, forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility? = nil, isSynchronizable: Bool = false) -> Bool {
        fakeDictionary[key] = value
        return true
    }

    override public func removeObject(forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility? = nil, isSynchronizable: Bool = false) -> Bool {
        guard fakeDictionary[key] != nil else { return false }
        fakeDictionary.removeValue(forKey: key)
        return true
    }

    override public func string(forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility? = nil, isSynchronizable: Bool = false) -> String? {
        guard let value = fakeDictionary[key] else { return nil }
        return value as? String
    }
}
