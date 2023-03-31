// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Common
@testable import Client

final class SceneCoordinatorTests: XCTestCase {
    var profile: MockProfile!
    var navigationController: NavigationController!
    var router: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        navigationController = MockNavigationController()
        router = MockRouter(navigationController: navigationController)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
        navigationController = nil
        router = nil
    }

    func testInitialState() {
        let subject = SceneCoordinator(router: router)
        XCTAssertNil(subject.browserCoordinator)
    }

    func testInitScene_createObjects() {
        let subject = SceneCoordinator(router: router)
        subject.start()
        XCTAssertNotNil(subject.launchCoordinator)
    }

    func testEnsureCoordinatorIsntEnabled() {
        XCTAssertFalse(AppConstants.useCoordinators)
    }
}
