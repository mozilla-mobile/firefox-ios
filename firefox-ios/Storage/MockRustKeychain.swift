// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

class MockRustKeychain: RustKeychain {
    static let shared = MockRustKeychain()

    private var storage: [Data: Data] = [:]

    private init() {
        super.init(serviceName: "Test")
    }

    override func getBaseKeychainQuery(key: Data) -> [String: Any?] {
        return [:]
    }

    override func queryKeychainForKey(key: Data) -> Result<Data?, Error> {
        return .success(storage[key])
    }

    override func updateKeychainKey(_ data: Data, key: Data) -> OSStatus {
        storage[key] = data
        return errSecSuccess
    }

    override func setKeychainKey(_ data: Data, key: Data) -> OSStatus {
        storage[key] = data
        return errSecSuccess
    }
}
