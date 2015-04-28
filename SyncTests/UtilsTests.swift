/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

/**
 * Test for our own utils.
 */
class UtilsTests: XCTestCase {
    func testMapUtils() {
        let m: [String: Int] = ["foo": 123, "bar": 456]
        let f: (Int) -> Int? = { v in
            return (v > 200) ? 999 : nil
        }

        let o = mapValues(m, f)
        XCTAssertEqual(2, o.count)
        XCTAssertTrue(o["foo"]! == nil)
        XCTAssertTrue(o["bar"]! == 999)

        let filtered = optFilter(o)
        XCTAssertEqual(1, filtered.count)
        XCTAssertTrue(filtered["bar"] == 999)
    }

    func testOptFilter() {
        let a: [Int?] = [nil, 1, nil, 2, 3, 4]
        let b = optFilter(a)
        XCTAssertEqual(4, b.count)
        XCTAssertEqual([1, 2, 3, 4], b)
    }

    func testOptArrayEqual() {
        let x: [String] = ["a", "b", "c"]
        let y: [String]? = ["a", "b", "c"]
        let z: [String]? = nil

        XCTAssertTrue(optArrayEqual(x, y))
        XCTAssertTrue(optArrayEqual(x, x))
        XCTAssertTrue(optArrayEqual(y, y))
        XCTAssertTrue(optArrayEqual(z, z))
        XCTAssertFalse(optArrayEqual(x, z))
        XCTAssertFalse(optArrayEqual(z, y))
    }

    func testWithQueryParam() {
        let urlA = NSURL(string: "http://foo.com/bar/")!
        let urlB = NSURL(string: "http://bar.com/noo")!
        let urlC = urlA.withQueryParam("ppp", value: "123")
        let urlD = urlB.withQueryParam("qqq", value: "123")
        let urlE = urlC.withQueryParam("rrr", value: "aaa")

        XCTAssertEqual("http://foo.com/bar/?ppp=123", urlC.absoluteString!)
        XCTAssertEqual("http://bar.com/noo?qqq=123", urlD.absoluteString!)
        XCTAssertEqual("http://foo.com/bar/?ppp=123&rrr=aaa", urlE.absoluteString!)
    }

    func testMockProfilePrefs() {
        let prefs = MockProfilePrefs().branch("baz")
        let val: Timestamp = NSDate.now()
        prefs.setLong(val, forKey: "foobar")
        XCTAssertEqual(val, prefs.unsignedLongForKey("foobar")!)
    }
}