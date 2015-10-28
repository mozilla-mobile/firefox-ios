/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

class StorageClientTests: XCTestCase {

    func testPartialJSON() {
        let body = "0"
        let o: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(body.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.AllowFragments)
        XCTAssertTrue(JSON(o!).isInt)
    }

    func testPOSTResult() {
        // Pulled straight from <http://docs.services.mozilla.com/storage/apis-1.5.html>.
        let r = "{" +
            "\"modified\": 1233702554.25," +
            "\"success\": [\"GXS58IDC_12\", \"GXS58IDC_13\", \"GXS58IDC_15\"," +
            "\"GXS58IDC_16\", \"GXS58IDC_18\", \"GXS58IDC_19\"]," +
            "\"failed\": {\"GXS58IDC_11\": [\"invalid ttl\"]," +
            "\"GXS58IDC_14\": [\"invalid sortindex\"]}" +
        "}"

        let p = POSTResult.fromJSON(JSON.parse(r))
        XCTAssertTrue(p != nil)
        XCTAssertEqual(p!.modified, 1233702554250)
        XCTAssertEqual(p!.success[0], "GXS58IDC_12")
        XCTAssertEqual(p!.failed["GXS58IDC_14"]![0], "invalid sortindex")

        XCTAssertTrue(nil == POSTResult.fromJSON(JSON.parse("{\"foo\": 5}")))
    }

    func testNumeric() {
        let m = ResponseMetadata(status: 200, headers: [
            "X-Last-Modified": "2174380461.12",
        ])
        XCTAssertTrue(m.lastModifiedMilliseconds == 2174380461120)

        XCTAssertEqual("2174380461.12", millisecondsToDecimalSeconds(2174380461120))
    }

    // Trivial test for struct semantics that we might want to pay attention to if they change,
    // and for response header parsing.
    func testResponseHeaders() {
        let v: JSON = JSON.parse("{\"a:\": 2}")
        let m = ResponseMetadata(status: 200, headers: [
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