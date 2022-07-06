// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import XCTest
@testable import Client
import Shared
import Storage
import SyncTelemetry

class TopSitesViewModelTests: XCTestCase {
    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile(databasePrefix: "FxHomeTopSitesViewModelTests")
    }

    override func tearDown() {
        super.tearDown()
        self.profile._shutdown()
        self.profile = nil
    }

    func testDeletionOfSingleSuggestedSite() {
        let viewModel = TopSitesViewModel(profile: self.profile,
                                                isZeroSearch: false)

        let siteToDelete = TopSitesHelper.defaultTopSites(profile)[0]

        viewModel.hideURLFromTopSites(siteToDelete)
        let newSites = TopSitesHelper.defaultTopSites(profile)

        XCTAssertFalse(newSites.contains(siteToDelete, f: { (a, b) -> Bool in
            return a.url == b.url
        }))
    }

    func testDeletionOfAllDefaultSites() {
        let viewModel = TopSitesViewModel(profile: self.profile,
                                                isZeroSearch: false)

        let defaultSites = TopSitesHelper.defaultTopSites(profile)
        defaultSites.forEach({
            viewModel.hideURLFromTopSites($0)
        })

        let newSites = TopSitesHelper.defaultTopSites(profile)
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
extension TopSitesViewModelTests {

    func createViewModel(overridenSiteCount: Int = 40, overridenNumberOfRows: Int = 2) -> TopSitesViewModel {
        let viewModel = TopSitesViewModel(profile: self.profile,
                                                isZeroSearch: false)

        let managerStub = TopSitesManagerStub(profile: profile)
        managerStub.overridenSiteCount = overridenSiteCount
        managerStub.overridenNumberOfRows = overridenNumberOfRows
        viewModel.tileManager = managerStub

        trackForMemoryLeaks(viewModel)
        trackForMemoryLeaks(managerStub)
        trackForMemoryLeaks(managerStub.googleTopSiteManager)
        trackForMemoryLeaks(managerStub.topSiteHistoryManager)

        return viewModel
    }
}

// MARK: FakeTraitCollection
class FakeTraitCollection: UITraitCollection {

    var overridenHorizontalSizeClass: UIUserInterfaceSizeClass = .regular
    override var horizontalSizeClass: UIUserInterfaceSizeClass {
        return overridenHorizontalSizeClass
    }

    var overridenVerticalSizeClass: UIUserInterfaceSizeClass = .regular
    override var verticalSizeClass: UIUserInterfaceSizeClass {
        return overridenVerticalSizeClass
    }
}

// MARK: TopSitesManagerStub
private class TopSitesManagerStub: TopSitesManager {

    var overridenSiteCount = 40
    override var siteCount: Int {
        return overridenSiteCount
    }

    var overridenNumberOfRows = 2
    override var numberOfRows: Int {
        return overridenNumberOfRows
    }
}
