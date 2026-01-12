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
        let subject = createSubject(with: Locale(identifier: "en_US"))
        XCTAssertEqual(subject.preferredLanguages, Locale.preferredLanguages)
    }

    func test_regionCode_withEnglishUSLocale_returnsProperRegionCode() {
        let subject = createSubject(with: Locale(identifier: "en_US"))
        XCTAssertEqual(subject.regionCode(), "US")
        XCTAssertNil(logger.savedMessage, "No log expected for valid region extraction")
    }

    func test_regionCode_withEnglishCanadaLocale_returnsProperRegionCode() {
        let subject = createSubject(with: Locale(identifier: "en_CA"))

        XCTAssertEqual(subject.regionCode(), "CA")
        XCTAssertNil(logger.savedMessage, "No log expected for valid region extraction")
    }

    func test_regionCode_withFrenchCanadaLocale_returnsProperRegionCode() {
        let subject = createSubject(with: Locale(identifier: "fr_CA"))

        XCTAssertEqual(subject.regionCode(), "CA")
        XCTAssertNil(logger.savedMessage, "No log expected for valid region extraction")
    }

    func test_regionCode_withFrenchFranceLocale_returnsProperRegionCode() {
        let subject = createSubject(with: Locale(identifier: "fr_FR"))

        XCTAssertEqual(subject.regionCode(), "FR")
        XCTAssertNil(logger.savedMessage, "No log expected for valid region extraction")
    }

    func test_regionCode_withGermanGermanyLocale_returnsProperRegionCode() {
        let subject = createSubject(with: Locale(identifier: "de_DE"))

        XCTAssertEqual(subject.regionCode(), "DE")
        XCTAssertNil(logger.savedMessage, "No log expected for valid region extraction")
    }

    func test_regionCode_whenIdentifierEmpty_returnsUnd_andLogsFatal() {
        let subject = createSubject(with: Locale(identifier: "abc123"))

        let result = subject.regionCode()
        XCTAssertEqual(result, "und", "Expected 'und' for undetermined locale")

        XCTAssertEqual(logger.savedCategory, .locale)
        XCTAssertEqual(logger.savedLevel, .fatal)
        XCTAssertEqual(logger.savedMessage, "Unable to retrieve region code from Locale, so return undetermined")
        XCTAssertEqual(logger.savedExtra, Optional(["Locale identifier": "abc123"]))
    }

    func test_regionCode_withMultipleLanguages_returnsUnd_andLogsFatal() {
        let subject: SystemLocaleProvider
        if #available (iOS 16, *) {
            subject = createSubject(with: Locale(languageCode: .multiple))
        } else {
            subject = createSubject(with: Locale(identifier: "mul"))
        }

        let result = subject.regionCode()
        XCTAssertEqual(result, "und", "Expected 'und' for cases when there are more than one languages")

        XCTAssertEqual(logger.savedCategory, .locale)
        XCTAssertEqual(logger.savedLevel, .fatal)
        XCTAssertEqual(logger.savedMessage, "Unable to retrieve region code from Locale, so return undetermined")
        XCTAssertEqual(logger.savedExtra, Optional(["Locale identifier": "mul"]))
    }

    func test_regionCode_withUnavailable_returnsUnd_andLogsFatal() {
        let subject: SystemLocaleProvider
        if #available (iOS 16, *) {
            subject = createSubject(with: Locale(languageCode: .unavailable))
        } else {
            subject = createSubject(with: Locale(identifier: "zxx"))
        }

        let result = subject.regionCode()
        XCTAssertEqual(
            result,
            "und",
            "Expected 'und' for cases when the content is not in any particular languages, such as images, symbols, etc."
        )

        XCTAssertEqual(logger.savedCategory, .locale)
        XCTAssertEqual(logger.savedLevel, .fatal)
        XCTAssertEqual(logger.savedMessage, "Unable to retrieve region code from Locale, so return undetermined")
        XCTAssertEqual(logger.savedExtra, Optional(["Locale identifier": "zxx"]))
    }

    func test_regionCode_withEmptyStringFallback_returnsProperFallback() {
        let subject = createSubject(with: Locale(identifier: "fakeIdentifier"))
        let result = subject.regionCode(fallback: "")
        XCTAssertEqual(result, "")

        XCTAssertEqual(logger.savedCategory, .locale)
        XCTAssertEqual(logger.savedLevel, .fatal)
        XCTAssertEqual(logger.savedMessage, "Unable to retrieve region code from Locale, so return undetermined")
        XCTAssertEqual(logger.savedExtra, Optional(["Locale identifier": "fakeidentifier"]))
    }

    func test_regionCode_withUSFallback_returnsProperFallback() {
        let subject = createSubject(with: Locale(identifier: "fakeIdentifier"))
        let result = subject.regionCode(fallback: "US")
        XCTAssertEqual(result, "US")

        XCTAssertEqual(logger.savedCategory, .locale)
        XCTAssertEqual(logger.savedLevel, .fatal)
        XCTAssertEqual(logger.savedMessage, "Unable to retrieve region code from Locale, so return undetermined")
        XCTAssertEqual(logger.savedExtra, Optional(["Locale identifier": "fakeidentifier"]))
    }

    private func createSubject(with locale: Locale) -> SystemLocaleProvider {
        return SystemLocaleProvider(
            logger: logger,
            injectedLocale: locale
        )
    }
}
