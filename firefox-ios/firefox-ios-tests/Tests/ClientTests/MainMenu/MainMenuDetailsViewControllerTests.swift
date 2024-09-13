// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import MenuKit
import XCTest

@testable import Client

final class MainMenuDetailsViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testMainMenuDetailsViewController_simpleCreation_hasNoLeaks() {
        let controller = MainMenuDetailViewController(
            windowUUID: windowUUID,
            with: [MenuSection(options: [])]
        )
        trackForMemoryLeaks(controller)
    }
}
