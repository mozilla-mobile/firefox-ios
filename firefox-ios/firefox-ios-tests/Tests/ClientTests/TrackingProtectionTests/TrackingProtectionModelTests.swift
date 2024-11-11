// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TrackingProtectionModelTests: XCTestCase {
    func testClearCookiesAndSiteData() {
        let cookiesClearable = MockCookiesClearable()
        let siteDataClearable = MockSiteDataClearable()

        let trackingProtectionModel = TrackingProtectionModel(url: URL(string: "https://www.google.com")!,
                                                              displayTitle: "TitleTest",
                                                              connectionSecure: false,
                                                              globalETPIsEnabled: false,
                                                              contentBlockerStatus: .disabled,
                                                              contentBlockerStats: nil,
                                                              selectedTab: nil)
        trackingProtectionModel.clearCookiesAndSiteData(cookiesClearable: cookiesClearable,
                                                        siteDataClearable: siteDataClearable)
        XCTAssertNotNil(cookiesClearable.isSucceed)
        XCTAssertNotNil(siteDataClearable.isSucceed)
    }
}
