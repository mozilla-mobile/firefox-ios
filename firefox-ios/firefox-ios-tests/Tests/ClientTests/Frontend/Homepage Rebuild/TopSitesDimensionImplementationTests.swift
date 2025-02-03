// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class TopSitesDimensionCalculatorTests: XCTestCase {
    struct UX {
        struct DeviceSize {
            static let iPhone14 = CGSize(width: 390, height: 844)
            static let iPadAir = CGSize(width: 820, height: 1180)
            static let iPadAirCompactSplit = CGSize(width: 320, height: 375)
        }
    }

    func test_getNumberOfTilesPerRow_withPortraitIphone_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .phone)

        let numberOfTilesPerRow = TopSitesDimensionCalculator.numberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPhone14.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIphone_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .phone)

        let numberOfTilesPerRow = TopSitesDimensionCalculator.numberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPhone14.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 8)
    }

    func test_getNumberOfTilesPerRow_withPortraitIpadRegular_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = TopSitesDimensionCalculator.numberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPadAir.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 7)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIpadRegular_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = TopSitesDimensionCalculator.numberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPadAir.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 10)
    }

    func test_getNumberOfTilesPerRow_withPortraitIpadCompact_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = TopSitesDimensionCalculator.numberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPadAirCompactSplit.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIpadCompact_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = TopSitesDimensionCalculator.numberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPadAirCompactSplit.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }
}
