// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage

@testable import Client

class HistoryPanelViewModelTests: XCTestCase {

    var sut: HistoryPanelViewModel!
    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "HistoryPanelViewModelTest")
        profile._reopen()
        sut = HistoryPanelViewModel(profile: profile)
    }

    override func tearDown() {
        super.tearDown()

        clear(profile.history)
        profile._shutdown()
        profile = nil
    }

    func testFetchHistory_WithResults() throws {
        let expectation = self.expectation(description: "Wait for search history")

        addSiteVisit(profile.history, url: "http://amazon.com/", title: "Amazon")
        addSiteVisit(profile.history, url: "http://mozilla.org/", title: "Mozilla internet")
        addSiteVisit(profile.history, url: "http://mozilla.dev.org/", title: "Internet dev")
        addSiteVisit(profile.history, url: "https://apple.com/", title: "Apple")

        sut.reloadData { success in
            XCTAssertTrue(hasResults)
            XCTAssertEqual(self.sut.searchResultSites.count, 2)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testPerformSearch_ForNoResults() throws {
        let expectation = self.expectation(description: "Wait for search history")

        sut.performSearch(term: "moz") { hasResults in
            XCTAssertFalse(hasResults)
            XCTAssertEqual(self.sut.searchResultSites.count, 0)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testPerformSearch_WithResults() throws {
        let expectation = self.expectation(description: "Wait for search history")

        addSiteVisit(profile.history, url: "http://amazon.com/", title: "Amazon")
        addSiteVisit(profile.history, url: "http://mozilla.org/", title: "Mozilla internet")
        addSiteVisit(profile.history, url: "http://mozilla.dev.org/", title: "Internet dev")
        addSiteVisit(profile.history, url: "https://apple.com/", title: "Apple")

        sut.performSearch(term: "moz") { hasResults in
            XCTAssertTrue(hasResults)
            XCTAssertEqual(self.sut.searchResultSites.count, 2)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    // MARK: -
    private func addSiteVisit(_ history: BrowserHistory, url: String, title: String, s: Bool = true) {
        let site = Site(url: url, title: title)
        let visit = SiteVisit(site: site, date: Date.nowMicroseconds())
        XCTAssertEqual(s, history.addLocalVisit(visit).value.isSuccess, "Site added: \(url).")
    }

    private func clear(_ history: BrowserHistory) {
        XCTAssertTrue(history.clearHistory().value.isSuccess, "History cleared.")
    }
}
