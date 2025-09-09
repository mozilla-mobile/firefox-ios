// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
import WebKit

final class CookieTests: XCTestCase {

    var urlProvider: URLProvider = .production

    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.setURLProvider(urlProvider)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.resetURLProvider()
    }

    // MARK: - Cookie Initialization Tests

    func testCookieInitFromHTTPCookie() {
        let validCookie = HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "test"])!
        let invalidDomainCookie = HTTPCookie(properties: [.name: "ECFG", .domain: ".google.com", .path: "/", .value: "test"])!
        let invalidNameCookie = HTTPCookie(properties: [.name: "INVALID", .domain: ".ecosia.org", .path: "/", .value: "test"])!

        XCTAssertNotNil(Cookie(validCookie))
        XCTAssertEqual(Cookie(validCookie), .main)

        XCTAssertNil(Cookie(invalidDomainCookie))
        XCTAssertNil(Cookie(invalidNameCookie))
    }

    func testCookieInitFromString() {
        XCTAssertEqual(Cookie("ECFG"), .main)
        XCTAssertEqual(Cookie("ECCC"), .consent)
        XCTAssertEqual(Cookie("ECUNL"), .unleash)
        XCTAssertEqual(Cookie("ECAIO"), .aiOverviews)
        XCTAssertNil(Cookie("INVALID"))
    }

    func testCookieName() {
        XCTAssertEqual(Cookie.main.name, "ECFG")
        XCTAssertEqual(Cookie.consent.name, "ECCC")
        XCTAssertEqual(Cookie.unleash.name, "ECUNL")
        XCTAssertEqual(Cookie.aiOverviews.name, "ECAIO")
    }

    // MARK: - Cookie Processing Tests

    func testReceivedCookiesProcessing() {
        // Setup initial state
        User.shared.searchCount = 0
        User.shared.cookieConsentValue = nil

        let cookies = [
            HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "t=100:cid=test-user"])!,
            HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "eampg"])!,
            HTTPCookie(properties: [.name: "ECUNL", .domain: ".ecosia.org", .path: "/", .value: "test-unleash-id"])!,
            HTTPCookie(properties: [.name: "ECAIO", .domain: ".ecosia.org", .path: "/", .value: "enabled"])!
        ]

        Cookie.received(cookies, in: MockHTTPCookieStore())

        // Verify effects through public observable state
        XCTAssertEqual(User.shared.searchCount, 100)
        XCTAssertEqual(User.shared.id, "test-user")
        XCTAssertEqual(User.shared.cookieConsentValue, "eampg")
    }

    func testReceivedCookiesIgnoresInvalidDomain() {
        User.shared.searchCount = 5

        let invalidDomainCookies = [
            HTTPCookie(properties: [.name: "ECFG", .domain: ".google.com", .path: "/", .value: "t=9999"])!,
            HTTPCookie(properties: [.name: "ECCC", .domain: ".bing.com", .path: "/", .value: "invalid"])!
        ]

        Cookie.received(invalidDomainCookies, in: MockHTTPCookieStore())

        // State should remain unchanged
        XCTAssertEqual(User.shared.searchCount, 5)
    }

    func testReceivedCookiesIgnoresInvalidNames() {
        User.shared.searchCount = 5

        let invalidNameCookies = [
            HTTPCookie(properties: [.name: "UNKNOWN", .domain: ".ecosia.org", .path: "/", .value: "t=9999"])!,
            HTTPCookie(properties: [.name: "INVALID", .domain: ".ecosia.org", .path: "/", .value: "test"])!
        ]

        Cookie.received(invalidNameCookies, in: MockHTTPCookieStore())

        // State should remain unchanged
        XCTAssertEqual(User.shared.searchCount, 5)
    }

    // MARK: - Cookie Creation Tests

    func testMakeRequiredCookies() async {
        // Setup prerequisites
        _ = try? await Unleash.start(appVersion: "1.0.0")
        User.shared.cookieConsentValue = "eampg"

        let standardCookies = Cookie.makeRequiredCookies(isPrivate: false)
        let privateCookies = Cookie.makeRequiredCookies(isPrivate: true)

        // Verify all expected cookie types are present
        let expectedCookieNames = [Cookie.main.name, Cookie.consent.name, Cookie.unleash.name, Cookie.aiOverviews.name]

        for cookieName in expectedCookieNames {
            XCTAssertTrue(standardCookies.contains { $0.name == cookieName }, "Standard cookies missing \(cookieName)")
            XCTAssertTrue(privateCookies.contains { $0.name == cookieName }, "Private cookies missing \(cookieName)")
        }

        // Verify domains are correct
        for cookie in standardCookies + privateCookies {
            XCTAssertEqual(cookie.domain, ".ecosia.org")
        }
    }

    func testMakeSearchSettingsObserverCookies() async {
        // Setup prerequisites
        _ = try? await Unleash.start(appVersion: "1.0.0")
        User.shared.cookieConsentValue = "eampg"

        let standardCookies = Cookie.makeSearchSettingsObserverCookies(isPrivate: false)
        let privateCookies = Cookie.makeSearchSettingsObserverCookies(isPrivate: true)

        // Should only contain main and aiOverviews cookies
        let expectedCookieNames = [Cookie.main.name, Cookie.aiOverviews.name]
        let unexpectedCookieNames = [Cookie.consent.name, Cookie.unleash.name]

        for cookieName in expectedCookieNames {
            XCTAssertTrue(standardCookies.contains { $0.name == cookieName }, "Standard search settings cookies missing \(cookieName)")
            XCTAssertTrue(privateCookies.contains { $0.name == cookieName }, "Private search settings cookies missing \(cookieName)")
        }

        for cookieName in unexpectedCookieNames {
            XCTAssertFalse(standardCookies.contains { $0.name == cookieName }, "Standard search settings cookies should not contain \(cookieName)")
            XCTAssertFalse(privateCookies.contains { $0.name == cookieName }, "Private search settings cookies should not contain \(cookieName)")
        }

        // Verify domains are correct
        for cookie in standardCookies + privateCookies {
            XCTAssertEqual(cookie.domain, ".ecosia.org")
        }
    }
}

// MARK: - Helper Methods
extension CookieTests {

    /// Helper method to parse main cookie value into dictionary
    private func parseMainCookieValue(_ value: String) -> [String: String] {
        return value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
    }
}
