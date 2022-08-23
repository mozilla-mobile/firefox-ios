// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

class WallpaperSelectorViewModelTests: XCTestCase {

    private var wallpaperManager: WallpaperManagerInterface!

    override func setUp() {
        super.setUp()

        wallpaperManager = WallpaperManagerMock()
        addWallpaperCollections()

        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        wallpaperManager = nil
        super.tearDown()
    }

    func testInit_hasCorrectNumberOfWallpapers() {
        let sut = createSut()
        let expectedLayout: WallpaperSelectorViewModel.WallpaperSelectorLayout = .compact
        XCTAssert(sut.sectionLayout == expectedLayout)
        XCTAssert(sut.numberOfWallpapers == expectedLayout.maxItemsToDisplay)
    }

    func testUpdateSectionLayout_regularLayout_hasCorrectNumberOfWallpapers() {
        let sut = createSut()
        let expectedLayout: WallpaperSelectorViewModel.WallpaperSelectorLayout = .regular

        let landscapeTrait = MockTraitCollection()
        landscapeTrait.overridenHorizontalSizeClass = .regular
        landscapeTrait.overridenVerticalSizeClass = .compact

        sut.updateSectionLayout(for: landscapeTrait)

        XCTAssert(sut.sectionLayout == expectedLayout)
        XCTAssert(sut.numberOfWallpapers == expectedLayout.maxItemsToDisplay)
    }

    func testDownloadAndSetWallpaper_downloaded_wallpaperIsSet() {
        let sut = createSut()
        let indexPath = IndexPath(item: 1, section: 0)
        let expectation = self.expectation(description: "Download and set wallpaper")

        sut.downloadAndSetWallpaper(at: indexPath) { result in
            let wallpaperCellModel = sut.cellViewModel(for: indexPath)!
            XCTAssertTrue(wallpaperCellModel.isSelected)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRecordsWallpaperSelectorView() {
        wallpaperManager = WallpaperManager()
        let sut = createSut()
        sut.sendImpressionTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.wallpaperSelectorView)
    }

    func testRecordsWallpaperSelectorClose() {
        wallpaperManager = WallpaperManager()
        let sut = createSut()
        sut.sendDismissImpressionTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.wallpaperSelectorClose)
    }

    func testClickingCell_recordsWallpaperChange() {
        wallpaperManager = WallpaperManager()
        let sut = createSut()
        sut.downloadAndSetWallpaper(at: IndexPath(item: 0, section: 0)) { _ in }

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.wallpaperSelectorSelected)
    }

    func createSut() -> WallpaperSelectorViewModel {
        let sut = WallpaperSelectorViewModel(wallpaperManager: wallpaperManager) { }
        trackForMemoryLeaks(sut)
        return sut
    }

    func addWallpaperCollections() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        var wallpapersForClassic: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            wallpapers.append(Wallpaper(id: "fxDefault", textColour: UIColor.green))

            for _ in 0..<4 {
                wallpapers.append(Wallpaper(id: "fxAmethyst", textColour: UIColor.red))
            }

            return wallpapers
        }

        var wallpapersForOther: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            let rangeEnd = Int.random(in: 3...6)
            for _ in 0..<rangeEnd {
                wallpapers.append(Wallpaper(id: "fxCerulean", textColour: UIColor.purple))
            }

            return wallpapers
        }

        mockManager.mockAvailableCollections = [
            WallpaperCollection(
                id: "classicFirefox",
                learnMoreURL: nil,
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForClassic),
            WallpaperCollection(
                id: "otherCollection",
                learnMoreURL: "https://www.mozilla.com",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForOther),
        ]
    }

}
