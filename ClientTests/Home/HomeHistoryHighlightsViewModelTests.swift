// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class HomeHistoryHighlightsViewModelTests: XCTestCase {

    private var sut: FxHomeHistoryHightlightsViewModel!
    private var profile: MockProfile!
    private var tabManager: TabManager!
    private var entryProvider: HistoryHighlightsTestEntryProvider!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "historyHighlightViewModel_tests")
        profile._reopen()
        tabManager = TabManager(profile: profile, imageStore: nil)
        entryProvider = HistoryHighlightsTestEntryProvider(with: profile, and: tabManager)
        sut = FxHomeHistoryHightlightsViewModel(with: profile,
                                                isPrivate: false,
                                                tabManager: tabManager)
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        profile = nil
        tabManager = nil
        entryProvider = nil
        sut = nil
    }

    func testViewModelCreation_WithNoEntries() {
        entryProvider.emptyDB()
        let expectation = expectation(description: "Wait for items to be loaded")
        sut.loadItems {
            XCTAssertNil(self.sut.historyItems)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testViewModelCreation_WithOneEntry() {
        entryProvider.emptyDB()
        let testSites = [("mozilla", "")]
        entryProvider.createHistoryEntry(siteEntry: testSites)
        let expectation = expectation(description: "Wait for items to be loaded")

        sut.loadItems {
            XCTAssertEqual(self.sut.historyItems?.count, 1)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testGetItems_isNil() {
        entryProvider.emptyDB()
        let expectation = expectation(description: "Wait for items to be loaded")

        sut.loadItems {
            XCTAssertNil(self.sut.getItemDetailsAt(index: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
    }

    func testGetItems_isMozilla() {
        entryProvider.emptyDB()
        let testSites = [("mozilla", "")]
        entryProvider.createHistoryEntry(siteEntry: testSites)
        let expectedString = "mozilla test"
        let expectation = expectation(description: "Wait for items to be loaded")

        sut.loadItems {
            XCTAssertEqual(self.sut.getItemDetailsAt(index: 0)?.displayTitle, expectedString)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }
}
