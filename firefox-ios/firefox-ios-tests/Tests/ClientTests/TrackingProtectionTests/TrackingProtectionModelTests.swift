// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class TrackingProtectionModelTests: XCTestCase {
    func testClearCookiesAndSiteData() {
        let cookiesClearable = MockCookiesClearable()
        let siteDataClearable = MockSiteDataClearable()
        let trackingProtectionModel = createSubject()

        _ = cookiesClearable.clear()
        _ = siteDataClearable.clear()
        trackingProtectionModel.clearCookiesAndSiteData()
        XCTAssertNotNil(cookiesClearable.isSucceed)
        XCTAssertNotNil(siteDataClearable.isSucceed)
    }

    func test_originalURL_onErrorPage_returnsFailingSiteURL() {
        let errorPageURL = URL(string: "http://localhost:6571/errorpages/NetError.html?url=https%3A%2F%2Ffailing.example.com")!
        let subject = createSubject(url: errorPageURL)

        XCTAssertEqual(subject.originalURL, URL(string: "https://failing.example.com"))
        XCTAssertEqual(subject.websiteTitle, "example.com")
    }

    func test_originalURL_onRegularURL_returnsSameURL() {
        let url = URL(string: "https://www.mozilla.org/en-US/firefox")!
        let subject = createSubject(url: url)

        XCTAssertEqual(subject.originalURL, url)
        XCTAssertEqual(subject.websiteTitle, "mozilla.org")
    }

    // MARK: - Helpers
    private func createSubject(
        url: URL = URL(string: "https://www.google.com")!,
        connectionSecure: Bool = false,
        globalETPIsEnabled: Bool = false,
        contentBlockerStatus: BlockerStatus = .disabled,
        contentBlockerStats: TPPageStats? = nil,
        selectedTab: Tab? = nil
    ) -> TrackingProtectionModel {
        let subject = TrackingProtectionModel(userDefaults: nil,
                                              url: url,
                                              connectionSecure: connectionSecure,
                                              globalETPIsEnabled: globalETPIsEnabled,
                                              contentBlockerStatus: contentBlockerStatus,
                                              contentBlockerStats: contentBlockerStats,
                                              selectedTab: selectedTab)
        trackForMemoryLeaks(subject)
        return subject
    }
}
