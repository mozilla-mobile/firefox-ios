// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import OnboardingKit
import XCTest

@testable import Client

private class MockWallpaperTelemetryUtility: OnboardingTelemetryProtocol {
    var wallpaperSelectorViewCalled = false
    var wallpaperSelectorCloseCalled = false
    var wallpaperSelectorSelectedName: String?
    var wallpaperSelectorSelectedType: String?

    func sendCardViewTelemetry(from cardName: String) {}
    func sendButtonActionTelemetry(from cardName: String, with action: OnboardingActions, and primaryButton: Bool) {}
    func sendMultipleChoiceButtonActionTelemetry(from cardName: String, with action: OnboardingMultipleChoiceAction) {}
    func sendDismissOnboardingTelemetry(from cardName: String) {}
    func sendGoToSettingsButtonTappedTelemetry() {}
    func sendDismissButtonTappedTelemetry() {}
    func sendOnboardingShownTelemetry() {}
    func sendOnboardingDismissedTelemetry(outcome: OnboardingFlowOutcome) {}

    func sendWallpaperSelectorViewTelemetry() { wallpaperSelectorViewCalled = true }
    func sendWallpaperSelectorCloseTelemetry() { wallpaperSelectorCloseCalled = true }
    func sendWallpaperSelectorSelectedTelemetry(wallpaperName: String, wallpaperType: String) {
        wallpaperSelectorSelectedName = wallpaperName
        wallpaperSelectorSelectedType = wallpaperType
    }
    func sendWallpaperSelectedTelemetry(wallpaperName: String, wallpaperType: String) {}
    func sendEngagementNotificationTappedTelemetry() {}
    func sendEngagementNotificationCancelTelemetry() {}
}

@MainActor
final class WallpaperSelectorViewModelTests: XCTestCase {
    private var wallpaperManager: WallpaperManagerInterface!
    private var mockTelemetry: MockWallpaperTelemetryUtility!

    override func setUp() async throws {
        try await super.setUp()

        wallpaperManager = WallpaperManagerMock()
        mockTelemetry = MockWallpaperTelemetryUtility()
        addWallpaperCollections()
    }

    override func tearDown() async throws {
        wallpaperManager = nil
        mockTelemetry = nil
        try await super.tearDown()
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

        subject.downloadAndSetWallpaper(at: indexPath) { [mockManager] result in
            XCTAssertEqual(subject.selectedIndexPath, indexPath)
            XCTAssertEqual(mockManager.setCurrentWallpaperCallCount, 1)
        }
    }

    func testRecordsWallpaperSelectorView() {
        let subject = createSubject()
        subject.sendImpressionTelemetry()
        XCTAssertTrue(mockTelemetry.wallpaperSelectorViewCalled)
    }

    func testRecordsWallpaperSelectorClose() {
        let subject = createSubject()
        subject.sendDismissImpressionTelemetry()
        XCTAssertTrue(mockTelemetry.wallpaperSelectorCloseCalled)
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
        let subject = WallpaperSelectorViewModel(
            wallpaperManager: wallpaperManager,
            telemetryUtility: mockTelemetry
        )
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
