// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import ComponentLibrary
@testable import Client

class HomepageCoordinatorTests: XCTestCase {
    var coordinator: HomepageCoordinator!
    let profile = MockProfile()
    let wallpaperManger = WallpaperManagerMock()
    let router = MockRouter(navigationController: MockNavigationController())

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    func test_showWallpaperSelectionOnboarding_withNoZeroSearch_doesNotPresentWallpaperSelection() {
        coordinator = HomepageCoordinator(
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            wallpaperManger: wallpaperManger,
            isZeroSearch: false,
            router: router
        )
        coordinator.showWallpaperSelectionOnboarding(true)
        XCTAssertNil(router.presentedViewController)
    }

    func test_showWallpaperSelectionOnboarding_withZeroSearch_doesPresentWallpaperSelection() {
        coordinator = HomepageCoordinator(
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            wallpaperManger: wallpaperManger,
            isZeroSearch: true,
            router: router
        )
        coordinator.showWallpaperSelectionOnboarding(true)
        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is BottomSheetViewController)
    }

    func test_showWallpaperSelectionOnboarding_withCanPresentModallyIsFalse_doesNotPresentWallpaperSelection() {
        coordinator = HomepageCoordinator(
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            wallpaperManger: wallpaperManger,
            isZeroSearch: true,
            router: router
        )
        coordinator.showWallpaperSelectionOnboarding(false)
        XCTAssertNil(router.presentedViewController)
    }

    func test_showWallpaperSelectionOnboarding_RouterAlreadyPresnting_doesNotPresentWallpaperSelection() {
        router.presentCalled = 1
        coordinator = HomepageCoordinator(
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            wallpaperManger: wallpaperManger,
            isZeroSearch: true,
            router: router
        )
        coordinator.showWallpaperSelectionOnboarding(true)
        XCTAssertNil(router.presentedViewController)
    }
}
