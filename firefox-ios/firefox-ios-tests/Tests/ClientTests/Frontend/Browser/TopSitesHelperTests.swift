// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest
import SiteImageView

@testable import Client

class TopSitesHelperTests: XCTestCase {
    private let faviconResource: SiteResource = .remoteURL(url: URL(string: "https://mozilla.org/favicon.ico")!)
    private var profile: MockProfile!

    private func deleteDatabases() {
        do {
            try profile.files.remove("TopSitesHelperTests.db")
        } catch {}
    }

    override func tearDown() {
        self.deleteDatabases()
        self.profile = nil
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        self.profile = MockProfile(databasePrefix: "TopSitesHelperTests")
        // Just in case tearDown didn't run or succeed last time!
        self.deleteDatabases()
    }

    func createSubject(
        mockPinnedSites: Bool,
        frecencySitesToAdd: [Site] = [],
        pinnedSites: [PinnedSite] = []
    ) -> TopSitesProviderImplementation {
        let pinnedSiteFetcher: PinnedSites
        if mockPinnedSites {
            let mock = PinnedSitesMock()
            let cursor = SiteCursorMock()
            cursor.sites = pinnedSites
            mock.pinnedResponse = Maybe(success: cursor)
            pinnedSiteFetcher = mock
        } else {
            pinnedSiteFetcher = profile.pinnedSites
        }
        let places = profile.places
        addFrecencySitesToPlaces(frecencySitesToAdd, places: places)

        let subject = TopSitesProviderImplementation(placesFetcher: places,
                                                     pinnedSiteFetcher: pinnedSiteFetcher,
                                                     prefs: profile.prefs)
        return subject
    }

    func testGetTopSites_withError_completesWithZeroSites() {
        let expectation = expectation(description: "Expect top sites to be fetched")
        let subject = createSubject(mockPinnedSites: false)

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
        let subject = createSubject(mockPinnedSites: true, pinnedSites: defaultPinnedSites)

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
        let subject = createSubject(
            mockPinnedSites: true,
            frecencySitesToAdd: defaultFrecencySites
        )

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
        let sites = defaultFrecencySites + [Site(url: "https://frecencySponsoredSite.com/page?mfadid=adm",
                                                 title: "A sponsored title")]
        let subject = createSubject(mockPinnedSites: true, frecencySitesToAdd: sites)

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
        let sites = defaultFrecencySites + defaultFrecencySites

        let subject = createSubject(mockPinnedSites: true, frecencySitesToAdd: sites)

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
        let sites = [Site(url: "https://facebook.com", title: "Facebook")]
        let subject = createSubject(mockPinnedSites: true, frecencySitesToAdd: sites)

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
        let subject = createSubject(
            mockPinnedSites: true,
            pinnedSites: [PinnedSite(
                site: Site(url: "https://facebook.com", title: "Facebook"),
                faviconResource: faviconResource
            )]
        )

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
        return [
            PinnedSite(
                site: Site(url: "https://apinnedsite.com/", title: "a pinned site title"),
                faviconResource: faviconResource
            ),
            PinnedSite(
                site: Site(url: "https://apinnedsite2.com/", title: "a pinned site title2"),
                faviconResource: faviconResource
            )
        ]
    }

    var defaultFrecencySites: [Site] {
        return [Site(url: "https://frecencySite.com/1/", title: "a frecency site"),
                Site(url: "https://anotherWebSite.com/2/", title: "Another website")]
    }

    func addFrecencySitesToPlaces(_ sites: [Site], places: RustPlaces) {
        for site in sites {
            let visit = VisitObservation(url: site.url, title: site.title, visitType: .link)
            // force synchronous call
            _ = places.applyObservation(visitObservation: visit).value
        }
    }
}

// MARK: - SiteCursorMock
class SiteCursorMock: Cursor<Site> {
    var sites = [Site]()
    override func asArray() -> [Site] {
        return sites
    }
}

// MARK: - MockablePinnedSites
class PinnedSitesMock: MockablePinnedSites {
    class Error: MaybeErrorType {
        var description = "Error"
    }

    var pinnedResponse: Maybe<Cursor<Site>> = Maybe(failure: Error())
    override func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>> {
        let deferred = Deferred<Maybe<Cursor<Site>>>()
        deferred.fill(pinnedResponse)
        return deferred
    }
}
