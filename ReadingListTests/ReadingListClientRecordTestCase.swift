/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import ReadingList
import Foundation

import XCTest

class ReadingListClientRecordTestCase: XCTestCase {

    func testInitWithRow() {
        let now = ReadingListNow()
        let row: [String: Any] = [
            "client_id": Int64(1234),
            "client_last_modified": now,
            "id": "5DB5597A-8E60-454D-B1F5-51810C2A5FFE",
            "last_modified": now,
            "url": "http://localhost/article/1",
            "title": "Article 1",
            "added_by": "Stefan's iPhone",
            "unread": true,
            "archived": false,
            "favorite": true
        ]

        let record = ReadingListClientRecord(row: row)
        XCTAssert(record != nil)

        if let record = record {
            XCTAssertEqual(record.url, "http://localhost/article/1")
            XCTAssertEqual(record.title, "Article 1")
            XCTAssertEqual(record.addedBy, "Stefan's iPhone")
            XCTAssertEqual(record.unread, true)
            XCTAssertEqual(record.archived, false)
            XCTAssertEqual(record.favorite, true)

            XCTAssert(record.clientMetadata.id == 1234)
            XCTAssert(record.clientMetadata.lastModified == now)

            XCTAssert(record.serverMetadata != nil)
            XCTAssertEqual(record.serverMetadata!.guid, "5DB5597A-8E60-454D-B1F5-51810C2A5FFE")
            XCTAssertEqual(record.serverMetadata!.lastModified, now)
        }
    }

    func testInitWithRowWithoutServerMeta() {
        let now = ReadingListNow()
        let row: [String:Any] = [
            "client_id": Int64(1234),
            "client_last_modified": now,
            "url": "http://localhost/article/1",
            "title": "Article 1",
            "added_by": "Stefan's iPhone",
            "unread": true,
            "archived": false,
            "favorite": true
        ]

        let record = ReadingListClientRecord(row: row)
        XCTAssert(record != nil)

        if let record = record {
            XCTAssertEqual(record.url, "http://localhost/article/1")
            XCTAssertEqual(record.title, "Article 1")
            XCTAssertEqual(record.addedBy, "Stefan's iPhone")
            XCTAssertEqual(record.unread, true)
            XCTAssertEqual(record.archived, false)
            XCTAssertEqual(record.favorite, true)

            XCTAssert(record.clientMetadata.id == 1234)
            XCTAssert(record.clientMetadata.lastModified == now)

            XCTAssert(record.serverMetadata == nil)
        }
    }

    func testInitWithEmptyRow() {
        let row = NSDictionary()
        let record = ReadingListClientRecord(row: row as! [String : Any])
        XCTAssert(record == nil)
    }

//    func testInit() {
//        let record = ReadingListClientRecord(url: "http://localhost/some/article", title: "Some Article", addedBy: "Stefan's iPad Mini")
//        XCTAssertNil(record.clientMetadata.id)
//        XCTAssert(record.clientMetadata.lastModified != 0)
//        XCTAssert(record.serverMetadata == nil)
//        XCTAssertEqual(record.url, "http://localhost/some/article")
//        XCTAssertEqual(record.title, "Some Article")
//        XCTAssertEqual(record.addedBy, "Stefan's iPad Mini")
//        XCTAssertEqual(record.unread, ReadingListDefaultUnread)
//        XCTAssertEqual(record.favorite, ReadingListDefaultFavorite)
//        XCTAssertEqual(record.archived, ReadingListDefaultArchived)
//    }

    func testJSON() {
        let now = ReadingListNow()
        let row: [String:Any] = [
            "client_id": Int64(1234),
            "client_last_modified": now,
            "id": "5DB5597A-8E60-454D-B1F5-51810C2A5FFE",
            "last_modified": now,
            "url": "http://localhost/article/1",
            "title": "Article 1",
            "added_by": "Stefan's iPhone 3GS",
            "unread": true,
            "archived": false,
            "favorite": true
        ]

        let record = ReadingListClientRecord(row: row)
        XCTAssert(record != nil)

        if let record = record {
            let json: AnyObject = record.json
            XCTAssertEqual(json.value(forKeyPath: "url") as? String, "http://localhost/article/1")
            XCTAssertEqual(json.value(forKeyPath: "title") as? String, "Article 1")
            XCTAssertEqual(json.value(forKeyPath: "added_by") as? String, "Stefan's iPhone 3GS")

            XCTAssertEqual(json.value(forKeyPath: "unread") as? Bool, true)
            XCTAssertEqual(json.value(forKeyPath: "archived") as? Bool, false)
            XCTAssertEqual(json.value(forKeyPath: "favorite") as? Bool, true)
        }
    }
}
