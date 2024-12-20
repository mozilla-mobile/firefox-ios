// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage

@testable import Client

class LegacyTopSitesDimensionTests: XCTestCase {
    struct DeviceSize {
        static let iPhone14 = CGSize(width: 390, height: 844)
        static let iPadAir = CGSize(width: 820, height: 1180)
        static let iPadAirCompactSplit = CGSize(width: 320, height: 375)
    }

    func testSectionDimension_portraitIphone_defaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: false,
                                            interfaceIdiom: .phone,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPhone14.width)

        let dimension = subject.getSectionDimension(for: createSites(), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_landscapeIphone_defaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: true,
                                            interfaceIdiom: .phone,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPhone14.height)

        let dimension = subject.getSectionDimension(for: createSites(), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 8)
    }

    func testSectionDimension_portraitiPadRegular_defaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: false,
                                            interfaceIdiom: .pad,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPadAir.width)

        let dimension = subject.getSectionDimension(for: createSites(), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 7)
    }

    func testSectionDimension_landscapeiPadRegular_defaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: true,
                                            interfaceIdiom: .pad,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPadAir.height)

        let dimension = subject.getSectionDimension(for: createSites(), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 10)
    }

    func testSectionDimension_portraitiPadCompact_defaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: false,
                                            interfaceIdiom: .pad,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPadAirCompactSplit.width)

        let dimension = subject.getSectionDimension(for: createSites(), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_landscapeiPadCompact_defaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: true,
                                            interfaceIdiom: .pad,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPadAirCompactSplit.height)

        let dimension = subject.getSectionDimension(for: createSites(), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_portraitiPadUnspecified_defaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection(horizontalSizeClass: .unspecified).getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: false,
                                            interfaceIdiom: .pad,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPadAir.width)

        let dimension = subject.getSectionDimension(for: createSites(), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 7)
    }

    func testSectionDimension_landscapeiPadUnspecified_defaultRowNumber() {
        let subject = createSubject()
        let trait = MockTraitCollection(horizontalSizeClass: .unspecified).getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: true,
                                            interfaceIdiom: .pad,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPadAir.height)

        let dimension = subject.getSectionDimension(for: createSites(), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 11)
    }

    // MARK: Section dimension with stubbed data

    func testSectionDimension_oneEmptyRow_shouldBeRemoved() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: false,
                                            interfaceIdiom: .phone,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPhone14.width)

        let dimension = subject.getSectionDimension(for: createSites(count: 4), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 1)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_twoEmptyRow_shouldBeRemoved() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: false,
                                            interfaceIdiom: .phone,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPhone14.width)

        let dimension = subject.getSectionDimension(for: createSites(count: 4), numberOfRows: 3, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 1)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_noEmptyRow_shouldNotBeRemoved() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: false,
                                            interfaceIdiom: .phone,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPhone14.width)

        let dimension = subject.getSectionDimension(for: createSites(count: 8), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }

    func testSectionDimension_halfFilledRow_shouldNotBeRemoved() {
        let subject = createSubject()
        let trait = MockTraitCollection().getTraitCollection()
        let interface = TopSitesUIInterface(isLandscape: false,
                                            interfaceIdiom: .phone,
                                            trait: trait,
                                            availableWidth: DeviceSize.iPhone14.width)

        let dimension = subject.getSectionDimension(for: createSites(count: 6), numberOfRows: 2, interface: interface)
        XCTAssertEqual(dimension.numberOfRows, 2)
        XCTAssertEqual(dimension.numberOfTilesPerRow, 4)
    }
}

extension LegacyTopSitesDimensionTests {
    func createSubject() -> TopSitesDimension {
        let subject = LegacyTopSitesDimensionImplementation()
        trackForMemoryLeaks(subject)

        return subject
    }

    func createSites(count: Int = 30) -> [TopSite] {
        var sites = [TopSite]()
        (0..<count).forEach {
            let site = Site(url: "www.url\($0).com",
                            title: "Title \($0)")
            sites.append(TopSite(site: site))
        }
        return sites
    }
}
