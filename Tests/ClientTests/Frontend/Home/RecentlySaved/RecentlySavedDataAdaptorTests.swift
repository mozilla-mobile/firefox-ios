// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest

class RecentlySavedDataAdaptorTests: XCTestCase {

    var subject: RecentlySavedDataAdaptor!
    var mockSiteImageHelper: SiteImageHelperMock!
    var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        mockSiteImageHelper = SiteImageHelperMock()
        mockProfile = MockProfile()
        subject = RecentlySavedDataAdaptorImplementation(siteImageHelper: mockSiteImageHelper,
                                                         profile: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
        mockSiteImageHelper = nil
        mockProfile = nil
        subject = nil
    }

    // MARK: - getRecentlySavedData

    // Test getRecentlySavedData with both bookmarks and reading items
    func testGetRecentlySavedData_withBookmarksAndReadingItems() {
        let 
    }
}
