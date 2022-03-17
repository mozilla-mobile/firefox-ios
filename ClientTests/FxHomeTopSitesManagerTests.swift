// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared
import Storage
import XCTest

class FxHomeTopSitesManagerTests: XCTestCase {

    private var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "FxHomeTopSitesManagerTests")
        profile._reopen()
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        profile = nil
    }

    func testEmptyData_whenNotLoaded() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertEqual(manager.hasData, false)
        XCTAssertEqual(manager.siteCount, 0)
    }

    func testEmptyData_getSites() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertNil(manager.getSite(index: 0))
        XCTAssertNil(manager.getSite(index: -1))
        XCTAssertNil(manager.getSite(index: 10))
        XCTAssertNil(manager.getSiteDetail(index: 0))
        XCTAssertNil(manager.getSiteDetail(index: -1))
        XCTAssertNil(manager.getSiteDetail(index: 10))
    }

    func testNumberOfRows_default() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertEqual(manager.numberOfRows, 2)
    }

    func testNumberOfRows_userChangedDefault() {
        profile.prefs.setInt(3, forKey: PrefsKeys.NumberOfTopSiteRows)
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertEqual(manager.numberOfRows, 3)
    }

    func testLoadTopSitesData() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.hasData, true)
            XCTAssertEqual(manager.siteCount, 10)
        }
    }

    func testLoadTopSitesData_whenGetSites() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertNotNil(manager.getSite(index: 0))
            XCTAssertNil(manager.getSite(index: -1))
            XCTAssertNotNil(manager.getSite(index: 10))
            XCTAssertNil(manager.getSite(index: 12))

            XCTAssertNotNil(manager.getSiteDetail(index: 0))
            XCTAssertNil(manager.getSiteDetail(index: -1))
            XCTAssertNotNil(manager.getSiteDetail(index: 10))
            XCTAssertNil(manager.getSiteDetail(index: 12))
        }
    }

    // MARK: Google top site

    func testCalculateTopSitesData_hasGoogleTopSite() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
        }
    }

    func testCalculateTopSitesData_hasNotGoogleTopSite() {
        let manager = createManager(addPinnedSite: true)

        // We test that having more pinned than available tiles, google tile isn't put in
        testLoadData(manager: manager, numberOfTilesPerRow: 1) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, false)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, false)
        }
    }

    // MARK: Pinned site

    func testCalculateTopSitesData_pinnedSites() {
        let manager = createManager(addPinnedSite: true)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.hasData, true)
            XCTAssertEqual(manager.siteCount, 13)
            XCTAssertEqual(manager.getSite(index: 0)?.isPinned, true)
        }
    }
}

// MARK: Helper methods
extension FxHomeTopSitesManagerTests {
    func createManager(addPinnedSite: Bool = false) -> FxHomeTopSitesManager {
        let topSitesManager = FxHomeTopSitesManager(profile: profile)
        let historyStub = TopSiteHistoryManagerStub(profile: profile)
        historyStub.addThreePinnedSite = addPinnedSite
        topSitesManager.topSiteHistoryManager = historyStub
        return topSitesManager
    }

    func testLoadData(manager: FxHomeTopSitesManager, numberOfTilesPerRow: Int, completion: @escaping () -> Void) {
        let expectation = self.expectation(description: "Top sites data should be loaded")

        manager.loadTopSitesData {
            manager.calculateTopSiteData(numberOfTilesPerRow: numberOfTilesPerRow)
            completion()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }
}

// MARK: TopSiteHistoryManagerStub
class TopSiteHistoryManagerStub: TopSiteHistoryManager {
    override func getTopSites(completion: @escaping ([Site]) -> Void) {
        completion(createHistorySites())
    }

    var siteCount = 10
    var addThreePinnedSite: Bool = false

    func createHistorySites() -> [Site] {
        var sites = [Site]()

        if addThreePinnedSite {
            (0..<3).forEach {
                let site = Site(url: "www.a-pinned-url-\($0).com", title: "A pinned title\($0)")
                sites.append(PinnedSite(site: site))
            }
        }

        (0..<siteCount).forEach {
            sites.append(Site(url: "www.a-url-\($0).com", title: "A title\($0)"))
        }

        return sites
    }
}
