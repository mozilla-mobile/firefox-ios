// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import ComponentLibrary
@testable import Client

class HomepageCoordinatorTests: XCTestCase {
    var profile: MockProfile!
    var wallpaperManager: WallpaperManagerMock!
    var router: MockRouter!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        wallpaperManager = WallpaperManagerMock()
        router = MockRouter(navigationController: MockNavigationController())
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        profile = nil
        wallpaperManager = nil
        router = nil
    }

    func test_showWallpaperSelectionOnboarding_withNoZeroSearch_doesNotPresentWallpaperSelection() {
        let coordinator = HomepageCoordinator(
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            wallpaperManager: wallpaperManager,
            isZeroSearch: false,
            router: router
        )
        trackForMemoryLeaks(coordinator)
        coordinator.showWallpaperSelectionOnboarding(true)
        XCTAssertNil(router.presentedViewController)
    }

    func test_showWallpaperSelectionOnboarding_withZeroSearch_doesPresentWallpaperSelection() {
        let coordinator = HomepageCoordinator(
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            wallpaperManager: wallpaperManager,
            isZeroSearch: true,
            router: router
        )
        trackForMemoryLeaks(coordinator)
        coordinator.showWallpaperSelectionOnboarding(true)
        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is BottomSheetViewController)
    }

    func test_showWallpaperSelectionOnboarding_withCanPresentModallyIsFalse_doesNotPresentWallpaperSelection() {
        let coordinator = HomepageCoordinator(
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            wallpaperManager: wallpaperManager,
            isZeroSearch: true,
            router: router
        )
        trackForMemoryLeaks(coordinator)
        coordinator.showWallpaperSelectionOnboarding(false)
        XCTAssertNil(router.presentedViewController)
    }

    func test_showWallpaperSelectionOnboarding_RouterAlreadyPresenting_doesNotPresentWallpaperSelection() {
        router.presentCalled = 1
        let coordinator = HomepageCoordinator(
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            wallpaperManager: wallpaperManager,
            isZeroSearch: true,
            router: router
        )
        trackForMemoryLeaks(coordinator)
        coordinator.showWallpaperSelectionOnboarding(true)
        XCTAssertNil(router.presentedViewController)
    }
}
