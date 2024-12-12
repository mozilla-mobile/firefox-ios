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
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        wallpaperManager = nil
        super.tearDown()
    }

    func testInit_hasCorrectNumberOfWallpapers() {
        let subject = createSubject()
        let expectedLayout: WallpaperSelectorViewModel.WallpaperSelectorLayout = .compact
        XCTAssertEqual(subject.sectionLayout, expectedLayout)
        XCTAssertEqual(subject.numberOfWallpapers, expectedLayout.maxItemsToDisplay)
    }

    func testUpdateSectionLayout_regularLayout_hasCorrectNumberOfWallpapers() {
        let subject = createSubject()
        let expectedLayout: WallpaperSelectorViewModel.WallpaperSelectorLayout = .regular

        let landscapeTrait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.updateSectionLayout(for: landscapeTrait)

        XCTAssertEqual(subject.sectionLayout, expectedLayout)
        XCTAssertEqual(subject.numberOfWallpapers, expectedLayout.maxItemsToDisplay)
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

    func testRecordsWallpaperSelectorView() {
        wallpaperManager = WallpaperManager()
        let subject = createSubject()
        subject.sendImpressionTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.wallpaperSelectorView)
    }

    func testRecordsWallpaperSelectorClose() {
        wallpaperManager = WallpaperManager()
        let subject = createSubject()
        subject.sendDismissImpressionTelemetry()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.wallpaperSelectorClose)
    }

//    func testClickingCell_recordsWallpaperChange() {
//        let subject = createSubject()
//
//        let expectation = self.expectation(description: "Download and set wallpaper")
//        subject.downloadAndSetWallpaper(at: IndexPath(item: 0, section: 0)) { _ in
//            self.testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.wallpaperSelectorSelected)
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }

    func createSubject() -> WallpaperSelectorViewModel {
        let subject = WallpaperSelectorViewModel(wallpaperManager: wallpaperManager)
        trackForMemoryLeaks(subject)
        return subject
    }

    func addWallpaperCollections() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        var wallpapersForClassic: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            wallpapers.append(Wallpaper(id: "fxDefault",
                                        textColor: .green,
                                        cardColor: .purple,
                                        logoTextColor: .purple))

            for _ in 0..<4 {
                wallpapers.append(Wallpaper(id: "fxAmethyst",
                                            textColor: .red,
                                            cardColor: .purple,
                                            logoTextColor: .purple))
            }

            return wallpapers
        }

        var wallpapersForOther: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            let rangeEnd = Int.random(in: 3...6)
            for _ in 0..<rangeEnd {
                wallpapers.append(Wallpaper(id: "fxCerulean",
                                            textColor: .purple,
                                            cardColor: .purple,
                                            logoTextColor: .purple))
            }

            return wallpapers
        }

        mockManager.mockAvailableCollections = [
            WallpaperCollection(
                id: "classic-firefox",
                learnMoreURL: nil,
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForClassic,
                description: nil,
                heading: nil),
            WallpaperCollection(
                id: "otherCollection",
                learnMoreURL: "https://www.mozilla.com",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForOther,
                description: nil,
                heading: nil),
        ]
    }
}
