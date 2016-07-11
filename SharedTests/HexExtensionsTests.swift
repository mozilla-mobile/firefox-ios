/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class HexExtensionsTests: XCTestCase {
    func testHexEncodedString() {
        XCTAssertEqual("Hello, world!".data(using: String.Encoding.utf8)!.hexEncodedString, "48656c6c6f2c20776f726c6421")
        XCTAssertEqual("Hello, world!!".data(using: String.Encoding.utf8)!.hexEncodedString, "48656c6c6f2c20776f726c642121")
    }

    func testHexDecodedData() {
        XCTAssertEqual("48656c6c6f2c20776f726c6421".hexDecodedData, "Hello, world!".data(using: String.Encoding.utf8))
        XCTAssertEqual("48656c6c6f2c20776f726c642121".hexDecodedData, "Hello, world!!".data(using: String.Encoding.utf8))
    }

    func testHexDecodedDataWithInvalidInput() {
        XCTAssertEqual("".hexDecodedData, Data())
        XCTAssertEqual("cheese".hexDecodedData, Data())
        XCTAssertEqual("a".hexDecodedData, Data())
    }
}
