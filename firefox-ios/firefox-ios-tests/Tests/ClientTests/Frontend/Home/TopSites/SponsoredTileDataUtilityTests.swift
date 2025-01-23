// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Storage
@testable import Client

class SponsoredTileDataUtilityTests: XCTestCase {
    var subject: SponsoredTileDataUtilityInterface!

    // MARK: Stubs
    let searchEngine = OpenSearchEngine(engineID: "test",
                                        shortName: "test",
                                        image: UIImage(),
                                        searchTemplate: "http://firefox.com/find?q={searchTerm}",
                                        suggestTemplate: nil,
                                        isCustomEngine: false)
    let caseInsensitiveSearchEngine = OpenSearchEngine(engineID: "TesT",
                                                       shortName: "TesT",
                                                       image: UIImage(),
                                                       searchTemplate: "http://firefox.com/find?q={searchTerm}",
                                                       suggestTemplate: nil,
                                                       isCustomEngine: false)
    let tldIncludedSearchEngine = OpenSearchEngine(engineID: "Test.com",
                                                   shortName: "Test.com",
                                                   image: UIImage(),
                                                   searchTemplate: "http://firefox.com/find?q={searchTerm}",
                                                   suggestTemplate: nil,
                                                   isCustomEngine: false)

    override func setUp() {
        super.setUp()
        subject = SponsoredTileDataUtility()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests
    func testShouldAdd_doesntFilterSite() {
        let siteToNotFilter = Site.createBasicSite(url: "https://www.hello.com", title: "hello", isBookmarked: false)
        let shouldAdd = subject.shouldAdd(site: siteToNotFilter, with: searchEngine)
        XCTAssertTrue(shouldAdd)
    }

    func testShouldAdd_filterSite() {
        let siteToFilter = Site.createBasicSite(url: "https://www.test.com", title: "test", isBookmarked: false)
        let shouldAdd = subject.shouldAdd(site: siteToFilter, with: searchEngine)
        XCTAssertFalse(shouldAdd)
    }

    func testShouldAdd_filterSite_whenCaseInsentiveIsUsed() {
        let siteToFilter = Site.createBasicSite(url: "https://www.test.com", title: "test", isBookmarked: false)
        let shouldAdd = subject.shouldAdd(site: siteToFilter, with: caseInsensitiveSearchEngine)
        XCTAssertFalse(shouldAdd)
    }

    func testShouldAdd_filterSite_whenTldIsIncluded() {
        let siteToFilter = Site.createBasicSite(url: "https://www.test.com", title: "test", isBookmarked: false)
        let shouldAdd = subject.shouldAdd(site: siteToFilter, with: tldIncludedSearchEngine)
        XCTAssertFalse(shouldAdd)
    }
}
