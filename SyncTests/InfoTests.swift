/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Sync

import XCTest

class InfoTests: XCTestCase {
    func testSame() {
        let empty = JSON.parse("{}")

        let oneA = JSON.parse("{\"foo\": 1234.0, \"bar\": 456.12}")
        let oneB = JSON.parse("{\"bar\": 456.12, \"foo\": 1234.0}")

        let twoA = JSON.parse("{\"bar\": 456.12}")
        let twoB = JSON.parse("{\"foo\": 1234.0}")

        let iEmpty = InfoCollections.fromJSON(empty)!
        let iOneA = InfoCollections.fromJSON(oneA)!
        let iOneB = InfoCollections.fromJSON(oneB)!
        let iTwoA = InfoCollections.fromJSON(twoA)!
        let iTwoB = InfoCollections.fromJSON(twoB)!

        XCTAssertTrue(iEmpty.same(iEmpty, collections: nil))
        XCTAssertTrue(iEmpty.same(iEmpty, collections: []))
        XCTAssertTrue(iEmpty.same(iEmpty, collections: ["anything"]))

        XCTAssertTrue(iEmpty.same(iOneA, collections: []))
        XCTAssertTrue(iEmpty.same(iOneA, collections: ["anything"]))
        XCTAssertTrue(iOneA.same(iEmpty, collections: []))
        XCTAssertTrue(iOneA.same(iEmpty, collections: ["anything"]))

        XCTAssertFalse(iEmpty.same(iOneA, collections: ["foo"]))
        XCTAssertFalse(iOneA.same(iEmpty, collections: ["foo"]))
        XCTAssertFalse(iEmpty.same(iOneA, collections: nil))
        XCTAssertFalse(iOneA.same(iEmpty, collections: nil))

        XCTAssertTrue(iOneA.same(iOneA, collections: nil))
        XCTAssertTrue(iOneA.same(iOneA, collections: ["foo", "bar", "baz"]))
        XCTAssertTrue(iOneA.same(iOneB, collections: ["foo", "bar", "baz"]))
        XCTAssertTrue(iOneB.same(iOneA, collections: ["foo", "bar", "baz"]))

        XCTAssertFalse(iTwoA.same(iOneA, collections: nil))
        XCTAssertTrue(iTwoA.same(iOneA, collections: ["bar", "baz"]))
        XCTAssertTrue(iOneA.same(iTwoA, collections: ["bar", "baz"]))
        XCTAssertTrue(iTwoB.same(iOneA, collections: ["foo", "baz"]))

        XCTAssertFalse(iTwoA.same(iTwoB, collections: nil))
        XCTAssertFalse(iTwoA.same(iTwoB, collections: ["foo"]))
        XCTAssertFalse(iTwoA.same(iTwoB, collections: ["bar"]))
    }
}
