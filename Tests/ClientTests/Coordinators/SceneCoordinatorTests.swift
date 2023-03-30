// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Common
@testable import Client

final class SceneCoordinatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
    }

    func testInitialState() {
        let subject = SceneCoordinator()

        XCTAssertNil(subject.window)
        XCTAssertNil(subject.browserCoordinator)
    }

    func testInitScene_createObjects() {
        let subject = SceneCoordinator()

        let scene = UIApplication.shared.windows.first?.windowScene
        subject.start(with: scene!)

        XCTAssertNotNil(subject.window)
        XCTAssertNotNil(subject.browserCoordinator)
    }

    func testEnsureCoordinatorIsntEnabled() {
        XCTAssertFalse(AppConstants.useCoordinators)
    }
}
