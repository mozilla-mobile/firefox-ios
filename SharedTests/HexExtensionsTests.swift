/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class HexExtensionsTests: XCTestCase {
    func testHexEncodedString() {
        XCTAssertEqual("Hello, world!".dataUsingEncoding(NSUTF8StringEncoding)!.hexEncodedString, "48656c6c6f2c20776f726c6421")
        XCTAssertEqual("Hello, world!!".dataUsingEncoding(NSUTF8StringEncoding)!.hexEncodedString, "48656c6c6f2c20776f726c642121")
    }

    func testHexDecodedData() {
        XCTAssertEqual("48656c6c6f2c20776f726c6421".hexDecodedData, "Hello, world!".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertEqual("48656c6c6f2c20776f726c642121".hexDecodedData, "Hello, world!!".dataUsingEncoding(NSUTF8StringEncoding))
    }

    func testHexDecodedDataWithInvalidInput() {
        XCTAssertEqual("".hexDecodedData, NSData())
        XCTAssertEqual("cheese".hexDecodedData, NSData())
        XCTAssertEqual("a".hexDecodedData, NSData())
    }
}
