// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@testable import Storage
import XCTest

class TestSQLiteQueue: XCTestCase {
    lazy var files = makeTemporaryFiles()
    var db: BrowserDB!
    var queue: SQLiteQueue!

    override func setUp() {
        super.setUp()
        self.db = BrowserDB(filename: "QueueTest.db", schema: BrowserSchema(), files: self.files)
        self.queue = SQLiteQueue(db: db)
    }

    override func tearDown() {
        self.queue = nil
        self.db = nil
        super.tearDown()
    }

    func testGetQueuedTabs_whenQueueIsEmpty_returnsNoTabs() async throws {
        let tabs = try await queue.getQueuedTabs()

        XCTAssertTrue(tabs.isEmpty)
    }

    func testGetQueuedTabs_afterAddingTabs_returnsAllTabs() async throws {
        let urls = ["https://www.mozilla.org/",
                    "https://www.firefox.com/",
                    "https://example.com/"]
        for url in urls {
            let result = queue.addToQueue(ShareItem(url: url, title: "")).value
            XCTAssertTrue(result.isSuccess, result.failureValue?.description ?? "")
        }

        let tabs = try await queue.getQueuedTabs()

        XCTAssertEqual(Set(tabs.map { $0.url }), Set(urls))
    }

    func testGetQueuedTabs_afterClearing_returnsNoTabs() async throws {
        _ = queue.addToQueue(ShareItem(url: "https://www.mozilla.org/", title: "")).value
        let queuedBeforeClearing = try await queue.getQueuedTabs()
        XCTAssertFalse(queuedBeforeClearing.isEmpty)

        let result = queue.clearQueuedTabs().value
        XCTAssertTrue(result.isSuccess, result.failureValue?.description ?? "")

        let tabs = try await queue.getQueuedTabs()
        XCTAssertTrue(tabs.isEmpty)
    }

    func testGetQueuedTabs_whenSameURLAddedTwice_returnsSingleTab() async throws {
        let url = "https://www.mozilla.org/"
        _ = queue.addToQueue(ShareItem(url: url, title: "")).value
        _ = queue.addToQueue(ShareItem(url: url, title: "")).value

        let tabs = try await queue.getQueuedTabs()

        XCTAssertEqual(tabs.count, 1)
        XCTAssertEqual(tabs.first?.url, url)
    }
}
