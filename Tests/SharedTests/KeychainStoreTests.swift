// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared
import XCTest

class KeychainStoreTests: XCTestCase {
    private var keychainStore: KeychainStore!

    override func setUp() {
        super.setUp()
        keychainStore = KeychainStore(keychainWrapper: FakeKeychainWrapper(serviceName: "fakeServiceName"))
    }

    override func tearDown() {
        super.tearDown()
        keychainStore = nil
    }

    func testDictionary() throws {
        let fakeKey = "fakeKey"
        var fakeKeychainDict: [String: Any] = [
            "stringValue": "stringKey",
            "intValue": 123,
            "boolValue": true
        ]

        keychainStore.setDictionary(fakeKeychainDict, forKey: fakeKey)
        var keychainDict = try XCTUnwrap(keychainStore.dictionary(forKey: fakeKey))
        XCTAssertEqual(keychainDict.count, 3)

        fakeKeychainDict["anotherStringValue"] = "anotherStringKey"
        keychainStore.setDictionary(fakeKeychainDict, forKey: fakeKey)
        keychainDict = try XCTUnwrap(keychainStore.dictionary(forKey: fakeKey))
        XCTAssertEqual(keychainDict.count, 4)
    }

    func testString() throws {
        let fakeKey = "fakeKey"
        let fakeValue = "fakeValue"

        keychainStore.setString(fakeValue, forKey: fakeKey)
        let keychainString = try XCTUnwrap(keychainStore.string(forKey: fakeKey))
        XCTAssertEqual(keychainString, fakeValue)
    }
}
