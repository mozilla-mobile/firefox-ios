// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
import WebKit

final class ConsentCookieHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Cookie.setURLProvider(.production)

        User.shared.cookieConsentValue = nil
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.resetURLProvider()
    }

    func testMakeCookieWithConsentValue() {
        User.shared.cookieConsentValue = "eampg"

        let handler = ConsentCookieHandler()
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create consent cookie")
            return
        }

        XCTAssertEqual(cookie.name, "ECCC")
        XCTAssertEqual(cookie.value, "eampg")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")
    }

    func testMakeCookieWithoutConsentValue() {
        User.shared.cookieConsentValue = nil

        let handler = ConsentCookieHandler()
        let cookie = handler.makeCookie()

        XCTAssertNil(cookie, "Cookie should not be created when consent value is nil")
    }

    func testMakeCookieWithEmptyConsentValue() {
        User.shared.cookieConsentValue = ""

        let handler = ConsentCookieHandler()
        let cookie = handler.makeCookie()

        XCTAssertEqual(cookie?.value, "")
    }

    func testReceivedMethodWithVariousConsentStrings() {
        let handler = ConsentCookieHandler()
        let testValues = [
            "e",
            "eampg",
            "ea",
            "eamp",
            "custom123"
        ]

        for value in testValues {
            let cookie = HTTPCookie(properties: [
                .name: "ECCC",
                .domain: ".ecosia.org",
                .path: "/",
                .value: value
            ])!

            handler.received(cookie, in: MockHTTPCookieStore())
            XCTAssertEqual(User.shared.cookieConsentValue, value)
        }
    }

    func testCookieNameIsCorrect() {
        let handler = ConsentCookieHandler()
        XCTAssertEqual(handler.cookieName, "ECCC")
    }

    // MARK: - Integration Tests

    func testConsentCookieInRequiredCookies() {
        User.shared.cookieConsentValue = "eampg"

        let cookies = Cookie.makeRequiredCookies(isPrivate: false)
        let consentCookies = cookies.filter { $0.name == "ECCC" }

        XCTAssertEqual(consentCookies.count, 1)
        XCTAssertEqual(consentCookies.first?.value, "eampg")
    }

    func testConsentCookieNotInRequiredCookiesWhenNil() {
        User.shared.cookieConsentValue = nil

        let cookies = Cookie.makeRequiredCookies(isPrivate: false)
        let consentCookies = cookies.filter { $0.name == "ECCC" }

        XCTAssertEqual(consentCookies.count, 0)
    }

    // MARK: - Analytics Consent Detection Tests

    func testAnalyticsConsentDetection() {
        let handler = ConsentCookieHandler()

        // Test values that should indicate analytics consent
        let eampgCookie = HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "eampg"])!
        handler.received(eampgCookie, in: MockHTTPCookieStore())
        XCTAssertTrue(User.shared.hasAnalyticsCookieConsent)

        let eampCookie = HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "eamp"])!
        handler.received(eampCookie, in: MockHTTPCookieStore())
        XCTAssertTrue(User.shared.hasAnalyticsCookieConsent)

        let eaCookie = HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "ea"])!
        handler.received(eaCookie, in: MockHTTPCookieStore())
        XCTAssertTrue(User.shared.hasAnalyticsCookieConsent)

        // Test values that should NOT indicate analytics consent
        let eCookie = HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "e"])!
        handler.received(eCookie, in: MockHTTPCookieStore())
        XCTAssertFalse(User.shared.hasAnalyticsCookieConsent)

        let empgCookie = HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "empg"])!
        handler.received(empgCookie, in: MockHTTPCookieStore())
        XCTAssertFalse(User.shared.hasAnalyticsCookieConsent)

        let emptyCookie = HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: ""])!
        handler.received(emptyCookie, in: MockHTTPCookieStore())
        XCTAssertFalse(User.shared.hasAnalyticsCookieConsent)
    }
}
