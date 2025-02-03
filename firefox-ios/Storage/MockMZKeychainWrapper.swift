// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import class MozillaAppServices.MZKeychainWrapper
import enum MozillaAppServices.MZKeychainItemAccessibility

class MockMZKeychainWrapper: MZKeychainWrapper {
    static let shared = MockMZKeychainWrapper()

    private var storage: [String: Data] = [:]

    private init() {
        super.init(serviceName: "Test")
    }

    override func set(_ value: Data, forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility? = nil,
                      isSynchronizable: Bool = false) -> Bool {
        storage[key] = value
        return true
    }

    override func string(forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility? = nil,
                         isSynchronizable: Bool = false) -> String? {
        guard let data = storage[key] else { return nil }
        return String(data: data, encoding: .utf8)
    }

    override func data(forKey key: String, withAccessibility accessibility: MZKeychainItemAccessibility? = nil,
                       isSynchronizable: Bool = false) -> Data? {
        return storage[key]
    }
}
