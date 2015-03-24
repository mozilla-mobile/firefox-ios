/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

class StorageClientTests: XCTestCase {

    func testNumeric() {
        let m = ResponseMetadata(headers: [
            "X-Last-Modified": "2174380461.12",
        ])
        XCTAssertTrue(m.lastModifiedMilliseconds == 2174380461120)
    }

    // Trivial test for struct semantics that we might want to pay attention to if they change,
    // and for response header parsing.
    func testResponseHeaders() {
        let v: JSON = JSON.parse("{\"a:\": 2}")
        let m = ResponseMetadata(headers: [
            "X-Weave-Timestamp": "1274380461.12",
            "X-Last-Modified":   "2174380461.12",
            "X-Weave-Next-Offset": "abdef",
            ])

        XCTAssertTrue(m.lastModifiedMilliseconds == 2174380461120)
        XCTAssertTrue(m.timestampMilliseconds    == 1274380461120)
        XCTAssertTrue(m.nextOffset == "abdef")

        // Just to avoid consistent overflow allowing ==.
        XCTAssertTrue(m.lastModifiedMilliseconds?.description == "2174380461120")
        XCTAssertTrue(m.timestampMilliseconds.description == "1274380461120")

        let x: StorageResponse<JSON> = StorageResponse<JSON>(value: v, metadata: m)

        func doTesting(y: StorageResponse<JSON>) {
            // Make sure that reference fields in a struct are copies of the same reference,
            // not references to a copy.
            XCTAssertTrue(x.value === y.value)

            XCTAssertTrue(y.metadata.lastModifiedMilliseconds == x.metadata.lastModifiedMilliseconds, "lastModified is the same.")

            XCTAssertTrue(x.metadata.quotaRemaining == nil, "No quota.")
            XCTAssertTrue(y.metadata.lastModifiedMilliseconds == 2174380461120, "lastModified is correct.")
            XCTAssertTrue(x.metadata.timestampMilliseconds == 1274380461120, "timestamp is correct.")
            XCTAssertTrue(x.metadata.nextOffset == "abdef", "nextOffset is correct.")
            XCTAssertTrue(x.metadata.records == nil, "No X-Weave-Records.")
        }

        doTesting(x)
    }
}