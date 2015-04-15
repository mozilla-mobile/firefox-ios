/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class ReadingListBatchRecordResponseTestCase: XCTestCase {

    func testCreateReadingListBatchRecordResponse() {
        let response = NSHTTPURLResponse(URL: NSURL(string: "http://localhost/v1/batch")!, statusCode: 200, HTTPVersion: "1.1", headerFields: ["Content-Type":"application/json"])!
        let headers = ["Content-Type": "application/json"]
        let json: [String:AnyObject] = [
            "responses": [
                ["path": "/v1/articles", "status": 201, "headers": headers, "body": [
                    "id": "GUID1", "last_modified": NSNumber(longLong: 1111111111111), "title": "Article 1", "url": "http://localhost/article/1", "added_by": "Stefan's iPhone",
                        "unread": true, "archived": false, "favorite": false]],
                ["path": "/v1/articles", "status": 200, "headers": headers, "body": [
                    "id": "GUID2", "last_modified": NSNumber(longLong: 2222222222222), "title": "Article 2", "url": "http://localhost/article/2", "added_by": "Stefan's iPhone",
                    "unread": true, "archived": false, "favorite": false]]
            ]
        ]

        if let batchRecordResponse = ReadingListBatchRecordResponse(response: response, json: json) {
            XCTAssertEqual(batchRecordResponse.responses.count, 2)

            XCTAssertEqual(batchRecordResponse.responses[0].response.statusCode, 201)
            XCTAssert(batchRecordResponse.responses[0].record != nil)
            XCTAssert(batchRecordResponse.responses[0].response.allHeaderFields.count > 0)
            if let record = batchRecordResponse.responses[0].record {
                XCTAssertEqual(record.serverMetadata!.guid, "GUID1")
            }

            XCTAssertEqual(batchRecordResponse.responses[1].response.statusCode, 200)
            XCTAssert(batchRecordResponse.responses[1].record != nil)
            XCTAssert(batchRecordResponse.responses[1].response.allHeaderFields.count > 0)
            if let record = batchRecordResponse.responses[1].record {
                XCTAssertEqual(record.serverMetadata!.guid, "GUID2")
            }
        } else {
            XCTFail("batchRecordResponse is nil")
        }
    }

}
