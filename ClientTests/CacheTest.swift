// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import XCTest

// TODO: Move this to an AccountTest
class CacheTest: XCTestCase {
    func testLRUCache() {
        var c = LRUCache<String, String>(cacheSize: 3);
        XCTAssertNil(c["one"], "Found nil when nothing added element")

        c["one"] = "one"
        XCTAssertEqual(c["one"]!, "one", "Found expected element")
        XCTAssertNil(c["two"], "Found nil for unadded key")

        c["two"] = "two"
        XCTAssertEqual(c["one"]!, "one", "Found expected element")
        XCTAssertEqual(c["two"]!, "two", "Found expected element")

        c["three"] = "three"
        XCTAssertEqual(c["three"]!, "three", "Found expected element")

        c["four"] = "four"
        XCTAssertNil(c["one"], "One was bumped from cache")
        XCTAssertEqual(c["two"]!, "two", "Found expected element")
        XCTAssertEqual(c["three"]!, "three", "Found expected element")
        XCTAssertEqual(c["four"]!, "four", "Found expected element")

        c["five"] = "five"
        XCTAssertNil(c["one"], "One was bumped from cache")
        XCTAssertNil(c["two"], "Found expected element")
        XCTAssertEqual(c["three"]!, "three", "Found expected element")
        XCTAssertEqual(c["four"]!, "four", "Found expected element")
        XCTAssertEqual(c["five"]!, "five", "Found expected element")

        c.clear()
        XCTAssertNil(c["one"], "One was bumped from cache")
        XCTAssertNil(c["two"], "Found expected element")
        XCTAssertNil(c["three"], "One was bumped from cache")
        XCTAssertNil(c["four"], "Found expected element")
        XCTAssertNil(c["five"], "One was bumped from cache")
    }
}
