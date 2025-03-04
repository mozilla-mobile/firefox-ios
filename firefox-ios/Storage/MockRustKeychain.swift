// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

class MockRustKeychain: RustKeychain {
    static let shared = MockRustKeychain()

    private var storage: [String: String] = [:]

    private init() {
        super.init(serviceName: "Test")
    }

    override func getBaseKeychainQuery(key: String) -> [String: Any] {
        return [:]
    }

    override func queryKeychainForKey(key: String) -> Result<String?, Error> {
        return .success(storage[key])
    }

    override func addOrUpdateKeychainKey(_ value: String, key: String) -> OSStatus {
        storage[key] = value
        return errSecSuccess
    }
}
