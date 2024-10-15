// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class NativeErrorPageViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testNativeErrorPageViewController_simpleCreation_hasNoLeaks() {
        let overlayManager = MockOverlayModeManager()
        let nativeErrroPageViewController = NativeErrorPageViewController(
            model: NativeErrorPageMock.model,
            windowUUID: windowUUID,
            overlayManager: overlayManager
        )
        trackForMemoryLeaks(nativeErrroPageViewController)
    }
}
