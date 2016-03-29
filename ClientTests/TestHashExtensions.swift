/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class TestHashExtensions: XCTestCase {
    func testSha1() {
        XCTAssertEqual("test1test2".sha1.hexEncodedString, "dff964f6e3c1761b6288f5c75c319d36fb09b2b9")
        XCTAssertEqual("test2test3".sha1.hexEncodedString, "66cdfcbbf4ad73f40ae06140460ff9bb0aabaf5c")
    }

    func testSha256() {
        let data1: NSData = "4f980b6f9baa6965f760d0bf2b2ccbee483032e5df01d77bbd9e25f7517a06b9".hexDecodedData
        XCTAssertEqual("test1test2".sha256, data1)
        XCTAssertEqual("test2test3".sha256, "fc3ea28dc1801e4180cec1022b55bee7795cf3c9fd430fb5237c9d8054218e81".hexDecodedData)
    }
}
