// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TranslationsVersionHelperTests: XCTestCase {
    func testIsStable_acceptsValidVersions() {
        let subject = createSubject()
        XCTAssertTrue(subject.isStable("1"))
        XCTAssertTrue(subject.isStable("1.0"))
        XCTAssertTrue(subject.isStable("1.2"))
        XCTAssertTrue(subject.isStable("10.20"))
        XCTAssertTrue(subject.isStable("1.2.3"))
        XCTAssertTrue(subject.isStable("10.0.15"))
    }

    func testIsStable_rejectsInvalidVersions() {
        let subject = createSubject()
        XCTAssertFalse(subject.isStable(""))
        XCTAssertFalse(subject.isStable(".1"))
        XCTAssertFalse(subject.isStable("1."))
        XCTAssertFalse(subject.isStable("1..0"))
        XCTAssertFalse(subject.isStable("1.2.3.4"))
        XCTAssertFalse(subject.isStable("1a"))
        XCTAssertFalse(subject.isStable("1.0a"))
        XCTAssertFalse(subject.isStable("v1.0"))
    }

    func testNormalize_validVersions() {
        let subject = createSubject()
        XCTAssertEqual(subject.normalize("1"), "1.0.0")
        XCTAssertEqual(subject.normalize("1.2"), "1.2.0")
        XCTAssertEqual(subject.normalize("1.2.3"), "1.2.3")

        // leading zeros get normalized via Int()
        XCTAssertEqual(subject.normalize("01"), "1.0.0")
        XCTAssertEqual(subject.normalize("01.02"), "1.2.0")
        XCTAssertEqual(subject.normalize("01.02.003"), "1.2.3")
    }

    func testNormalize_invalidVersions() {
        let subject = createSubject()
        XCTAssertNil(subject.normalize(""))
        XCTAssertNil(subject.normalize(".1"))
        XCTAssertNil(subject.normalize("1."))
        XCTAssertNil(subject.normalize("1.2.3.4"))
        XCTAssertNil(subject.normalize("1.0a"))
    }

    func testCompare_equalVersions() {
        let subject = createSubject()
        XCTAssertEqual(subject.compare("1", "1.0"), .some(.orderedSame))
        XCTAssertEqual(subject.compare("1.0", "1.0.0"), .some(.orderedSame))
        XCTAssertEqual(subject.compare("01.02.003", "1.2.3"), .some(.orderedSame))
    }

    func testCompare_ordersCorrectly() {
        let subject = createSubject()
        XCTAssertEqual(subject.compare("1", "2"), .some(.orderedAscending))
        XCTAssertEqual(subject.compare("1.0", "1.1"), .some(.orderedAscending))
        XCTAssertEqual(subject.compare("1.2", "1.10"), .some(.orderedAscending))
        XCTAssertEqual(subject.compare("2.0.1", "2.0.0"), .some(.orderedDescending))
    }

    func testCompare_invalidReturnsNil() {
        let subject = createSubject()
        XCTAssertNil(subject.compare(".1", "1.0"))
        XCTAssertNil(subject.compare("1.0", ".1"))
        XCTAssertNil(subject.compare("1.2.3.4", "1.2.3"))
    }

    func testBest_picksHighestStableBelowMax() {
        let subject = createSubject()
        let versions = ["1.0", "1.1", "1.2.3", "2.0"]
        let best = subject.best(from: versions, maxAllowed: "1.9")
        XCTAssertEqual(best, "1.2.3")
    }

    func testBest_ignoresInvalidVersions() {
        let subject = createSubject()
        let versions = ["1.0", "1.2.3.4", ".1", "1.1"]
        let best = subject.best(from: versions, maxAllowed: "2.0")
        XCTAssertEqual(best, "1.1")
    }

    func testBest_respectsMaxAllowed() {
        let subject = createSubject()
        let versions = ["1.0", "1.5", "2.0", "2.1"]
        let best = subject.best(from: versions, maxAllowed: "2.0")
        XCTAssertEqual(best, "2.0")
    }

    func testBest_invalidMaxAllowedReturnsNil() {
        let subject = createSubject()
        let versions = ["1.0", "1.1", "1.2"]
        XCTAssertNil(subject.best(from: versions, maxAllowed: "1.2.3.4"))
        XCTAssertNil(subject.best(from: versions, maxAllowed: ".1"))
    }

    func testBest_noValidVersionsReturnsNil() {
        let subject = createSubject()
        let versions = ["", ".1", "1.2.3.4", "1.0a"]
        let best = subject.best(from: versions, maxAllowed: "2.0")
        XCTAssertNil(best)
    }

    private func createSubject() -> TranslationsVersionHelper {
        return TranslationsVersionHelper()
    }
}
