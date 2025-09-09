// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
import WebKit

final class UnleashCookieHandlerTests: XCTestCase {

    var mockCookieStore: MockHTTPCookieStore!

    override func setUp() {
        super.setUp()
        Cookie.setURLProvider(.production)
        MockUnleash.setLoaded(true)

        mockCookieStore = MockHTTPCookieStore()
    }

    override func tearDown() {
        super.tearDown()
        Cookie.resetURLProvider()
        MockUnleash.reset()
    }

    func testNoCookieWithoutLoadingUnleash() {
        MockUnleash.setLoaded(false)
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)
        XCTAssertNil(handler.makeCookie())
    }

    func testMakeCookieCreatesValidCookie() {
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create unleash cookie when mock is loaded")
            return
        }

        XCTAssertEqual(cookie.name, "ECUNL")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")

        XCTAssertFalse(cookie.value.isEmpty)
        XCTAssertEqual(cookie.value, cookie.value.lowercased())
    }

    func testMultipleCookiesHaveSameId() {
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)

        let cookie1 = handler.makeCookie()
        let cookie2 = handler.makeCookie()

        XCTAssertNotNil(cookie1)
        XCTAssertNotNil(cookie2)
        XCTAssertEqual(cookie1?.value, cookie2?.value)
    }

    // MARK: - Received Value Tests

    func testReceivedMethodOverridesCookieButOnlyIfDifferent() async {
        // First case: Received random web value but keep native one
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)
        guard let existingCookie = handler.makeCookie() else {
            XCTFail("Failed to create unleash cookie when mock is loaded")
            return
        }
        await mockCookieStore.setCookie(existingCookie)

        let webCookie = HTTPCookie(properties: [.name: "ECUNL", .domain: ".ecosia.org", .path: "/", .value: "some-random-value"])!
        handler.received(webCookie, in: mockCookieStore)
        try? await Task.sleep(nanoseconds: 100_000_000) // Make sure aync setCookie inside received is done

        var cookies = await mockCookieStore.allCookies()
        var receivedWebCookie = cookies.first { $0.name == "ECUNL" }
        XCTAssertEqual(receivedWebCookie?.value, existingCookie.value)

        // Second case: Received native web value so did not change cookie store
        let fakeCookie = HTTPCookie(properties: [.name: "ECUNL", .domain: ".ecosia.org", .path: "/", .value: "some-unchanged-value"])!
        await mockCookieStore.setCookie(fakeCookie)

        guard let nativeIdCookie = handler.makeCookie() else {
            XCTFail("Failed to create unleash cookie when mock is loaded")
            return
        }
        handler.received(nativeIdCookie, in: mockCookieStore)
        try? await Task.sleep(nanoseconds: 100_000_000) // Make sure aync setCookie inside received is done

        cookies = await mockCookieStore.allCookies()
        receivedWebCookie = cookies.first { $0.name == "ECUNL" }
        XCTAssertEqual(receivedWebCookie?.value, fakeCookie.value, "When received cookie is the same as the native one, no cookie should be changed on store")
    }

    // MARK: - Cookie Properties Tests

    func testCookieNameIsCorrect() {
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)
        XCTAssertEqual(handler.cookieName, "ECUNL")
    }
}

// MARK: - Integration Tests

extension UnleashCookieHandlerTests {

    func testMakeCookieCreatesValidCookieAfterUnleashStart() async {
        _ = try? await Unleash.start(appVersion: "1.0.0")

        let handler = UnleashCookieHandler()
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create unleash cookie")
            return
        }

        XCTAssertEqual(cookie.name, "ECUNL")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")

        XCTAssertFalse(cookie.value.isEmpty)
        XCTAssertEqual(cookie.value, cookie.value.lowercased())
    }

    func testMultipleCookiesHaveSameIdAcrossSessions() async {
        // Simulate Unleash being loaded
        _ = try? await Unleash.start(appVersion: "1.0.0")

        let handler = UnleashCookieHandler()

        let cookie1 = handler.makeCookie()
        XCTAssertNotNil(cookie1)

        // Force unloaded state and start again
        Unleash.clearInstanceModel()
        _ = try? await Unleash.start(appVersion: "1.0.0")

        let cookie2 = handler.makeCookie()

        XCTAssertNotNil(cookie2)
        XCTAssertEqual(cookie1?.value, cookie2?.value)
    }
}
