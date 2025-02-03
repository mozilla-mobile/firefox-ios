// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class PrivateHomepageViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override class func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testPrivateHomepageViewController_simpleCreation_hasNoLeaks() {
        let overlayManager = MockOverlayModeManager()
        let privateHomeViewController = PrivateHomepageViewController(windowUUID: windowUUID, overlayManager: overlayManager)

        trackForMemoryLeaks(privateHomeViewController)
    }
}
