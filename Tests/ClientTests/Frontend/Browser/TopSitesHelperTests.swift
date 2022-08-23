// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Storage
import Shared
import XCTest

class TopSitesHelperTests: XCTestCase {

    func testGetTopSites_withError_completesWithZeroSites() {
        let expectation = expectation(description: "Expect top sites to be fetched")

        let subject = TopSitesProviderImplementation(browserHistoryFetcher: BrowserHistoryMock(),
                                                     prefs: MockProfilePrefs())

        subject.getTopSites { sites in
            guard let sites = sites else {
                XCTFail("Has no sites")
                return
            }
            XCTAssertEqual(sites.count, 5, "Contains 5 default sites")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetTopSites_withFrecencyError_completesWithPinnedSites() {
        let expectation = expectation(description: "Expect top sites to be fetched")
        let mockHistory = BrowserHistoryMock()

        let cursor = SiteCursorMock()
        cursor.sites = defaultPinnedSites
        mockHistory.pinnedResponse = Maybe(success: cursor)

        let subject = TopSitesProviderImplementation(browserHistoryFetcher: mockHistory,
                                                     prefs: MockProfilePrefs())

        subject.getTopSites { sites in
            guard let sites = sites else {
                XCTFail("Has no sites")
                return
            }
            XCTAssertEqual(sites.count, 7, "Contains 5 default sites and two pinned sites")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetTopSites_withPinnedSitesError_completesWithFrecencySites() {
        let expectation = expectation(description: "Expect top sites to be fetched")
        let mockHistory = BrowserHistoryMock()

        let cursor = SiteCursorMock()
        cursor.sites = defaultFrecencySites
        mockHistory.frecencyResponse = Maybe(success: cursor)

        let subject = TopSitesProviderImplementation(browserHistoryFetcher: mockHistory,
                                                     prefs: MockProfilePrefs())

        subject.getTopSites { sites in
            guard let sites = sites else {
                XCTFail("Has no sites")
                return
            }
            XCTAssertEqual(sites.count, 7, "Contains 5 default sites and 2 frecency sites")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetTopSites_filterHideSearchParam() {
        let expectation = expectation(description: "Expect top sites to be fetched")
        let mockHistory = BrowserHistoryMock()

        let cursor = SiteCursorMock()
        let sites = defaultFrecencySites + [Site(url: "https://frecencySponsoredSite.com/page?mfadid=adm",
                                                 title: "A sponsored title")]
        cursor.sites = sites
        mockHistory.frecencyResponse = Maybe(success: cursor)

        let subject = TopSitesProviderImplementation(browserHistoryFetcher: mockHistory,
                                                     prefs: MockProfilePrefs())

        subject.getTopSites { sites in
            guard let sites = sites else {
                XCTFail("Has no sites")
                return
            }
            XCTAssertEqual(sites.count, 7, "Contains 5 default sites and 2 frecency sites, no sponsored urls")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetTopSites_removesDuplicates() {
        let expectation = expectation(description: "Expect top sites to be fetched")
        let mockHistory = BrowserHistoryMock()

        let cursor = SiteCursorMock()
        let sites = defaultFrecencySites + defaultFrecencySites
        cursor.sites = sites
        mockHistory.frecencyResponse = Maybe(success: cursor)

        let subject = TopSitesProviderImplementation(browserHistoryFetcher: mockHistory,
                                                     prefs: MockProfilePrefs())

        subject.getTopSites { sites in
            guard let sites = sites else {
                XCTFail("Has no sites")
                return
            }
            XCTAssertEqual(sites.count, 7, "Contains 5 default sites and 2 frecency sites, no frecency duplicates")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetTopSites_defaultSitesHavePrecedenceOverFrecency() {
        let expectation = expectation(description: "Expect top sites to be fetched")
        let mockHistory = BrowserHistoryMock()

        let cursor = SiteCursorMock()
        cursor.sites = [Site(url: "https://facebook.com", title: "Facebook")]
        mockHistory.frecencyResponse = Maybe(success: cursor)

        let subject = TopSitesProviderImplementation(browserHistoryFetcher: mockHistory,
                                                     prefs: MockProfilePrefs())

        subject.getTopSites { sites in
            guard let sites = sites else {
                XCTFail("Has no sites")
                return
            }
            XCTAssertEqual(sites.count, 5, "Contains only 5 default sites, no duplicates of defaults sites")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetTopSites_pinnedSitesHasPrecedenceOverDefaultTopSites() {
        let expectation = expectation(description: "Expect top sites to be fetched")
        let mockHistory = BrowserHistoryMock()

        let cursor = SiteCursorMock()
        cursor.sites = [PinnedSite(site: Site(url: "https://facebook.com", title: "Facebook"))]
        mockHistory.pinnedResponse = Maybe(success: cursor)

        let subject = TopSitesProviderImplementation(browserHistoryFetcher: mockHistory,
                                                     prefs: MockProfilePrefs())

        subject.getTopSites { sites in
            guard let sites = sites else {
                XCTFail("Has no sites")
                return
            }
            XCTAssertEqual(sites.count, 5, "Contains only 4 default sites, and "
                           + "one pinned site that replaced the default site")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}

// MARK: - Tests data
extension TopSitesHelperTests {

    var defaultPinnedSites: [PinnedSite] {
        return [PinnedSite(site: Site(url: "https://apinnedsite.com/", title: "a pinned site title")),
                PinnedSite(site: Site(url: "https://apinnedsite2.com/", title: "a pinned site title2"))]
    }

    var defaultFrecencySites: [Site] {
        return [Site(url: "https://frecencySite.com/1/", title: "a frecency site"),
                Site(url: "https://anotherWebSite.com/2/", title: "Another website")]
    }
}

// MARK: - SiteCursorMock
class SiteCursorMock: Cursor<Site> {

    var sites = [Site]()
    override func asArray() -> [Site] {
        return sites
    }
}

// MARK: - MockableHistory
class BrowserHistoryMock: MockableHistory {

    class Error: MaybeErrorType {
        var description = "Error"
    }

    var frecencyResponse: Maybe<Cursor<Site>> = Maybe(failure: Error())
    override func getTopSitesWithLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        let deferred = Deferred<Maybe<Cursor<Site>>>()
        deferred.fill(frecencyResponse)
        return deferred
    }

    var pinnedResponse: Maybe<Cursor<Site>> = Maybe(failure: Error())
    override func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>> {
        let deferred = Deferred<Maybe<Cursor<Site>>>()
        deferred.fill(pinnedResponse)
        return deferred
    }
}
