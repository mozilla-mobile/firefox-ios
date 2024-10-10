// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class FirefoxAccountSignInViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var mockProfile: MockProfile!
    var deeplinkParams: FxALaunchParams!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        deeplinkParams = FxALaunchParams(entrypoint: .browserMenu, query: ["test_key": "test_value"])
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testFirefoxAccountSignInViewController_simpleCreation_hasNoLeaks() {
        let testFirefoxAccountSignInViewController = FirefoxAccountSignInViewController(
            profile: mockProfile,
            parentType: .appMenu,
            deepLinkParams: deeplinkParams,
            windowUUID: windowUUID
        )
        trackForMemoryLeaks(testFirefoxAccountSignInViewController)
    }
}
