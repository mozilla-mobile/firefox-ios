// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

class ClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        XCTAssert(true, "Pass")
    }

    func testBookmarks() {
        var expectation = expectationWithDescription("asynchronous request")
        Bookmarks.getAll({ (response: [Bookmark]) in
            XCTAssert(response.count > 0, "Found some bookmarks");
            for bookmark in response {
                XCTAssert(bookmark.url != "", "Bookmarks has url \(bookmark.url)");
                XCTAssert(bookmark.title != "", "Bookmarks has title  \(bookmark.title)");
            }
            expectation.fulfill()
        });

        waitForExpectationsWithTimeout(10.0, handler:nil)
    }
    
    func testPerformanceExample() {
        self.measureBlock() {
        }
    }
    
}
