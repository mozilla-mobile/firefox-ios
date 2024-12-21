// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class TopSitesDimensionImplementationTests: XCTestCase {
    private var dispatchQueue: MockDispatchQueue!

    struct UX {
        struct DeviceSize {
            static let iPhone14 = CGSize(width: 390, height: 844)
            static let iPadAir = CGSize(width: 820, height: 1180)
            static let iPadAirCompactSplit = CGSize(width: 320, height: 375)
        }

        static let cellWidth = HomepageSectionLayoutProvider.UX.TopSitesConstants.cellEstimatedSize.width
    }

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        dispatchQueue = MockDispatchQueue()
    }

    override func tearDown() {
        dispatchQueue = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func test_updateNumberOfTilesPerRow_withPortraitIphone_showsExpectedRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .phone)

        subject.updateNumberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPhone14.width,
            leadingInset: leadingInset,
            cellWidth: UX.cellWidth
        )

        XCTAssertEqual(subject.numberOfTilesPerRow, 4)
    }

    func test_updateNumberOfTilesPerRow_withLandscapeIphone_showsExpectedRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .phone)

        subject.updateNumberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPhone14.height,
            leadingInset: leadingInset,
            cellWidth: UX.cellWidth
        )

        XCTAssertEqual(subject.numberOfTilesPerRow, 8)
    }

    func test_updateNumberOfTilesPerRow_withPortraitIpadRegular_showsExpectedRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        subject.updateNumberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPadAir.width,
            leadingInset: leadingInset,
            cellWidth: UX.cellWidth
        )

        XCTAssertEqual(subject.numberOfTilesPerRow, 7)
    }

    func test_updateNumberOfTilesPerRow_withLandscapeIpadRegular_showsDefaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        subject.updateNumberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPadAir.height,
            leadingInset: leadingInset,
            cellWidth: UX.cellWidth
        )

        XCTAssertEqual(subject.numberOfTilesPerRow, 10)
    }

    func test_updateNumberOfTilesPerRow_withPortraitIpadCompact_showsDefaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        subject.updateNumberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPadAirCompactSplit.width,
            leadingInset: leadingInset,
            cellWidth: UX.cellWidth
        )

        XCTAssertEqual(subject.numberOfTilesPerRow, 4)
    }

    func test_updateNumberOfTilesPerRow_withLandscapeIpadCompact_showsDefaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        subject.updateNumberOfTilesPerRow(
            availableWidth: UX.DeviceSize.iPadAirCompactSplit.height,
            leadingInset: leadingInset,
            cellWidth: UX.cellWidth
        )

        XCTAssertEqual(subject.numberOfTilesPerRow, 4)
    }

    func createSubject() -> TopSitesDimensionImplementation {
        let subject = TopSitesDimensionImplementation(windowUUID: .XCTestDefaultUUID, queue: dispatchQueue)
        trackForMemoryLeaks(subject)

        return subject
    }
}
