// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class AddressLocaleFeatureValidatorTests: XCTestCase {
    func testValidRegionCA() {
        let locale = Locale(identifier: "en_CA")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(locale: locale),
            "Region valid for CA"
        )
    }

    func testValidRegionUS() {
        let locale = Locale(identifier: "en_US")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(locale: locale),
            "Region valid for US"
        )
    }

    func testValidRegionFR() {
        let locale = Locale(identifier: "fr_FR")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(locale: locale),
            "Valid region for FR"
        )
    }

    func testValidRegionDE() {
        let locale = Locale(identifier: "de_DE")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(locale: locale),
            "Valid region for DE"
        )
    }

    func testValidRegionGB() {
        let locale = Locale(identifier: "en_GB")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(locale: locale),
            "Valid region for GB"
        )
    }

    func testInvalidRegionMA() {
        let locale = Locale(identifier: "fr_MA")
        XCTAssertFalse(
            AddressLocaleFeatureValidator.isValidRegion(locale: locale),
            "Invalid region for MA"
        )
    }

    func testInvalidRegionWithoutRegionCode() {
        let locale = Locale(identifier: "")
        XCTAssertFalse(
            AddressLocaleFeatureValidator.isValidRegion(locale: locale),
            "Invalid region for locale without region code"
        )
    }
}
