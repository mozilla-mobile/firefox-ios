// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import ComponentLibrary
import Shared
import TestKit

@testable import Client

@MainActor
final class WallpaperEngagementCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var prefs: MockProfilePrefs!
    private var featureFlagsProvider: MockNimbusFeatureFlags!
    private var wallpaperManager: WallpaperManagerMock!
    private var parentCoordinator: MockParentCoordinator!
    private var tabManager: MockTabManager!
    private let marketingSlug = "wallpaper-drop-1"

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        router = MockRouter(navigationController: MockNavigationController())
        prefs = MockProfilePrefs()
        featureFlagsProvider = MockNimbusFeatureFlags()
        featureFlagsProvider.enabledFlags = [.wallpaperEngagementSheet]
        wallpaperManager = WallpaperManagerMock()
        parentCoordinator = MockParentCoordinator()
        tabManager = MockTabManager()
        tabManager.selectedTab = makeTab()
        setMarketingSlug(marketingSlug)
    }

    override func tearDown() async throws {
        router = nil
        prefs = nil
        featureFlagsProvider = nil
        wallpaperManager = nil
        parentCoordinator = nil
        tabManager = nil
        setMarketingSlug("")
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - shouldShow

    func test_shouldShow_whenNoSelectedTab_returnsFalse() {
        tabManager.selectedTab = nil
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenSelectedTabIsNotHomepage_returnsFalse() {
        tabManager.selectedTab = makeTab(isHomePage: false)
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenSelectedTabIsPrivate_returnsFalse() {
        tabManager.selectedTab = makeTab(isPrivate: true)
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenFlagDisabled_returnsFalse() {
        featureFlagsProvider.enabledFlags = []
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenMarketingSlugIsEmpty_returnsFalse() {
        setMarketingSlug("")
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenWallpapersAreNotAvailable_returnsFalse() {
        wallpaperManager.canSettingsBeShown = false
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenStoredSlugEqualsMarketingSlug_returnsFalse() {
        prefs.setString(marketingSlug, forKey: PrefsKeys.Wallpapers.EngagementSheetShownMarketingSlug)
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenMarketingSlugIsNew_returnsTrue() {
        prefs.setString("previous-wallpaper-drop", forKey: PrefsKeys.Wallpapers.EngagementSheetShownMarketingSlug)
        let subject = createSubject()

        XCTAssertTrue(subject.shouldShow())
    }

    func test_shouldShow_whenNothingStored_returnsTrue() {
        let subject = createSubject()

        XCTAssertTrue(subject.shouldShow())
    }

    // MARK: - start

    func test_start_presentsBottomSheet() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
    }

    func test_start_storesMarketingSlug() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(prefs.stringForKey(PrefsKeys.Wallpapers.EngagementSheetShownMarketingSlug), marketingSlug)
        XCTAssertFalse(subject.shouldShow())
    }

    func test_start_whenPresentationIsDismissed_notifiesParent() {
        let subject = createSubject()
        subject.start()

        router.savedCompletion?()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func test_start_whenCloseButtonIsTapped_notifiesParent() throws {
        let subject = createSubject()
        subject.start()
        let bottomSheet = try XCTUnwrap(router.presentedViewController as? NativeBottomSheetViewController)

        bottomSheet.onDismiss?()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> WallpaperEngagementCoordinator {
        let subject = WallpaperEngagementCoordinator(
            router: router,
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            prefs: prefs,
            wallpaperManager: wallpaperManager,
            featureFlagsProvider: featureFlagsProvider
        )
        subject.parentCoordinator = parentCoordinator
        trackForMemoryLeaks(subject)
        return subject
    }

    private func makeTab(isPrivate: Bool = false, isHomePage: Bool = true) -> Tab {
        return MockTab(
            profile: makeProfile(),
            isPrivate: isPrivate,
            windowUUID: .XCTestDefaultUUID,
            isHomePage: isHomePage
        )
    }

    private func setMarketingSlug(_ slug: String) {
        FxNimbus.shared.features.wallpaperEngagementSheetFeature.with(initializer: { _ in
            WallpaperEngagementSheetFeature(enabled: true, marketingSlug: slug)
        })
    }
}
