// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Common
@testable import Client

final class SceneCoordinatorTests: XCTestCase {
    var profile: MockProfile!
    var launchManager: MockLaunchManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        launchManager = MockLaunchManager()
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
        launchManager = nil
    }

    func testInitialState() {
        let scene = UIApplication.shared.windows.first?.windowScene
        let subject = SceneCoordinator(scene: scene!)
        XCTAssertNotNil(subject.window)
        XCTAssertNil(subject.browserCoordinator)
        XCTAssertNil(subject.launchCoordinator)
    }

    func testStartBrowserCoordinator_withoutCanLaunchfromScene() {
        let scene = UIApplication.shared.windows.first?.windowScene
        let subject = SceneCoordinator(scene: scene!)

        launchManager.canLaunchFromSceneCoordinator = false
        launchManager.mockLaunchType = nil
        subject.start(with: launchManager)

        XCTAssertNotNil(subject.window)
        XCTAssertNotNil(subject.browserCoordinator)
        XCTAssertNil(subject.launchCoordinator)
    }

    func testStartBrowserCoordinator_withoutLaunchType() {
        let scene = UIApplication.shared.windows.first?.windowScene
        let subject = SceneCoordinator(scene: scene!)

        launchManager.canLaunchFromSceneCoordinator = true
        launchManager.mockLaunchType = nil
        subject.start(with: launchManager)

        XCTAssertNotNil(subject.window)
        XCTAssertNotNil(subject.browserCoordinator)
        XCTAssertNil(subject.launchCoordinator)
    }

    func testStartLaunchCoordinator() {
        let scene = UIApplication.shared.windows.first?.windowScene
        let subject = SceneCoordinator(scene: scene!)

        launchManager.canLaunchFromSceneCoordinator = true
        launchManager.mockLaunchType = .intro
        subject.start(with: launchManager)

        XCTAssertNotNil(subject.window)
        XCTAssertNil(subject.browserCoordinator)
        XCTAssertNotNil(subject.launchCoordinator)
    }

    func testEnsureCoordinatorIsntEnabled() {
        XCTAssertFalse(AppConstants.useCoordinators)
    }
}
