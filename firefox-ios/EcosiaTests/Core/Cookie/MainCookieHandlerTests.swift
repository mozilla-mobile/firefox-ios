// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
import WebKit

final class MainCookieHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Cookie.setURLProvider(.production)

        User.shared.searchCount = 0
        User.shared.id = nil
        User.shared.marketCode = .en_us
        User.shared.adultFilter = .off
        User.shared.autoComplete = true
        User.shared.personalized = false
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.resetURLProvider()
    }

    // MARK: - Standard Mode Tests

    func testStandardModeIncludesUserData() {
        User.shared.id = "test-user-id"
        User.shared.searchCount = 42

        let handler = MainCookieHandler(mode: .standard)
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create standard cookie")
            return
        }

        let values = parseMainCookieValue(cookie.value)
        XCTAssertEqual(values["cid"], "test-user-id")
        XCTAssertEqual(values["t"], "42")
    }

    func testStandardModeWithoutUserData() {
        User.shared.id = nil
        User.shared.searchCount = 0

        let handler = MainCookieHandler(mode: .standard)
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create standard cookie")
            return
        }

        let values = parseMainCookieValue(cookie.value)
        XCTAssertNil(values["cid"])
        XCTAssertEqual(values["t"], "0")
    }

    // MARK: - Incognito Mode Tests

    func testIncognitoModeExcludesUserData() {
        User.shared.id = "test-user-id"
        User.shared.searchCount = 42

        let handler = MainCookieHandler(mode: .incognito)
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create incognito cookie")
            return
        }

        let values = parseMainCookieValue(cookie.value)
        XCTAssertNil(values["cid"])
        XCTAssertNil(values["t"])
    }

    func testIncognitoModeIncludesBaseValues() {
        User.shared.marketCode = .de_de
        User.shared.adultFilter = .strict
        User.shared.autoComplete = false
        User.shared.personalized = true

        let handler = MainCookieHandler(mode: .incognito)
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create incognito cookie")
            return
        }

        let values = parseMainCookieValue(cookie.value)
        XCTAssertEqual(values["mc"], "de-de")
        XCTAssertEqual(values["f"], "y")
        XCTAssertEqual(values["as"], "0")
        XCTAssertEqual(values["pz"], "1")
    }

    // MARK: - Cookie Properties Tests

    func testCookieBasicProperties() {
        let handler = MainCookieHandler(mode: .standard)
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create cookie")
            return
        }

        XCTAssertEqual(cookie.name, "ECFG")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")
    }

    // MARK: - Base Values Tests

    func testBaseValuesWithUserSettings() {
        User.shared.marketCode = .es_cl
        User.shared.adultFilter = .moderate
        User.shared.autoComplete = false
        User.shared.personalized = true

        let handler = MainCookieHandler(mode: .standard)
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create cookie")
            return
        }

        let values = parseMainCookieValue(cookie.value)
        XCTAssertEqual(values["mc"], "es-cl")
        XCTAssertEqual(values["f"], "i")
        XCTAssertEqual(values["as"], "0")
        XCTAssertEqual(values["pz"], "1")
        XCTAssertEqual(values["l"], Language.current.rawValue)
        XCTAssertEqual(values["ma"], "1")
        XCTAssertEqual(values["mr"], "1")
        XCTAssertEqual(values["dt"], "mobile")
        XCTAssertEqual(values["fs"], "0")
        XCTAssertEqual(values["a"], "1")
    }

    // MARK: - Extract Value Tests

    func testReceivedMethodUpdatesUser() {
        let handler = MainCookieHandler()
        let cookie = HTTPCookie(properties: [
            .name: "ECFG",
            .domain: ".ecosia.org",
            .path: "/",
            .value: "cid=new-user-id:t=100:mc=fr-fr:f=y:as=1:pz=0"
        ])!

        handler.received(cookie, in: MockHTTPCookieStore())

        XCTAssertEqual(User.shared.id, "new-user-id")
        XCTAssertEqual(User.shared.searchCount, 100)
        XCTAssertEqual(User.shared.marketCode, .fr_fr)
        XCTAssertEqual(User.shared.adultFilter, .strict)
        XCTAssertTrue(User.shared.autoComplete)
        XCTAssertFalse(User.shared.personalized)
    }

    func testReceivedMethodWithInvalidValues() {
        User.shared.searchCount = 50
        User.shared.marketCode = .en_us
        User.shared.adultFilter = .off

        let handler = MainCookieHandler()
        let cookie = HTTPCookie(properties: [
            .name: "ECFG",
            .domain: ".ecosia.org",
            .path: "/",
            .value: "t=invalid:mc=invalid-market:f=invalid-filter"
        ])!

        handler.received(cookie, in: MockHTTPCookieStore())

        // Should maintain existing values when invalid data is received
        XCTAssertEqual(User.shared.searchCount, 50)
        XCTAssertEqual(User.shared.marketCode, .en_us)
        XCTAssertEqual(User.shared.adultFilter, .off)
    }

    func testReceivedMethodTreeCountOnlyIncreasesOrResetsToZero() {
        User.shared.searchCount = 50

        let handler = MainCookieHandler()

        // Should not decrease
        let decreaseCookie = HTTPCookie(properties: [
            .name: "ECFG",
            .domain: ".ecosia.org",
            .path: "/",
            .value: "t=30"
        ])!
        handler.received(decreaseCookie, in: MockHTTPCookieStore())
        XCTAssertEqual(User.shared.searchCount, 50)

        // Should increase
        let increaseCookie = HTTPCookie(properties: [
            .name: "ECFG",
            .domain: ".ecosia.org",
            .path: "/",
            .value: "t=75"
        ])!
        handler.received(increaseCookie, in: MockHTTPCookieStore())
        XCTAssertEqual(User.shared.searchCount, 75)

        // Should reset to zero
        let resetCookie = HTTPCookie(properties: [
            .name: "ECFG",
            .domain: ".ecosia.org",
            .path: "/",
            .value: "t=0"
        ])!
        handler.received(resetCookie, in: MockHTTPCookieStore())
        XCTAssertEqual(User.shared.searchCount, 0)
    }
}

// MARK: - Helper Methods
extension MainCookieHandlerTests {

    private func parseMainCookieValue(_ value: String) -> [String: String] {
        return value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
    }
}
