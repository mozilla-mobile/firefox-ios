// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
import WebKit

final class AIOverviewsCookieHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Cookie.setURLProvider(.production)
        User.shared.aiOverviews = false
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.resetURLProvider()
    }

    func testMakeCookieWithAIOverviewsEnabled() {
        User.shared.aiOverviews = true

        let handler = AIOverviewsCookieHandler()
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create AI overviews cookie")
            return
        }

        XCTAssertEqual(cookie.name, "ECAIO")
        XCTAssertEqual(cookie.value, "true")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")
    }

    func testMakeCookieWithAIOverviewsDisabled() {
        User.shared.aiOverviews = false

        let handler = AIOverviewsCookieHandler()
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create AI overviews cookie")
            return
        }

        XCTAssertEqual(cookie.name, "ECAIO")
        XCTAssertEqual(cookie.value, "false")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")
    }

    func testReceivedMethodWithTrueValue() {
        let handler = AIOverviewsCookieHandler()
        let cookie = HTTPCookie(properties: [
            .name: "ECAIO",
            .domain: ".ecosia.org",
            .path: "/",
            .value: "true"
        ])!

        handler.received(cookie, in: MockHTTPCookieStore())
        XCTAssertTrue(User.shared.aiOverviews)
    }

    func testReceivedMethodWithFalseValue() {
        User.shared.aiOverviews = true // Start with true to verify it changes

        let handler = AIOverviewsCookieHandler()
        let cookie = HTTPCookie(properties: [
            .name: "ECAIO",
            .domain: ".ecosia.org",
            .path: "/",
            .value: "false"
        ])!

        handler.received(cookie, in: MockHTTPCookieStore())
        XCTAssertFalse(User.shared.aiOverviews)
    }

    func testReceivedMethodWithInvalidValue() {
        User.shared.aiOverviews = true // Start with true to verify it changes to false for invalid values

        let handler = AIOverviewsCookieHandler()
        let testValues = ["invalid", "1", "0", "", "yes", "no", "enabled", "disabled"]

        for value in testValues {
            let cookie = HTTPCookie(properties: [
                .name: "ECAIO",
                .domain: ".ecosia.org",
                .path: "/",
                .value: value
            ])!

            handler.received(cookie, in: MockHTTPCookieStore())
            XCTAssertFalse(User.shared.aiOverviews, "Invalid value '\(value)' should result in false")
        }
    }

    func testCookieNameIsCorrect() {
        let handler = AIOverviewsCookieHandler()
        XCTAssertEqual(handler.cookieName, "ECAIO")
    }

    // MARK: - Integration Tests

    func testAIOverviewsCookieInRequiredCookies() {
        User.shared.aiOverviews = true

        let cookies = Cookie.makeRequiredCookies(isPrivate: false)
        let aiOverviewsCookies = cookies.filter { $0.name == "ECAIO" }

        XCTAssertEqual(aiOverviewsCookies.count, 1)
        XCTAssertEqual(aiOverviewsCookies.first?.value, "true")
    }

    func testAIOverviewsCookieWorksInBothPrivateModes() {
        User.shared.aiOverviews = true

        let standardCookies = Cookie.makeRequiredCookies(isPrivate: false)
        let privateCookies = Cookie.makeRequiredCookies(isPrivate: true)

        let standardAICookie = standardCookies.first { $0.name == "ECAIO" }
        let privateAICookie = privateCookies.first { $0.name == "ECAIO" }

        XCTAssertNotNil(standardAICookie)
        XCTAssertNotNil(privateAICookie)
        XCTAssertEqual(standardAICookie?.value, "true")
        XCTAssertEqual(privateAICookie?.value, "true")
    }
}
