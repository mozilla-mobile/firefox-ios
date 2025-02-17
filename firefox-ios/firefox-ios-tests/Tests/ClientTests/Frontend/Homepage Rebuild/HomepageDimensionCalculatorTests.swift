// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class HomepageDimensionCalculatorTests: XCTestCase {
    struct UX {
        struct DeviceSize {
            static let iPhone14 = CGSize(width: 390, height: 844)
            static let iPadAir = CGSize(width: 820, height: 1180)
            static let iPadAirCompactSplit = CGSize(width: 320, height: 375)
        }
    }

    // MARK: - maxJumpBackInItemsToDisplay
    func test_maxJumpBackInItemsToDisplay_withPortraitIphone_showsExpectedConfiguration() {
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        let configuration = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: trait,
            for: .phone,
            and: false
        )

        XCTAssertEqual(configuration.maxLocalTabsWhenSyncedTabExists, 1)
        XCTAssertEqual(configuration.maxLocalTabsWhenNoSyncedTab, 2)
        XCTAssertEqual(configuration.layoutType, .compact)
    }

    func test_maxJumpBackInItemsToDisplay_withLandscapeIphone_showsExpectedConfiguration() {
        let trait = MockTraitCollection().getTraitCollection()

        let configuration = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: trait,
            for: .phone,
            and: true
        )

        XCTAssertEqual(configuration.maxLocalTabsWhenSyncedTabExists, 2)
        XCTAssertEqual(configuration.maxLocalTabsWhenNoSyncedTab, 4)
        XCTAssertEqual(configuration.layoutType, .medium)
    }

    func test_maxJumpBackInItemsToDisplay_withPortraitIpad_showsExpectedConfiguration() {
        let trait = MockTraitCollection().getTraitCollection()

        let configuration = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: trait,
            for: .pad,
            and: false
        )

        XCTAssertEqual(configuration.maxLocalTabsWhenSyncedTabExists, 2)
        XCTAssertEqual(configuration.maxLocalTabsWhenNoSyncedTab, 4)
        XCTAssertEqual(configuration.layoutType, .medium)
    }

    func test_maxJumpBackInItemsToDisplay_withLandscapeIpad_andWithSyncedTab_showsExpectedTabs() {
        let trait = MockTraitCollection().getTraitCollection()

        let configuration = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: trait,
            for: .pad,
            and: true
        )
        XCTAssertEqual(configuration.maxLocalTabsWhenSyncedTabExists, 4)
        XCTAssertEqual(configuration.maxLocalTabsWhenNoSyncedTab, 6)
        XCTAssertEqual(configuration.layoutType, .regular)
    }

    // MARK: - getNumberOfTilesPerRow
    func test_getNumberOfTilesPerRow_withPortraitIphone_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .phone)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPhone14.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIphone_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .phone)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPhone14.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 8)
    }

    func test_getNumberOfTilesPerRow_withPortraitIpadRegular_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPadAir.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 7)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIpadRegular_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPadAir.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 10)
    }

    func test_getNumberOfTilesPerRow_withPortraitIpadCompact_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPadAirCompactSplit.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIpadCompact_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPadAirCompactSplit.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }
}
