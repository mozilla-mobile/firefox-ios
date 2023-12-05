// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class DictionaryExtensionsTests: XCTestCase {
    // MARK: - asString

    func test_asString_emptyDictionary_returnsEmptyString() {
        let dictionaryResult = [String: String]().asString
        XCTAssertNotNil(dictionaryResult)
        XCTAssertEqual(dictionaryResult, "{\n\n}")
    }

    func test_asString_stringDictionary_returnsResultString() {
        let dictionaryResult = ["key1": "value1"].asString
        XCTAssertNotNil(dictionaryResult)
        XCTAssertEqual(dictionaryResult, "{\n  \"key1\" : \"value1\"\n}")
    }

    func test_asString_intDictionary_returnsResultString() {
        let dictionaryResult = ["key1": 1].asString
        XCTAssertNotNil(dictionaryResult)
        XCTAssertEqual(dictionaryResult, "{\n  \"key1\" : 1\n}")
    }
}
