// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Shared
import XCTest

@testable import Client

@MainActor
final class WallpaperSettingsViewModelTests: XCTestCase {
    private var wallpaperManager: WallpaperManagerInterface!

    override func setUp() async throws {
        try await super.setUp()

        wallpaperManager = WallpaperManagerMock()
        addWallpaperCollections()
    }

    override func tearDown() async throws {
        wallpaperManager = nil
        try await super.tearDown()
    }

    func testInit_hasDefaultLayout() {
        let subject = createSubject()
        let expectedLayout: WallpaperSettingsViewModel.WallpaperSettingsLayout = .compact
        XCTAssertEqual(subject.sectionLayout, expectedLayout)
    }

    func testUpdateSectionLayout_hasRegularLayout() {
        let subject = createSubject()
        let expectedLayout: WallpaperSettingsViewModel.WallpaperSettingsLayout = .regular

        let landscapeTrait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.updateSectionLayout(for: landscapeTrait)

        XCTAssertEqual(subject.sectionLayout, expectedLayout)
    }

    func testNumberOfSections() {
        let subject = createSubject()

        XCTAssertEqual(subject.numberOfSections, 2)
    }

    func testNumberOfItemsInSection() {
        let subject = createSubject()

        XCTAssertEqual(subject.numberOfWallpapers(in: 0),
                       wallpaperManager.availableCollections[safe: 0]?.wallpapers.count)

        XCTAssertEqual(subject.numberOfWallpapers(in: 1),
                       wallpaperManager.availableCollections[safe: 1]?.wallpapers.count)
    }

    func testSectionHeaderViewModel_defaultCollectionWithoutLinkAndDescription() {
        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 0) {
        }

        XCTAssertNotNil(headerViewModel?.title)
        XCTAssertNil(headerViewModel?.description)
        XCTAssertNil(headerViewModel?.buttonTitle)
    }

    func testSectionHeaderViewModel_limitedCollectionWithLinkAndDescription() {
        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 1) {
        }

        XCTAssertNotNil(headerViewModel?.title)
        XCTAssertNotNil(headerViewModel?.description)
        XCTAssertNotNil(headerViewModel?.buttonTitle)
    }

    func testSectionHeaderViewModel_wrexhamCollection_hasBrandTitleWithoutDescriptionAndLink() {
        setCollections([
            makeCollection(id: WallpaperCollection.classicFirefoxID),
            makeCollection(id: WallpaperCollection.wrexhamID, learnMoreURL: "https://www.mozilla.com")
        ])
        let subject = createSubject()

        let headerViewModel = subject.sectionHeaderViewModel(for: 1) {
        }

        XCTAssertEqual(headerViewModel?.title, WallpaperCollection.wrexhamTitle)
        XCTAssertNil(headerViewModel?.description)
        XCTAssertNil(headerViewModel?.buttonTitle)
    }

    func testSectionHeaderViewModel_limitedCollection_usesDescriptionFromMetadata() {
        setCollections([
            makeCollection(id: WallpaperCollection.classicFirefoxID),
            makeCollection(id: "otherCollection", description: "A described collection")
        ])
        let subject = createSubject()

        let headerViewModel = subject.sectionHeaderViewModel(for: 1) {
        }

        XCTAssertEqual(headerViewModel?.description, "A described collection")
    }

    func testSectionHeaderViewModel_limitedCollectionWithoutMetadataDescription_usesDefaultDescription() {
        setCollections([
            makeCollection(id: WallpaperCollection.classicFirefoxID),
            makeCollection(id: "otherCollection")
        ])
        let subject = createSubject()

        let headerViewModel = subject.sectionHeaderViewModel(for: 1) {
        }

        XCTAssertEqual(headerViewModel?.description,
                       String.Settings.Homepage.Wallpaper.LimitedEditionDefaultDescription)
    }

    func testSectionHeaderViewModel_descriptionIsNotDerivedFromSectionIndex() {
        setCollections([
            makeCollection(id: WallpaperCollection.classicFirefoxID),
            makeCollection(id: "firstLimitedCollection", description: "First description"),
            makeCollection(id: "secondLimitedCollection", description: "Second description")
        ])
        let subject = createSubject()

        XCTAssertEqual(subject.sectionHeaderViewModel(for: 1) {}?.description, "First description")
        XCTAssertEqual(subject.sectionHeaderViewModel(for: 2) {}?.description, "Second description")
    }

    func testDownloadAndSetWallpaper_downloaded_wallpaperIsSet() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }
        let subject = createSubject()
        let indexPath = IndexPath(item: 1, section: 0)

        subject.downloadAndSetWallpaper(at: indexPath) { result in
            XCTAssertEqual(subject.selectedIndexPath, indexPath)
            XCTAssertEqual(mockManager.setCurrentWallpaperCallCount, 1)
        }
    }

//    func testClickingCell_recordsWallpaperChange() {
//        wallpaperManager = WallpaperManager()
//        let subject = createSubject()
//
//        let expectation = self.expectation(description: "Download and set wallpaper")
//        subject.downloadAndSetWallpaper(at: IndexPath(item: 0, section: 0)) { _ in
//            self.testEventMetricRecordingSuccess(metric: GleanMetrics.WallpaperAnalytics.wallpaperSelected)
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }

    func createSubject() -> WallpaperSettingsViewModel {
        let subject = WallpaperSettingsViewModel(
            wallpaperManager: wallpaperManager,
            tabManager: MockTabManager(),
            theme: LightTheme(),
            windowUUID: .XCTestDefaultUUID
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    func makeCollection(id: String,
                        learnMoreURL: String? = nil,
                        description: String? = nil) -> WallpaperCollection {
        return WallpaperCollection(
            id: id,
            learnMoreURL: learnMoreURL,
            availableLocales: nil,
            availability: nil,
            wallpapers: [Wallpaper(id: "fxAmethyst",
                                   textColor: .red,
                                   cardColor: .red,
                                   logoTextColor: .red)],
            description: description,
            heading: nil)
    }

    func setCollections(_ collections: [WallpaperCollection]) {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }
        mockManager.mockAvailableCollections = collections
    }

    func addWallpaperCollections() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        var wallpapersForClassic: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            wallpapers.append(Wallpaper(id: "fxDefault",
                                        textColor: .green,
                                        cardColor: .green,
                                        logoTextColor: .green))

            for _ in 0..<4 {
                wallpapers.append(Wallpaper(id: "fxAmethyst",
                                            textColor: .red,
                                            cardColor: .red,
                                            logoTextColor: .red))
            }

            return wallpapers
        }

        var wallpapersForOther: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            for _ in 0..<6 {
                wallpapers.append(Wallpaper(id: "fxCerulean",
                                            textColor: .purple,
                                            cardColor: .purple,
                                            logoTextColor: .purple))
            }

            return wallpapers
        }

        mockManager.mockAvailableCollections = [
            WallpaperCollection(
                id: WallpaperCollection.classicFirefoxID,
                learnMoreURL: nil,
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForOther,
                description: nil,
                heading: nil),
            WallpaperCollection(
                id: "otherCollection",
                learnMoreURL: "https://www.mozilla.com",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForOther,
                description: nil,
                heading: nil)
        ]
    }
}
