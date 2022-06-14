// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class HomeHistoryHighlightsViewModelTests: XCTestCase {

    private var profile: MockProfile!
    private var tabManager: TabManager!
    private var entryProvider: HistoryHighlightsTestEntryProvider!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "historyHighlightViewModel_tests")
        profile._reopen()
        tabManager = TabManager(profile: profile, imageStore: nil)
        entryProvider = HistoryHighlightsTestEntryProvider(with: profile, and: tabManager)
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        profile = nil
        tabManager = nil
        entryProvider = nil
    }

    func testViewModelCreation_WithNoEntries() {
        entryProvider.emptyDB()
        let viewModel = FxHomeHistoryHightlightsViewModel(with: profile,
                                                          isPrivate: false,
                                                          tabManager: tabManager)
        delayTest {
            XCTAssertNil(viewModel.historyItems)
        }
    }

    func testViewModelCreation_WithOneEntry() {
        entryProvider.emptyDB()
        let testSites = [("mozilla", "")]
        entryProvider.createHistoryEntry(siteEntry: testSites)

        let viewModel = FxHomeHistoryHightlightsViewModel(with: profile,
                                                          isPrivate: false,
                                                          tabManager: tabManager)
        delayTest {
            XCTAssertEqual(viewModel.historyItems?.count, 1)
        }
    }

    func testGetItems_isNil() {
        entryProvider.emptyDB()
        let viewModel = FxHomeHistoryHightlightsViewModel(with: profile,
                                                          isPrivate: false,
                                                          tabManager: tabManager)

        delayTest {
            XCTAssertNil(viewModel.getItemDetailsAt(index: 0))
        }
    }

    func testGetItems_isMozilla() {
        entryProvider.emptyDB()
        let testSites = [("mozilla", "")]
        entryProvider.createHistoryEntry(siteEntry: testSites)
        let viewModel = FxHomeHistoryHightlightsViewModel(with: profile,
                                                          isPrivate: false,
                                                          tabManager: tabManager)

        let expectedString = "mozilla test"

        delayTest {
            XCTAssertEqual(viewModel.getItemDetailsAt(index: 0)?.displayTitle, expectedString)
        }
    }

    private func delayTest(for seconds: TimeInterval = 1.0, then completion: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Test after \(seconds) seconds")
        let result = XCTWaiter.wait(for: [exp], timeout: 1.0)
        if result == XCTWaiter.Result.timedOut {
            completion()
        } else {
            XCTFail("Delay interrupted", file: file, line: line)
        }
    }
}
