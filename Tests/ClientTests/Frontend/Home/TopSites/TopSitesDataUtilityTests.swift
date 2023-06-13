// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Storage
@testable import Client

class TopSitesDataAdapterTests: XCTestCase {
    var topSitesDataUtility: TopSitesDataUtilityInterface!

    // MARK: Stubs
    let nonFilterableSites: [Site] = [
        Site(url: "https://www.hello.com", title: "hello", bookmarked: false, guid: nil),
        Site(url: "https://www.another.com", title: "another", bookmarked: false, guid: nil),
        Site(url: "https://www.site.com", title: "site", bookmarked: false, guid: nil),
    ]
    let filterableSites: [Site] = [
        Site(url: "https://www.test.com", title: "test", bookmarked: false, guid: nil),
        Site(url: "https://www.another.com", title: "another", bookmarked: false, guid: nil),
        Site(url: "https://www.site.com", title: "site", bookmarked: false, guid: nil),
    ]
    let searchEngine = OpenSearchEngine(engineID: "test",
                                        shortName: "test",
                                        image: UIImage(),
                                        searchTemplate: "http://firefox.com/find?q={searchTerm}",
                                        suggestTemplate: nil,
                                        isCustomEngine: false)

    override func setUp() {
        super.setUp()
        topSitesDataUtility = TopSitesDataUtility()
    }

    override func tearDown() {
        super.tearDown()
        topSitesDataUtility = nil
    }

    // MARK: Tests
    func testSitesNotFiltered() {
        let sites = topSitesDataUtility.removeSiteMatching(searchEngine, from: nonFilterableSites)
        XCTAssertEqual(sites.count, 3)
    }

    func testSitesAreFiltered() {
        let sites = topSitesDataUtility.removeSiteMatching(searchEngine, from: filterableSites)
        XCTAssertEqual(sites.count, 2)
    }
}
