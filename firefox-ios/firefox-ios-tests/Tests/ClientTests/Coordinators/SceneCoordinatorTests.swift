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
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() {
        super.tearDown()
        mockRouter = nil
        AppContainer.shared.reset()
    }

    func testInitialState() {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let subject = SceneCoordinator(scene: scene!)
        trackForMemoryLeaks(subject)

        XCTAssertNotNil(subject.window)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testStart_rootViewIsSceneContainer() {
        let subject = createSubject()
        subject.start()

        XCTAssertNotNil(subject.window)
        XCTAssertNotNil(mockRouter.rootViewController as? SceneContainer)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testStart_startsLaunchScreen() {
        let subject = createSubject()
        subject.start()

        XCTAssertNotNil(mockRouter.pushedViewController as? LaunchScreenViewController)
        XCTAssertEqual(mockRouter.pushCalled, 1)
    }

    func testLaunchWithLaunchType_launchFromScene() {
        let subject = createSubject()
        subject.launchWith(launchType: .intro(manager: IntroScreenManager(prefs: MockProfile().prefs)))

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators.first as? LaunchCoordinator)
    }

    func testLaunchWithLaunchType_launchFromBrowser() {
        let subject = createSubject()
        subject.launchWith(launchType: .defaultBrowser)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators.first as? BrowserCoordinator)
    }

    func testLaunchBrowser_onlyStartsOnce() {
        let subject = createSubject()
        subject.launchBrowser()
        subject.launchBrowser()

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators.first as? BrowserCoordinator)
    }

    func testChildLaunchCoordinatorIsDone_startsBrowser() throws {
        let subject = createSubject()
        subject.launchWith(launchType: .intro(manager: IntroScreenManager(prefs: MockProfile().prefs)))

        let childLaunchCoordinator = try XCTUnwrap(subject.childCoordinators.first as? LaunchCoordinator)
        subject.didFinishLaunch(from: childLaunchCoordinator)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators.first as? BrowserCoordinator)
    }

    func testHandleRoute_launchNotFinished_routeSaved() {
        let subject = createSubject()

        subject.start()
        let coordinator = subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        XCTAssertNil(coordinator)
        XCTAssertNotNil(subject.savedRoute)
    }

    func testHandleRoute_launchFinishedAndBrowserNotReady_routeSaved() throws {
        let subject = createSubject()

        subject.start()
        subject.launchBrowser()
        let coordinator = subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        XCTAssertNil(coordinator)
        XCTAssertNotNil(subject.savedRoute)
        let browserCoordinator = try XCTUnwrap(subject.childCoordinators.first as? BrowserCoordinator)
        XCTAssertNotNil(browserCoordinator.savedRoute)
    }

    func testHandleRoute_launchFinishedAndBrowserReady_routeSavedCalled() throws {
        let subject = createSubject()

        subject.start()
        subject.launchBrowser()
        let browserCoordinator = try XCTUnwrap(subject.childCoordinators.first as? BrowserCoordinator)
        browserCoordinator.browserHasLoaded()
        let coordinator = subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        XCTAssertNotNil(coordinator)
        XCTAssertNil(subject.savedRoute)
    }

    // MARK: - Handle route

    func testHandleShowOnboarding_returnsTrueAndShowsOnboarding() {
        let subject = createSubject()

        let result = testCanHandleAndHandle(subject, route: .action(action: .showIntroOnboarding))

        XCTAssertTrue(result)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators.first as? LaunchCoordinator)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> SceneCoordinator {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let subject = SceneCoordinator(scene: scene!)
        // Replace created router from scene with a mock router so we don't trigger real navigation in our tests
        subject.router = mockRouter
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func testCanHandleAndHandle(_ subject: Coordinator, route: Route) -> Bool {
        let result = subject.canHandle(route: route)
        subject.handle(route: route)
        return result
    }
}
