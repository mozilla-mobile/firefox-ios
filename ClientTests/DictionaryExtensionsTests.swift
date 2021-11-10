// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import Client

class DictionaryExtensionsTests: XCTestCase {

    // MARK: merge:withDictionary

    func test_mergeTwoEmptyDict_returnEmptyDict() {
        var dictionary: [String: String] = [:]
        dictionary.merge(with: [:])
        XCTAssertEqual(dictionary, [:])
    }

    func test_mergeTwoDict_withoutOverlappingValues() {
        var dictionary = [1: 1, 2: 2, 3: 3]
        dictionary.merge(with: [4: 4, 5: 5, 6: 6])
        XCTAssertEqual(dictionary, [1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6])
    }

    func test_mergeTwoDict_withOverlappingValues() {
        var dictionary = [1: 1, 2: 2, 3: 3]
        dictionary.merge(with: [4: 4, 5: 5, 6: 6, 1: 10, 2: 20, 3: 30])
        XCTAssertEqual(dictionary, [1: 10, 2: 20, 3: 30, 4: 4, 5: 5, 6: 6])
    }

    // MARK: - asString

    func test_asString_emptyDictionary_returnsEmptyString() {
        let dictionaryResult = [:].asString
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
