// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Foundation
import XCTest

@testable import Client

final class SystemLocaleProviderTests: XCTestCase {
    private var logger: MockLogger!

    override func setUp() {
        super.setUp()
        logger = MockLogger()
    }
    override func tearDown() {
        logger = nil
        super.tearDown()
    }

    func test_preferredLanguages_returnsSystemPreferredLanguages() {
        let subject = createSubject()
        XCTAssertEqual(subject.preferredLanguages, Locale.preferredLanguages)
    }

    func test_regionCode_withDefaultLocale_returnsProperRegionCode() {
        let subject = createSubject()
        XCTAssertEqual(subject.regionCode, "US")
        XCTAssertNil(logger.savedMessage, "No log expected for valid region extraction")
    }

    func test_regionCode_withFrenchLocale_returnsProperRegionCode() {
        let subject = createSubject(with: Locale(identifier: "fr_FR"))

        XCTAssertEqual(subject.regionCode, "FR")
        XCTAssertNil(logger.savedMessage, "No log expected for valid region extraction")
    }

    func test_regionCode_whenIdentifierEmpty_returnsUnd_andLogsFatal() {
        let subject = createSubject(with: Locale(identifier: "abc123"))

        let result = subject.regionCode
        XCTAssertEqual(result, "und", "Expected 'und' for undetermined locale")

        XCTAssertEqual(logger.savedCategory, .locale)
        XCTAssertEqual(logger.savedLevel, .fatal)
        XCTAssertEqual(logger.savedMessage, "Unable to retrieve region code from Locale, so return undetermined")
        XCTAssertEqual(logger.savedExtra, Optional(["Locale identifier": "abc123"]))
    }

    private func createSubject(with locale: Locale = Locale(identifier: "en_US")) -> SystemLocaleProvider {
        return SystemLocaleProvider(
            logger: logger,
            injectedLocale: locale
        )
    }
}
