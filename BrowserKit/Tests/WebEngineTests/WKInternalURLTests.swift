// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class WKInternalURLTests: XCTestCase {
    // MARK: Internal URL creation
    func testInternalURLCreationGivenUnvalidURLThenNotCreated() {
        let url = URL(string: "https://example.com")!

        let subject = WKInternalURL(url)

        XCTAssertNil(subject)
    }

    func testInternalURLCreationGivenTestURLThenNotCreated() {
        let url = URL(string: "http://localhost:6571/test-fixture/find-in-page.html")!

        let subject = WKInternalURL(url)

        XCTAssertNil(subject)
    }

    func testInternalURLCreationGivenLocalHostURLThenNotCreated() {
        let url = URL(string: "http://localhost:6571/reader-mode-page?url=https:example.com")!

        let subject = WKInternalURL(url)

        XCTAssertNotNil(subject)
    }

    func testInternalURLCreationGivenInternalSchemeURLThenNotCreated() {
        let url = URL(string: "internal://local/about/home")!

        let subject = WKInternalURL(url)

        XCTAssertNotNil(subject)
    }

    // MARK: Authorization

    func testInternalURLIsAuthorizedWhenNotAutorizedThenNotAuthorized() {
        let url = URL(string: "internal://local/about/home")!

        let subject = WKInternalURL(url)!

        XCTAssertFalse(subject.isAuthorized)
    }

    func testInternalURLIsAuthorizedWhenAutorizedThenAuthorized() {
        let url = URL(string: "internal://local/about/home")!

        let subject = WKInternalURL(url)!
        subject.authorize()

        XCTAssertTrue(subject.isAuthorized)
    }

    func testInternalURLIsAuthorizedWhenWrongUUIDExistsThenNotAuthorized() {
        let url = URL(string: "internal://local/about/home?uuidkey=AAAAA")!

        let subject = WKInternalURL(url)!
        subject.authorize()

        XCTAssertFalse(subject.isAuthorized)
    }

    func testInternalURLIsAuthorizedWhenStripedThenNotAuthorized() {
        let url = URL(string: "internal://local/about/home")!

        let subject = WKInternalURL(url)!
        subject.authorize()
        subject.stripAuthorization()

        XCTAssertFalse(subject.isAuthorized)
    }

    // MARK: Original URL from Error page

    func testOriginalURLFromErrorPageWhenInternalErrorPageThenErrorPageURL() {
        let expectedURL = "www.example.com"
        let url = URL(string: "internal://local/errorpage?url=\(expectedURL)")!

        let subject = WKInternalURL(url)
        XCTAssertEqual(subject?.originalURLFromErrorPage, URL(string: expectedURL)!)
    }

    func testOriginalURLFromErrorPageWhenNoParamThenNil() {
        let url = URL(string: "internal://local/errorpage")!

        let subject = WKInternalURL(url)
        XCTAssertNil(subject?.originalURLFromErrorPage)
    }

    func testOriginalURLFromErrorPageWhenEmptyParamURLHasNoParamThenNil() {
        let url = URL(string: "internal://local/errorpage?url=")!

        let subject = WKInternalURL(url)
        XCTAssertNil(subject?.originalURLFromErrorPage)
    }
}
