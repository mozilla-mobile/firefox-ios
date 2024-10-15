// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class PasswordGeneratorViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testPasswordGeneratorViewController_simpleCreation_hasNoLeaks() {
        let mockProfile = MockProfile()
        let currentTab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let passwordGeneratorViewController = PasswordGeneratorViewController(windowUUID: windowUUID, currentTab: currentTab)
        trackForMemoryLeaks(passwordGeneratorViewController)
    }
}
