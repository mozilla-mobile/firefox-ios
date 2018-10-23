/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Firefox_Focus

class StringExtensionTest: XCTestCase {
    
    
    func testStringShouldBeTruncated() {
        let originalString = "This is a long title string"
        
        let headTruncatedString = originalString.truncated(limit: 15, position: .head, leader: "..")
        XCTAssertEqual(headTruncatedString.count, 15)
        XCTAssertEqual(headTruncatedString, ".. title string")
        
        let middleTruncatedString = originalString.truncated(limit: 15, position: .middle, leader: "..")
        XCTAssertEqual(middleTruncatedString.count, 15)
        XCTAssertEqual(middleTruncatedString, "This i.. string")
        
        let tailTruncatedString = originalString.truncated(limit: 15, position: .tail, leader: "..")
        XCTAssertEqual(tailTruncatedString.count, 15)
        XCTAssertEqual(tailTruncatedString, "This is a lon..")
    }
    
    func testStringShouldStartWithString() {
        let originalString = "This is a long title string"
        let startString = "This is"
        
        let isStarting = originalString.startsWith(other: startString)
        XCTAssertEqual(isStarting, true)
    }
    
    func testStringShouldStartWithEmptyString() {
        let originalString = "This is a long title string"
        let startString = ""
        
        let isStarting = originalString.startsWith(other: startString)
        XCTAssertEqual(isStarting, true)
    }
    
    func testStringShouldNotStartWithString() {
        let originalString = "This is a long title string"
        let startString = "TX"
        
        let isStarting = originalString.startsWith(other: startString)
        XCTAssertEqual(isStarting, false)
    }
    
}
