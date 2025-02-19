// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import XCTest
import Common

@testable import Client
@testable import Storage

// FXIOS-8331: Disable History Highlight tests while FXIOS-8059 (Epic) is in progress
// FXIOS-8367: Added a ticket to enable these tests when we re-enable history highlights
class HistoryHighlightsTests: XCTestCase {
    private var manager: HistoryHighlightsManager!
    private var profile: MockProfile!
    private var entryProvider: HistoryHighlightsTestEntryProvider!

    override func setUp() {
        super.setUp()

        manager = HistoryHighlightsManager()
        profile = MockProfile(databasePrefix: "historyHighlights_tests")
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        DependencyHelperMock().bootstrapDependencies()
        profile.reopen()
        let tabManager = TabManagerImplementation(profile: profile,
                                                  uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        entryProvider = HistoryHighlightsTestEntryProvider(with: profile, and: tabManager)
    }

    override func tearDown() {
        manager = nil
        profile.shutdown()
        profile = nil
        entryProvider = nil
        DependencyHelperMock().reset()
        super.tearDown()
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

    func testHistoryHighlightsDontExist() {
        entryProvider.emptyDB()

        let expectation = expectation(description: "Highlights")

        manager.getHighlightsData(with: profile, and: [Tab]()) { highlights in
            XCTAssertNil(highlights, "Highlights should be nil if the DB is empty")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testHistoryHighlightCount() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("amazon", "")]
        entryProvider.createHistoryEntry(siteEntry: testSites)

        let expectation = expectation(description: "Highlights")
        let expectedCount = 3

        manager.getHighlightsData(with: profile, and: [Tab]()) { highlights in
            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be three history highlight")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testHistoryHighlightCount_ForMoreThanNineResult() {
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
        entryProvider.createHistoryEntry(siteEntry: testSites)

        let expectation = expectation(description: "Highlights")
        let expectedCount = 9

        manager.getHighlightsData(with: profile, and: [Tab]()) { highlights in
            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be nine history highlight")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightExists_RemovingOpenTab() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("amazon", "")]
        entryProvider.createHistoryEntry(siteEntry: testSites)

        let tabs = entryProvider.createTabs(named: "mozilla")

        let expectation = expectation(description: "Highlights")
        let expectedCount = 2

        manager.getHighlightsData(with: profile, and: [tabs]) { highlights in
            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be two history highlight")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlight_withGroupingEnabled() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("amazon", ""),
                         ("mozilla", "/group"),
                         ("amazon", "/group")]
        entryProvider.createHistoryEntry(siteEntry: testSites)
        // 2 groups and 1 individual item
        let expectedCount = 3

        let expectation = expectation(description: "Highlights")

        manager.getHighlightsData(with: profile, and: [Tab](), shouldGroupHighlights: true) { highlights in
            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be three history highlight")
            XCTAssertNotNil((highlights[0] as? HistoryHighlight), "Expected History highlight as the first item")
            XCTAssertNotNil((highlights[1] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            XCTAssertNotNil((highlights[2] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightOrder_withMoreSingleItemEach() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("apple", ""),
                         ("mozilla", "/group")]
        entryProvider.createHistoryEntry(siteEntry: testSites)
        let expectedCount = 3

        let expectation = expectation(description: "Highlights")

        manager.getHighlightsData(with: profile, and: [Tab](), shouldGroupHighlights: true) { highlights in
            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be two history highlight")
            XCTAssertNotNil((highlights[0] as? HistoryHighlight), "Expected History highlight as the first item")
            XCTAssertNotNil((highlights[1] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            XCTAssertNotNil((highlights[2] as? HistoryHighlight), "Expected History highlight as the first item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightOrder_withTwoItemEach() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("apple", ""),
                         ("mozilla", "/group"),
                         ("apple", "/group"),
                         ("google", "/group")]
        entryProvider.createHistoryEntry(siteEntry: testSites)
        let expectedCount = 4

        let expectation = expectation(description: "Highlights")

        manager.getHighlightsData(with: profile, and: [Tab](), shouldGroupHighlights: true) { highlights in
            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be two history highlight")
            XCTAssertNotNil((highlights[0] as? HistoryHighlight), "Expected History highlight as the first item")
            XCTAssertNotNil((highlights[1] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            XCTAssertNotNil((highlights[2] as? HistoryHighlight), "Expected History highlight as the first item")
            XCTAssertNotNil((highlights[3] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightOrder_OnlySingleItems() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("apple", "")]
        entryProvider.createHistoryEntry(siteEntry: testSites)
        let expectedCount = 3

        let expectation = expectation(description: "Highlights")

        manager.getHighlightsData(with: profile, and: [Tab](), shouldGroupHighlights: true) { highlights in
            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be two history highlight")
            XCTAssertNotNil((highlights[0] as? HistoryHighlight), "Expected History highlight as the first item")
            XCTAssertNotNil((highlights[1] as? HistoryHighlight), "Expected History highlight as second item")
            XCTAssertNotNil((highlights[2] as? HistoryHighlight), "Expected History highlight as the first item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightOrder_OnlyGroupItems() {
        entryProvider.emptyDB()

        let testSites = [("mozilla", ""),
                         ("mozilla", "/group"),
                         ("wikipedia", ""),
                         ("wikipedia", "/group"),
                         ("apple", ""),
                         ("apple", "/group")]
        entryProvider.createHistoryEntry(siteEntry: testSites)
        let expectedCount = 3

        let expectation = expectation(description: "Highlights")

        manager.getHighlightsData(with: profile, and: [Tab](), shouldGroupHighlights: true) { highlights in
            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be two history highlight")
            XCTAssertNotNil((highlights[0] as? ASGroup<HistoryHighlight>), "Expected group as the first item")
            XCTAssertNotNil((highlights[1] as? ASGroup<HistoryHighlight>), "Expected group as second item")
            XCTAssertNotNil((highlights[2] as? ASGroup<HistoryHighlight>), "Expected group as the first item")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
