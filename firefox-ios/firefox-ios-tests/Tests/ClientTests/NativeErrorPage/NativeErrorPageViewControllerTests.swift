// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

@MainActor
final class NativeErrorPageViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testNativeErrorPageViewController_simpleCreation_hasNoLeaks() {
        let overlayManager = MockOverlayModeManager()
        let tabManager = MockTabManager()
        let nativeErrroPageViewController = NativeErrorPageViewController(
            windowUUID: windowUUID,
            overlayManager: overlayManager,
            tabManager: tabManager
        )
        trackForMemoryLeaks(nativeErrroPageViewController)
    }
}
