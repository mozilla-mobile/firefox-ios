// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class PrivateHomepageViewControllerTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testPrivateHomepageViewController_simpleCreation_hasNoLeaks() {
        let overlayManager = MockOverlayModeManager()
        let privateHomeViewController = PrivateHomepageViewController(overlayManager: overlayManager)

        trackForMemoryLeaks(privateHomeViewController)
    }
}
