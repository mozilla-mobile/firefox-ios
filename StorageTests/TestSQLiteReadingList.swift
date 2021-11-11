// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
@testable import Storage
@testable import Client

import XCTest

class TestSQLiteReadingList: XCTestCase {
    let files = MockFiles()
    var db: BrowserDB!
    var readingList: SQLiteReadingList!

    override func setUp() {
        super.setUp()
        self.db = BrowserDB(filename: "ReadingListTest.db", schema: ReadingListSchema(), files: self.files)
        self.readingList = SQLiteReadingList(db: db)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCreateRecord() {
        let result = readingList.createRecordWithURL("http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance", title: "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma", addedBy: "Stefan's iPhone").value
        switch result {
        case .failure(let error):
            XCTFail(error.description)
        case .success(let result):
            XCTAssertEqual(result.url, "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance")
            XCTAssertEqual(result.title, "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma")
            XCTAssertEqual(result.addedBy, "Stefan's iPhone")
            XCTAssertEqual(result.unread, true)
            XCTAssertEqual(result.archived, false)
            XCTAssertEqual(result.favorite, false)
        }
    }

    func testGetRecordWithURL() {
        let result1 = readingList.createRecordWithURL("http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance", title: "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma", addedBy: "Stefan's iPhone").value
        switch result1 {
        case .failure(let error):
            XCTFail(error.description)
        case .success( _):
            break
        }

        let result2 = readingList.getRecordWithURL("http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance").value
        switch result2 {
        case .failure(let error):
            XCTFail(error.description)
        case .success( _):
            XCTAssert(result1.successValue == result2.successValue!)
        }
    }

    func testGetAllRecords() {
        let _ = createRecordWithURL("http://localhost/article1", title: "Test 1", addedBy: "Stefan's iPhone")
        let createResult2 = createRecordWithURL("http://localhost/article2", title: "Test 2", addedBy: "Stefan's iPhone")
        let _ = createRecordWithURL("http://localhost/article3", title: "Test 3", addedBy: "Stefan's iPhone")
        if let record = createResult2.successValue {
            let _ = updateRecord(record, unread: false)
        }

        let getAllResult = readingList.getAvailableRecords().value
        if let records = getAllResult.successValue {
            XCTAssertEqual(3, records.count)
        }
    }

    func testGetNewRecords() {
        let _ = createRecordWithURL("http://localhost/article1", title: "Test 1", addedBy: "Stefan's iPhone")
        let _ = createRecordWithURL("http://localhost/article2", title: "Test 2", addedBy: "Stefan's iPhone")
        let _ = createRecordWithURL("http://localhost/article3", title: "Test 3", addedBy: "Stefan's iPhone")
        let getAllResult = getAllRecords()
        if let records = getAllResult.successValue {
            XCTAssertEqual(3, records.count)
        }
        // TODO When we are able to create records coming from the server, we can extend this test to see if we query correctly
    }

    func testDeleteRecord() {
        let result1 = readingList.createRecordWithURL("http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance", title: "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma", addedBy: "Stefan's iPhone").value
        switch result1 {
        case .failure(let error):
            XCTFail(error.description)
        case .success(_):
            break
        }

        let result2 = readingList.deleteRecord(result1.successValue!).value
        switch result2 {
        case .failure(let error):
            XCTFail(error.description)
        case .success:
            break
        }

        let result3 = readingList.getRecordWithURL("http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance").value
        switch result3 {
        case .failure:
            break
        case .success:
            XCTFail("ReadingListItem should have been deleted")
        }
    }

    func testDeleteAllRecords() {
        let _ = createRecordWithURL("http://localhost/article1", title: "Test 1", addedBy: "Stefan's iPhone")
        let _ = createRecordWithURL("http://localhost/article2", title: "Test 2", addedBy: "Stefan's iPhone")
        let _ = createRecordWithURL("http://localhost/article3", title: "Test 3", addedBy: "Stefan's iPhone")

        let getAllResult1 = readingList.getAvailableRecords().value
        if let records = getAllResult1.successValue {
            XCTAssertNotEqual(0, records.count)
        }

        let _ = deleteAllRecords()

        let getAllResult2 = getAllRecords()
        if let records = getAllResult2.successValue {
            XCTAssertEqual(0, records.count)
        }
    }

    func testUpdateRecord() {
        let result = createRecordWithURL("http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance", title: "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma", addedBy: "Stefan's iPhone")
        if let record = result.successValue {
            XCTAssertEqual(record.url, "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance")
            XCTAssertEqual(record.title, "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma")
            XCTAssertEqual(record.addedBy, "Stefan's iPhone")
            XCTAssertEqual(record.unread, true)
            XCTAssertEqual(record.archived, false)
            XCTAssertEqual(record.favorite, false)

            let result = updateRecord(record, unread: false)
            if let record = result.successValue {
                XCTAssertEqual(record.url, "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance")
                XCTAssertEqual(record.title, "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma")
                XCTAssertEqual(record.addedBy, "Stefan's iPhone")
                XCTAssertEqual(record.unread, false)
                XCTAssertEqual(record.archived, false)
                XCTAssertEqual(record.favorite, false)
            }
        }
    }

    // Helpers that croak if the storage call was not successful

    func createRecordWithURL(_ url: String, title: String, addedBy: String) -> Maybe<ReadingListItem> {
        let result = readingList.createRecordWithURL(url, title: title, addedBy: addedBy).value
        XCTAssertTrue(result.isSuccess)
        return result
    }

    func deleteAllRecords() -> Maybe<Void> {
        let result = readingList.deleteAllRecords().value
        XCTAssertTrue(result.isSuccess)
        return result
    }

    func getAllRecords() -> Maybe<[ReadingListItem]> {
        let result = readingList.getAvailableRecords().value
        XCTAssertTrue(result.isSuccess)
        return result
    }

    func updateRecord(_ record: ReadingListItem, unread: Bool) -> Maybe<ReadingListItem> {
        let result = readingList.updateRecord(record, unread: unread).value
        XCTAssertTrue(result.isSuccess)
        return result
    }
}
