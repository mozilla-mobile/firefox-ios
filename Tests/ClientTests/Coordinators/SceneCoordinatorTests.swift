// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Common
@testable import Client

final class SceneCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() {
        super.tearDown()
        mockRouter = nil
        AppContainer.shared.reset()
    }

    func testInitialState() {
        let scene = UIApplication.shared.windows.first?.windowScene
        let launchScreenManager = MockLaunchScreenManager(profile: MockProfile())
        let subject = SceneCoordinator(scene: scene!, launchScreenManager: launchScreenManager)
        trackForMemoryLeaks(subject)

        XCTAssertNotNil(subject.window)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(launchScreenManager.setOpenURLDelegateCalled, 1)
    }

    func testStart_startsLaunchScreen() {
        let launchScreenManager = MockLaunchScreenManager(profile: MockProfile())
        let subject = createSubject(launchScreenManager: launchScreenManager)
        subject.start()

        XCTAssertNotNil(subject.window)
        XCTAssertNotNil(mockRouter.rootViewController as? LaunchScreenViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testLaunchTypeLoaded_noLaunchType_launchBrowser() {
        let launchScreenManager = MockLaunchScreenManager(profile: MockProfile())
        launchScreenManager.mockLaunchType = nil
        let subject = createSubject(launchScreenManager: launchScreenManager)
        subject.launchTypeLoaded()

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? BrowserCoordinator)
    }

    func testLaunchTypeLoaded_withLaunchType_launchCoordinator() {
        let launchScreenManager = MockLaunchScreenManager(profile: MockProfile())
        launchScreenManager.mockLaunchType = .intro
        let subject = createSubject(launchScreenManager: launchScreenManager)
        subject.launchTypeLoaded()

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }

    func testEnsureCoordinatorIsntEnabled() {
        XCTAssertFalse(AppConstants.useCoordinators)
    }

    // MARK: - Helpers
    func createSubject(launchScreenManager: MockLaunchScreenManager,
                       file: StaticString = #file,
                       line: UInt = #line) -> SceneCoordinator {
        let scene = UIApplication.shared.windows.first?.windowScene
        let subject = SceneCoordinator(scene: scene!, launchScreenManager: launchScreenManager)
        // Replace created router from scene with a mock router so we don't trigger real navigation in our tests
        subject.router = mockRouter
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
