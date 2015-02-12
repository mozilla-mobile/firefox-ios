/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class TestSQLiteReadingList: XCTestCase {
    var readingList: SQLiteReadingList!

    override func setUp() {
        let files = MockFiles()
        files.remove("browser.db")
        readingList = SQLiteReadingList(files: files)
    }

    func testInsertAndQueryAndClear() {
        var items = [
            ReadingListItem(url: "http://one.com", title: "One"),
            ReadingListItem(url: "http://two.com", title: "Two"),
            ReadingListItem(url: "http://thr.com", title: "Thr")
        ]

        for item in items {
            var expectation = expectationWithDescription("main thread")
            readingList.add(item: item, complete: { (success) -> Void in
                expectation.fulfill()
                XCTAssertTrue(success)
            })
        }

        waitForExpectationsWithTimeout(5.0) { (error) in
            return
        }

        // Fetch them, we should get three back

        var expectation = expectationWithDescription("main thread")
        readingList.get { (cursor) -> Void in
            expectation.fulfill()

            XCTAssertEqual(cursor.status, CursorStatus.Success)
            XCTAssertEqual(cursor.count, 3)

            for index in 0..<cursor.count {
                if let item = cursor[index] as? ReadingListItem {
                    XCTAssert(item.id != nil && item.id! != 0)
                    println("GOT \(item.id) \(item.title!) \(item.clientLastModified)")
                    //XCTAssertEqual(item.title!, items[countElements(items)-index-1].title!)
                } else {
                    XCTFail("Did not get a ReadingListItem back (nil or wrong type)")
                }
            }
        }
        waitForExpectationsWithTimeout(1.0) { (error) in
            return
        }

        // Now delete the items

        readingList.clear { (success) -> Void in
            XCTAssertTrue(success)
        }

        expectation = expectationWithDescription("main thread")
        readingList.get { (cursor) -> Void in
            expectation.fulfill()
            XCTAssertEqual(cursor.status, CursorStatus.Success)
            XCTAssertEqual(cursor.count, 0)
        }
        waitForExpectationsWithTimeout(1.0) { (error) in
            return
        }
    }
}
