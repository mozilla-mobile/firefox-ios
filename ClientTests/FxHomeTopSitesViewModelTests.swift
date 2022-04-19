// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import XCTest
@testable import Client
import Shared
import Storage
import SyncTelemetry

class FxHomeTopSitesViewModelTests: XCTestCase {

    func testDeletionOfSingleSuggestedSite() {
        let sut = createViewModelAndProfile(useManager: false)

        let siteToDelete = TopSitesHelper.defaultTopSites(sut.1)[0]

        sut.0.hideURLFromTopSites(siteToDelete)
        let newSites = TopSitesHelper.defaultTopSites(sut.1)

        XCTAssertFalse(newSites.contains(siteToDelete, f: { (a, b) -> Bool in
            return a.url == b.url
        }))
    }

    func testDeletionOfAllDefaultSites() {
        let sut = createViewModelAndProfile(useManager: false)

        let defaultSites = TopSitesHelper.defaultTopSites(sut.1)
        defaultSites.forEach({
            sut.0.hideURLFromTopSites($0)
        })

        let newSites = TopSitesHelper.defaultTopSites(sut.1)
        XCTAssertTrue(newSites.isEmpty)
    }

    // MARK: Section dimension with Default row number

    func testSectionDimension_portraitIphone_defaultRowNumber() {
        let viewModel = createViewModel()
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_landscapeIphone_defaultRowNumber() {
        let viewModel = createViewModel()
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: true, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 8)
    }

    func testSectionDimension_portraitiPadRegular_defaultRowNumber() {
        let viewModel = createViewModel()
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 6)
    }

    func testSectionDimension_landscapeiPadRegular_defaultRowNumber() {
        let viewModel = createViewModel()
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: true, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 8)
    }

    func testSectionDimension_portraitiPadCompact_defaultRowNumber() {
        let viewModel = createViewModel()
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .compact

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_landscapeiPadCompact_defaultRowNumber() {
        let viewModel = createViewModel()
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .compact

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: true, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_portraitiPadUnspecified_defaultRowNumber() {
        let viewModel = createViewModel()
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .unspecified

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 2)
    }

    func testSectionDimension_landscapeiPadUnspecified_defaultRowNumber() {
        let viewModel = createViewModel()
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .unspecified

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: true, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    // MARK: Section dimension with stubbed data

    func testSectionDimension_oneEmptyRow_shouldBeRemoved() {
        let viewModel = createViewModel(overridenSiteCount: 4, overridenNumberOfRows: 2)
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 1)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_twoEmptyRow_shouldBeRemoved() {
        let viewModel = createViewModel(overridenSiteCount: 4, overridenNumberOfRows: 3)
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 1)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_noEmptyRow_shouldNotBeRemoved() {
        let viewModel = createViewModel(overridenSiteCount: 8, overridenNumberOfRows: 2)
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_halfFilledRow_shouldNotBeRemoved() {
        let viewModel = createViewModel(overridenSiteCount: 6, overridenNumberOfRows: 2)
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }
}

// MARK: Helper methods
extension FxHomeTopSitesViewModelTests {

    func createViewModel(useManager: Bool = true,
                         overridenSiteCount: Int = 40,
                         overridenNumberOfRows: Int = 2,
                         file: StaticString = #file,
                         line: UInt = #line) -> FxHomeTopSitesViewModel {
        return createViewModelAndProfile(useManager: useManager,
                                         overridenSiteCount: overridenSiteCount,
                                         overridenNumberOfRows: overridenNumberOfRows,
                                         file: file, line: line).0
    }

    func createViewModelAndProfile(useManager: Bool = true,
                                   overridenSiteCount: Int = 40,
                                   overridenNumberOfRows: Int = 2,
                                   file: StaticString = #file,
                                   line: UInt = #line) -> (FxHomeTopSitesViewModel, MockProfile) {
        let profile = MockProfile(databasePrefix: "FxHomeTopSitesViewModelTests")
        let nimbusMock = NimbusMock()

        let viewModel = FxHomeTopSitesViewModel(profile: profile,
                                                isZeroSearch: false)

        if useManager {
            let managerStub = FxHomeTopSitesManagerStub(profile: profile)
            managerStub.overridenSiteCount = overridenSiteCount
            managerStub.overridenNumberOfRows = overridenNumberOfRows
            viewModel.tileManager = managerStub

            trackForMemoryLeaks(managerStub)
            trackForMemoryLeaks(managerStub.googleTopSiteManager)
            trackForMemoryLeaks(managerStub.topSiteHistoryManager)
        }

        trackForMemoryLeaks(viewModel, file: file, line: line)

        return (viewModel, profile)
    }
}

// MARK: FakeTraitCollection
private class FakeTraitCollection: UITraitCollection {

    var overridenHorizontalSizeClass: UIUserInterfaceSizeClass = .regular
    override var horizontalSizeClass: UIUserInterfaceSizeClass {
        return overridenHorizontalSizeClass
    }
}

// MARK: FxHomeTopSitesManagerStub
private class FxHomeTopSitesManagerStub: FxHomeTopSitesManager {

    var overridenSiteCount = 40
    override var siteCount: Int {
        return overridenSiteCount
    }

    var overridenNumberOfRows = 2
    override var numberOfRows: Int {
        return overridenNumberOfRows
    }
}
