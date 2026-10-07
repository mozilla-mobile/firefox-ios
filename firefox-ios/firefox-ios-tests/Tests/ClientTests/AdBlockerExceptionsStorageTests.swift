// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class AdBlockerExceptionsStorageTests: XCTestCase {
    private var subject: AdBlockerExceptionsStorage!

    override func setUp() async throws {
        try await super.setUp()
        subject = AdBlockerExceptionsStorage()
        subject.removeAllDomains()
    }

    override func tearDown() async throws {
        subject.removeAllDomains()
        subject = nil
        try await super.tearDown()
    }

    func testAddDomain_addsToList() {
        subject.addDomain("example.com")

        XCTAssertEqual(subject.count, 1)
        XCTAssertTrue(subject.containsDomain("example.com"))
    }

    func testAddDomain_normalizesDomain() {
        subject.addDomain("https://www.Example.COM/")

        XCTAssertEqual(subject.domains.first, "example.com")
        XCTAssertTrue(subject.containsDomain("example.com"))
    }

    func testAddDomain_preventsDuplicates() {
        subject.addDomain("example.com")
        subject.addDomain("example.com")

        XCTAssertEqual(subject.count, 1)
    }

    func testAddDomain_ignoresEmptyString() {
        subject.addDomain("")

        XCTAssertEqual(subject.count, 0)
    }

    func testRemoveDomain_removesFromList() {
        subject.addDomain("example.com")
        subject.addDomain("test.com")

        subject.removeDomain("example.com")

        XCTAssertEqual(subject.count, 1)
        XCTAssertFalse(subject.containsDomain("example.com"))
        XCTAssertTrue(subject.containsDomain("test.com"))
    }

    func testRemoveDomains_removesBatch() {
        subject.addDomain("a.com")
        subject.addDomain("b.com")
        subject.addDomain("c.com")

        subject.removeDomains(Set(["a.com", "c.com"]))

        XCTAssertEqual(subject.count, 1)
        XCTAssertTrue(subject.containsDomain("b.com"))
    }

    func testRemoveAllDomains_clearsAll() {
        subject.addDomain("a.com")
        subject.addDomain("b.com")

        subject.removeAllDomains()

        XCTAssertEqual(subject.count, 0)
        XCTAssertTrue(subject.domains.isEmpty)
    }

    func testExceptionsAsJSON_emptyReturnsEmptyString() {
        XCTAssertEqual(subject.exceptionsAsJSON(), "")
    }

    func testExceptionsAsJSON_generatesIgnorePreviousRules() {
        subject.addDomain("example.com")

        let json = subject.exceptionsAsJSON()

        XCTAssertTrue(json.contains("ignore-previous-rules"))
        XCTAssertTrue(json.contains("*example.com"))
    }

    func testExceptionsAsJSON_includesMultipleDomains() {
        subject.addDomain("a.com")
        subject.addDomain("b.com")

        let json = subject.exceptionsAsJSON()

        XCTAssertTrue(json.contains("*a.com"))
        XCTAssertTrue(json.contains("*b.com"))
    }

    func testNormalizeDomain_stripsSchemes() {
        subject.addDomain("http://test.com")
        XCTAssertTrue(subject.containsDomain("test.com"))

        subject.addDomain("https://secure.com")
        XCTAssertTrue(subject.containsDomain("secure.com"))
    }

    func testNormalizeDomain_stripsWwwPrefix() {
        subject.addDomain("www.test.com")
        XCTAssertTrue(subject.containsDomain("test.com"))
    }

    func testNormalizeDomain_stripsTrailingSlash() {
        subject.addDomain("test.com/")
        XCTAssertTrue(subject.containsDomain("test.com"))
    }

    func testNormalizeDomain_lowercases() {
        subject.addDomain("TEST.COM")
        XCTAssertTrue(subject.containsDomain("test.com"))
    }
}
