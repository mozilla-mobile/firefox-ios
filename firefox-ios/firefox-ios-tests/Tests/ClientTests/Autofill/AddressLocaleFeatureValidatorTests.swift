// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class AddressLocaleFeatureValidatorTests: XCTestCase {
    func testValidRegionCA() {
        let locale = MockLocaleProvider(regionCode: "CA")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(for: locale.regionCode),
            "Region valid for CA"
        )
    }

    func testValidRegionUS() {
        let locale = MockLocaleProvider(regionCode: "US")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(for: locale.regionCode),
            "Region valid for US"
        )
    }

    func testValidRegionFR() {
        let locale =  MockLocaleProvider(regionCode: "FR")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(for: locale.regionCode),
            "Valid region for FR"
        )
    }

    func testValidRegionDE() {
        let locale =  MockLocaleProvider(regionCode: "DE")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(for: locale.regionCode),
            "Valid region for DE"
        )
    }

    func testValidRegionGB() {
        let locale =  MockLocaleProvider(regionCode: "GB")
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(for: locale.regionCode),
            "Valid region for GB"
        )
    }

    func testInvalidRegionMA() {
        let locale =  MockLocaleProvider(regionCode: "MA")
        XCTAssertFalse(
            AddressLocaleFeatureValidator.isValidRegion(for: locale.regionCode),
            "Invalid region for MA"
        )
    }

    func testInvalidRegionWithoutRegionCode() {
        let locale =  MockLocaleProvider(regionCode: "")
        XCTAssertFalse(
            AddressLocaleFeatureValidator.isValidRegion(for: locale.regionCode),
            "Invalid region for locale without region code"
        )
    }
}
