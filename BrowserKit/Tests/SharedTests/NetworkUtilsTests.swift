// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Shared

class NetworkUtilsTests: XCTestCase {
    func testJsonResponseWithNilData() {
        // 1. Given nil data
        let data: Data? = nil

        // 2. When
        do {
            _ = try jsonResponse(fromData: data)
            XCTFail("Expected JSONSerializeError.noData to be thrown")
        } catch let error as JSONSerializeError {
            // 3. Then
            XCTAssertEqual(error, JSONSerializeError.noData)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testJsonResponseWithEmptyData() {
        // Given empty data
        let data = Data()

        // When
        do {
            _ = try jsonResponse(fromData: data)
            XCTFail("Expected JSONSerializeError.noData to be thrown")
        } catch let error as JSONSerializeError {
            // Then
            XCTAssertEqual(error, JSONSerializeError.noData)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testJsonResponseWithInvalidJson() {
        // Given invalid JSON data
        let invalidJsonData = "invalid json".data(using: .utf8)!

        // When
        do {
            _ = try jsonResponse(fromData: invalidJsonData)
            XCTFail("Expected JSONSerializeError.parseError to be thrown")
        } catch let error as JSONSerializeError {
            // Then
            XCTAssertEqual(error, JSONSerializeError.parseError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testJsonResponseWithValidJson() {
        // Given valid JSON data
        let validJson = "{\"key\":\"value\"}"
        let validJsonData = validJson.data(using: .utf8)!

        // When
        do {
            let json = try jsonResponse(fromData: validJsonData)
            // Then
            XCTAssertNotNil(json)
            XCTAssertEqual(json?["key"] as? String, "value")
        } catch {
            XCTFail("No error should have been thrown, but got \(error)")
        }
    }
}
