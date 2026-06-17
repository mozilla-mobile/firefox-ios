// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Shared

final class UserAgentTests: XCTestCase {
    func testGetUserAgentDesktop_withListedDomain_returnProperUserAgent() {
        let domains = CustomUserAgentConstant.customDesktopUAForDomain
        domains.forEach { domain, agent in
            XCTAssertEqual(agent, UserAgent.getUserAgent(domain: domain, platform: .Desktop))
        }
    }

    func testGetUserAgentMobile_withListedDomain_returnProperUserAgent() {
        let domains = CustomUserAgentConstant.customMobileUAForDomain
        domains.forEach { domain, agent in
            XCTAssertEqual(agent, UserAgent.getUserAgent(domain: domain, platform: .Mobile))
        }
    }

    func testIsGoogleDomain_withGoogleDomains_returnsTrue() {
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("google.com"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("www.google.com"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("mail.google.com"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("google.de"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("google.co.uk"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("https://www.google.com/search?q=firefox"))
    }

    func testIsGoogleDomain_withNonGoogleDomains_returnsFalse() {
        XCTAssertFalse(CustomUserAgentConstant.isGoogleDomain("notgoogle.com"))
        XCTAssertFalse(CustomUserAgentConstant.isGoogleDomain("google.example.com"))
        XCTAssertFalse(CustomUserAgentConstant.isGoogleDomain("youtube.com"))
        XCTAssertFalse(CustomUserAgentConstant.isGoogleDomain(""))
    }

    func testGetUserAgentDesktop_withGoogleDomain_returnsGoogleDesktopUserAgent() {
        let ua = UserAgent.getUserAgent(domain: "www.google.com", platform: .Desktop)

        XCTAssertEqual(ua, CustomUserAgentConstant.googleDesktopUserAgent)
        XCTAssertTrue(ua.contains("FxiOS/"))
    }

    func testGetUserAgentDesktop_withGoogleCcTLD_returnsGoogleDesktopUserAgent() {
        let ua = UserAgent.getUserAgent(domain: "google.co.uk", platform: .Desktop)

        XCTAssertEqual(ua, CustomUserAgentConstant.googleDesktopUserAgent)
        XCTAssertTrue(ua.contains("FxiOS/"))
    }

    func testGetUserAgentMobile_withGoogleDomain_returnsDefaultMobileUserAgent() {
        let ua = UserAgent.getUserAgent(domain: "www.google.com", platform: .Mobile)

        XCTAssertEqual(ua, UserAgent.mobileUserAgent())
    }

    func testGetUserAgentDesktop_withNonGoogleDomain_doesNotContainFxiOS() {
        let ua = UserAgent.getUserAgent(domain: "example.com", platform: .Desktop)

        XCTAssertEqual(ua, UserAgent.desktopUserAgent())
        XCTAssertFalse(ua.contains("FxiOS/"))
    }
}
