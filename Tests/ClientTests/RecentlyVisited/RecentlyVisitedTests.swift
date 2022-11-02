// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client
@testable import Storage

class RecentlyVisitedTests: XCTestCase {

    private var manager: RecentlyVisitedManager!
    private var profile: MockProfile!
    private var entryProvider: RecentlyVisitedTestEntryProvider!

    override func setUp() {
        super.setUp()

        manager = RecentlyVisitedManager()
        profile = MockProfile(databasePrefix: "recentlyVisited_tests")
        profile.reopen()
        let tabManager = TabManager(profile: profile, imageStore: nil)
        entryProvider = RecentlyVisitedTestEntryProvider(with: profile, and: tabManager)
    }

    override func tearDown() {
        super.tearDown()

        manager = nil
        profile.shutdown()
        profile = nil
        entryProvider = nil
    }

    func testEmptyRead() {
        entryProvider.emptyDB()

        let emptyRead = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyRead.isSuccess)
        XCTAssertNotNil(emptyRead.successValue)
        XCTAssertEqual(emptyRead.successValue!.count, 0)
    }

    func testSingleDataExists() {
        entryProvider.emptyDB()
        entryProvider.setupData(forTestURL: "https://www.mozilla.com/",
                                withTitle: "Mozilla Test",
                                andViewTime: 1)

        let singleItemRead = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(singleItemRead.isSuccess)
        XCTAssertNotNil(singleItemRead.successValue)
        XCTAssertEqual(singleItemRead.successValue!.count, 1)
        XCTAssertEqual(singleItemRead.successValue![0].url, "https://www.mozilla.com/")
        XCTAssertEqual(singleItemRead.successValue![0].title?.lowercased(), "mozilla test")
        XCTAssertEqual(singleItemRead.successValue![0].documentType, DocumentType.regular)
        XCTAssertEqual(singleItemRead.successValue![0].totalViewTime, 1)
    }

    func testRecentlyVisitedDontExist() {
        entryProvider.emptyDB()

        let expectation = expectation(description: "Recently Visited")

        manager.getData(with: profile, and: [Tab]()) { items in
            XCTAssertNil(items, "Recently Visited should be nil if the DB is empty")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRecentlyVisitedCount() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("amazon", "")]
        entryProvider.createEntry(siteEntry: testSites)

        let expectation = expectation(description: "Recently Visited")
        let expectedCount = 3

        manager.getData(with: profile, and: [Tab]()) { items in

            guard let items = items else {
                XCTFail("Recently Visited items should not be nil.")
                return
            }

            XCTAssertEqual(items.count, expectedCount, "There should be three Recently Visited items")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRecentlyVisitedCount_ForMoreThanNineResult() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("amazon", ""),
                         ("github", ""),
                         ("google", ""),
                         ("facebook", ""),
                         ("testSite1", ""),
                         ("testSite2", ""),
                         ("testSite3", ""),
                         ("testSite4", ""),
                         ("testSite5", "")]
        entryProvider.createEntry(siteEntry: testSites)

        let expectation = expectation(description: "Recently Visited")
        let expectedCount = 9

        manager.getData(with: profile, and: [Tab]()) { items in

            guard let items = items else {
                XCTFail("Recently Visited should not be nil.")
                return
            }

            XCTAssertEqual(items.count, expectedCount, "There should be nine Recently Visited items")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleRecentlyVisitedExists_RemovingOpenTab() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("amazon", "")]
        entryProvider.createEntry(siteEntry: testSites)

        let tabs = entryProvider.createTabs(named: "mozilla")

        let expectation = expectation(description: "Recently Visited")
        let expectedCount = 2

        manager.getData(with: profile, and: [tabs]) { items in
            guard let items = items else {
                XCTFail("Recently Visited should not be nil.")
                return
            }

            XCTAssertEqual(items.count, expectedCount, "There should be two Recently Visited items")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleRecentlyVisited_withGroupingEnabled() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("amazon", ""),
                         ("mozilla", "/group"),
                         ("amazon", "/group")]
        entryProvider.createEntry(siteEntry: testSites)
        // 2 groups and 1 individual item
        let expectedCount = 3

        let expectation = expectation(description: "Recently Visited")

        manager.getData(with: profile, and: [Tab](), shouldGroup: true) { items in

            guard let items = items else {
                XCTFail("Recently Visited items should not be nil.")
                return
            }

            XCTAssertEqual(items.count, expectedCount, "There should be three Recently Visited items")
            XCTAssertNotNil((items[0] as? HistoryHighlight), "Expected Recently Visited as the first item")
            XCTAssertNotNil((items[1] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            XCTAssertNotNil((items[2] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleRecentlyVisitedOrder_withMoreSingleItemEach() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("apple", ""),
                         ("mozilla", "/group")]
        entryProvider.createEntry(siteEntry: testSites)
        let expectedCount = 3

        let expectation = expectation(description: "Recently Visited")

        manager.getData(with: profile, and: [Tab](), shouldGroup: true) { items in

            guard let items = items else {
                XCTFail("Recently Visited items should not be nil.")
                return
            }

            XCTAssertEqual(items.count, expectedCount, "There should be two Recently Visited items")
            XCTAssertNotNil((items[0] as? HistoryHighlight), "Expected Recently Visited as the first item")
            XCTAssertNotNil((items[1] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            XCTAssertNotNil((items[2] as? HistoryHighlight), "Expected Recently Visited as the first item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleRecentlyVisitedOrder_withTwoItemEach() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("apple", ""),
                         ("mozilla", "/group"),
                         ("apple", "/group"),
                         ("google", "/group")]
        entryProvider.createEntry(siteEntry: testSites)
        let expectedCount = 4

        let expectation = expectation(description: "Recently Visited")

        manager.getData(with: profile, and: [Tab](), shouldGroup: true) { items in

            guard let items = items else {
                XCTFail("Recently Visited items should not be nil.")
                return
            }

            XCTAssertEqual(items.count, expectedCount, "There should be two Recently Visited items")
            XCTAssertNotNil((items[0] as? HistoryHighlight), "Expected Recently Visited as the first item")
            XCTAssertNotNil((items[1] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            XCTAssertNotNil((items[2] as? HistoryHighlight), "Expected Recently Visited as the first item")
            XCTAssertNotNil((items[3] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleRecentlyVisitedOrder_OnlySingleItems() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("apple", "")]
        entryProvider.createEntry(siteEntry: testSites)
        let expectedCount = 3

        let expectation = expectation(description: "Recently Visited")

        manager.getData(with: profile, and: [Tab](), shouldGroup: true) { items in

            guard let items = items else {
                XCTFail("Recently Visited items should not be nil.")
                return
            }

            XCTAssertEqual(items.count, expectedCount, "There should be two Recently Visited items")
            XCTAssertNotNil((items[0] as? HistoryHighlight), "Expected Recently Visited as the first item")
            XCTAssertNotNil((items[1] as? HistoryHighlight), "Expected Recently Visited as second item")
            XCTAssertNotNil((items[2] as? HistoryHighlight), "Expected Recently Visited as the first item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleRecentlyVisitedOrder_OnlyGroupItems() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("mozilla", "/group"),
                         ("wikipedia", ""),
                         ("wikipedia", "/group"),
                         ("apple", ""),
                         ("apple", "/group")]
        entryProvider.createEntry(siteEntry: testSites)
        let expectedCount = 3

        let expectation = expectation(description: "Recently Visited")

        manager.getData(with: profile, and: [Tab](), shouldGroup: true) { items in

            guard let items = items else {
                XCTFail("Recently Visited items should not be nil.")
                return
            }

            XCTAssertEqual(items.count, expectedCount, "There should be two Recently Visited items")
            XCTAssertNotNil((items[0] as? ASGroup<HistoryHighlight>), "Expected group as the first item")
            XCTAssertNotNil((items[1] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            XCTAssertNotNil((items[2] as? ASGroup<HistoryHighlight>), "Expected group as the first item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
