// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class CookieTests: XCTestCase {

    var urlProvider: URLProvider = .production

    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    func testDefaults() {
        XCTAssertEqual("ECFG", Cookie.makeStandardCookie(urlProvider).name)
        XCTAssertEqual(".ecosia.org", Cookie.makeStandardCookie(urlProvider).domain)
        XCTAssertEqual("/", Cookie.makeStandardCookie(urlProvider).path)
    }

    func testIncognitoValuesNoPersonalData() {
        User.shared.searchCount = 1234
        User.shared.id = "neverland"

        let incognitoDict = Cookie.makeIncognitoCookie(urlProvider).value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
        XCTAssertNil(incognitoDict["cid"])
        XCTAssertNil(incognitoDict["t"])

        let standardDict = Cookie.makeStandardCookie(urlProvider).value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
        XCTAssertNotNil(standardDict["cid"])
        XCTAssertNotNil(standardDict["t"])
    }

    func testMakeConsentCookieReturnsCookieWhenValueStoredInUser() {
        User.shared.cookieConsentValue = "eampg"

        XCTAssertNotNil(Cookie.makeConsentCookie(urlProvider))
        XCTAssertEqual(Cookie.makeConsentCookie(urlProvider)?.name, Cookie.consent.name)
    }

    func testMakeConsentCookieDoesNotReturnCookieWhenValueNotStoredInUser() {
        User.shared.cookieConsentValue = nil

        XCTAssertNil(Cookie.makeConsentCookie(urlProvider))
    }

    func testDefaultsAddingUser() {
        User.shared.searchCount = 1234
        User.shared.marketCode = .es_cl
        User.shared.adultFilter = .off
        User.shared.autoComplete = false
        User.shared.id = "neverland"
        User.shared.personalized = true

        let dictionary = Cookie.makeStandardCookie(urlProvider).value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
        XCTAssertEqual(Language.current.rawValue, dictionary["l"])
        XCTAssertEqual("1234", dictionary["t"])
        XCTAssertEqual("n", dictionary["f"])
        XCTAssertEqual("es-cl", dictionary["mc"])
        XCTAssertEqual("0", dictionary["as"])
        XCTAssertEqual("1", dictionary["ma"])
        XCTAssertEqual("1", dictionary["mr"])
        XCTAssertEqual("mobile", dictionary["dt"])
        XCTAssertEqual("0", dictionary["fs"])
        XCTAssertEqual("neverland", dictionary["cid"])
        XCTAssertEqual("1", dictionary["a"])
        XCTAssertEqual("1", dictionary["pz"])
    }

    func testDefaultsNoUserId() {
        User.shared.id = nil

        let dictionary = Cookie.makeStandardCookie(urlProvider).value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
        XCTAssertEqual(Language.current.rawValue, dictionary["l"])
        XCTAssertNil(dictionary["cid"])
    }

    func testReceivedInvalidDomain() {
        User.shared.searchCount = 3
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.it", .path: "/", .value: "as=0:f=s:mc=en-uk:t=9999"])!])

        let dictionary = Cookie.makeStandardCookie(urlProvider).value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
        XCTAssertEqual("3", dictionary["t"])
    }

    func testReceiving() {
        User.shared.searchCount = 0
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0:f=s:mc=en-uk:t=9999:cid=loremipsum"])!])

        let dictionary = Cookie.makeStandardCookie(urlProvider).value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
        XCTAssertEqual("9999", dictionary["t"])
        XCTAssertEqual("loremipsum", dictionary["cid"])
    }

    func testReceivingUpdatesCounter() {
        User.shared.searchCount = 0
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0:f=s:mc=en-uk:t=9999"])!])

        XCTAssertEqual(9999, User.shared.searchCount)
    }

    func testReceivingUpdatesCounterToZero() {
        User.shared.searchCount = 5
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0:f=s:mc=en-uk:t=0"])!])

        XCTAssertEqual(0, User.shared.searchCount)
    }

    func testReceivingUpdatesCounterOnlyIncrease() {
        User.shared.searchCount = 5
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0:f=s:mc=en-uk:t=4"])!])

        XCTAssertEqual(5, User.shared.searchCount)

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0:f=s:mc=en-uk:t=6"])!])
        XCTAssertEqual(6, User.shared.searchCount)
    }

    func testReceivingUpdatesUserId() {
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0:f=s:mc=en-uk:t=9999:cid=lorem"])!])

        XCTAssertEqual("lorem", User.shared.id)
    }

    func testReceivingTreeCount() {
        User.shared.searchCount = 0
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "t=9999"])!])
        XCTAssertEqual(9999, User.shared.searchCount)
    }

    func testReceivingAdultFilter() {
        User.shared.adultFilter = .off

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "f=i"])!])
        XCTAssert(User.shared.adultFilter == .moderate)

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "f=y"])!])
        XCTAssert(User.shared.adultFilter == .strict)

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "f=n"])!])
        XCTAssert(User.shared.adultFilter == .off)

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "f=foo"])!])
        XCTAssert(User.shared.adultFilter == .off)
    }

    func testReceivingMarketCode() {
        User.shared.marketCode = .en_us

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "mc=en-gb"])!])
        XCTAssert(User.shared.marketCode == .en_gb)
    }

    func testReceivingAutocomplete() {
        User.shared.autoComplete = false

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=1"])!])
        XCTAssertTrue(User.shared.autoComplete)

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0"])!])
        XCTAssertFalse(User.shared.autoComplete)

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=foo"])!])
        XCTAssertFalse(User.shared.autoComplete)
    }

    func testReceivingPersonalisedSearch() {
        User.shared.personalized = false

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "pz=1"])!])
        XCTAssertTrue(User.shared.personalized)

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "pz=0"])!])
        XCTAssertFalse(User.shared.personalized)

        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "pz=foo"])!])
        XCTAssertFalse(User.shared.personalized)
    }

    func testRemoveUnknownProperties() {
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0:name=test"])!])

        let dictionary = Cookie.makeStandardCookie(urlProvider).value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
        XCTAssertNil(dictionary["name"])
    }

    func testReceivingMaintainsUserId() {
        User.shared.id = "hello"
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "as=0:f=s:mc=en-uk:t=9999"])!])

        XCTAssertEqual("hello", User.shared.id)
    }

    func testReceivedInvalidName() {
        User.shared.searchCount = 3
        extractReceivedCookies([HTTPCookie(properties: [.name: "Facebook", .domain: ".ecosia.org", .path: "/", .value: "as=0:f=s:mc=en-uk:t=9999"])!])

        let dictionary = Cookie.makeStandardCookie(urlProvider).value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
        XCTAssertEqual("3", dictionary["t"])
    }

    func testExtractECCCNoAnalyticsConsent() {
        User.shared.cookieConsentValue = "e"
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "e"])!])

        XCTAssertEqual(User.shared.cookieConsentValue, "e")
        XCTAssertFalse(User.shared.hasAnalyticsCookieConsent)
    }

    func testExtractECCCWithAnalyticsConsent() {
        User.shared.cookieConsentValue = "e"
        extractReceivedCookies([HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "eampg"])!])

        XCTAssertEqual(User.shared.cookieConsentValue, "eampg")
        XCTAssertTrue(User.shared.hasAnalyticsCookieConsent)
    }
}

extension CookieTests {

    /// This function calls the original `Cookie.received` injecting the `urlProvider` utilized for tests
    func extractReceivedCookies(_ cookies: [HTTPCookie]) {
        Cookie.received(cookies, urlProvider: urlProvider)
    }
}
