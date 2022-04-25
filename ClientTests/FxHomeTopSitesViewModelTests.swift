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
    var profile: MockProfile!
    var viewModel: FxHomeTopSitesViewModel!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile(databasePrefix: "FxHomeTopSitesViewModelTests")
        self.viewModel = FxHomeTopSitesViewModel(profile: self.profile,
                                                 isZeroSearch: false)
    }

    override func tearDown() {
        super.tearDown()
        self.profile._shutdown()
        self.viewModel = nil
        self.profile = nil
    }

    func testDeletionOfSingleSuggestedSite() {
        let siteToDelete = TopSitesHelper.defaultTopSites(profile)[0]

        viewModel.hideURLFromTopSites(siteToDelete)
        let newSites = TopSitesHelper.defaultTopSites(profile)

        XCTAssertFalse(newSites.contains(siteToDelete, f: { (a, b) -> Bool in
            return a.url == b.url
        }))
    }

    func testDeletionOfAllDefaultSites() {
        let defaultSites = TopSitesHelper.defaultTopSites(profile)
        defaultSites.forEach({
            viewModel.hideURLFromTopSites($0)
        })

        let newSites = TopSitesHelper.defaultTopSites(profile)
        XCTAssertTrue(newSites.isEmpty)
    }

    // MARK: Section dimension with Default row number

    func testSectionDimension_portraitIphone_defaultRowNumber() {
        createManager()
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_landscapeIphone_defaultRowNumber() {
        createManager()
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: true, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 8)
    }

    func testSectionDimension_portraitiPadRegular_defaultRowNumber() {
        createManager()
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 6)
    }

    func testSectionDimension_landscapeiPadRegular_defaultRowNumber() {
        createManager()
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: true, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 8)
    }

    func testSectionDimension_portraitiPadCompact_defaultRowNumber() {
        createManager()
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .compact

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_landscapeiPadCompact_defaultRowNumber() {
        createManager()
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .compact

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: true, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_portraitiPadUnspecified_defaultRowNumber() {
        createManager()
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .unspecified

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 2)
    }

    func testSectionDimension_landscapeiPadUnspecified_defaultRowNumber() {
        createManager()
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .unspecified

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: true, isIphone: false)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    // MARK: Section dimension with stubbed data

    func testSectionDimension_oneEmptyRow_shouldBeRemoved() {
        createManager(overridenSiteCount: 4, overridenNumberOfRows: 2)
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 1)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_twoEmptyRow_shouldBeRemoved() {
        createManager(overridenSiteCount: 4, overridenNumberOfRows: 3)
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 1)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_noEmptyRow_shouldNotBeRemoved() {
        createManager(overridenSiteCount: 8, overridenNumberOfRows: 2)
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_halfFilledRow_shouldNotBeRemoved() {
        createManager(overridenSiteCount: 6, overridenNumberOfRows: 2)
        let trait = FakeTraitCollection()

        let dimension = viewModel.getSectionDimension(for: trait, isLandscape: false, isIphone: true)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }
}

// MARK: Helper methods
extension FxHomeTopSitesViewModelTests {

    func createManager(overridenSiteCount: Int = 40, overridenNumberOfRows: Int = 2) {
        let managerStub = FxHomeTopSitesManagerStub(profile: profile)
        managerStub.overridenSiteCount = overridenSiteCount
        managerStub.overridenNumberOfRows = overridenNumberOfRows
        viewModel.tileManager = managerStub
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
