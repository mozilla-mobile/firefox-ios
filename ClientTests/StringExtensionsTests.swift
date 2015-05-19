/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class StringExtensionsTests: XCTestCase {
    func testContains() {
        XCTAssertTrue("abcde".contains("abcde"))
        XCTAssertTrue("abcde".contains(""))
        XCTAssertTrue("abcde".contains("a"))
        XCTAssertTrue("abcde".contains("e"))
        XCTAssertFalse("abcde".contains("f"))
        XCTAssertFalse("abcde".contains("fa"))
        XCTAssertFalse("abcde".contains("ef"))
    }

    func testStartsWith() {
        XCTAssertTrue("abcde".startsWith("abcde"))
        XCTAssertTrue("abcde".startsWith(""))
        XCTAssertTrue("abcde".startsWith("a"))
        XCTAssertTrue("abcdea".startsWith("a"))
        XCTAssertFalse("abcde".startsWith("fa"))
        XCTAssertFalse("abcde".startsWith("af"))
        XCTAssertFalse("abcde".startsWith("b"))
    }

    func testEndsWith() {
        XCTAssertTrue("abcde".endsWith("abcde"))
        XCTAssertTrue("abcde".endsWith(""))
        XCTAssertTrue("abcde".endsWith("e"))
        XCTAssertTrue("abcdea".endsWith("a"))
        XCTAssertFalse("abcde".endsWith("fe"))
        XCTAssertFalse("abcde".endsWith("ef"))
        XCTAssertFalse("abcde".endsWith("d"))
    }

    func testEncryption() {
        let test = "Test data"
        let secret = ""

        // Random IVs by default mean that encrypting the same string twice won't result in the same data.
        let encrypted1 = test.AES256EncryptWithKey(secret)
        let encrypted2 = test.AES256EncryptWithKey(secret)
        XCTAssertNotNil(encrypted1, "String was encrypted")
        XCTAssertNotNil(encrypted2, "String was encrypted")
        XCTAssertNotEqual(encrypted1!, encrypted2!, "Encrypting the same phrase twice gives different values")

        // Test decryption.
        let decrypted = encrypted1?.AES256DecryptWithKey(secret)
        XCTAssertNotNil(decrypted, "String was decrypted")
        XCTAssertEqual(test, decrypted!, "String was decrypted correctly")

        // Using a forced IV can ensure we always get the same cipher back.
        let ivString = "Initial values"
        let iv = ivString.dataUsingEncoding(NSUTF8StringEncoding)
        let encrypted3 = test.AES256EncryptWithKey(secret, iv: iv)
        let encrypted4 = test.AES256EncryptWithKey(secret, iv: iv)
        XCTAssertNotNil(encrypted3, "String was encrypted")
        XCTAssertNotNil(encrypted4, "String was encrypted")
        XCTAssertEqual(encrypted3!, encrypted4!, "Encrypting the same phrase with an IV always gives the same value.")
    }
}
