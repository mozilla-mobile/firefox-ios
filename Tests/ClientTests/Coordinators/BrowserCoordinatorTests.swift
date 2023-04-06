// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

final class BrowserCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.profile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()
        self.mockRouter = nil
        self.profile = nil
        AppContainer.shared.reset()
    }

    func testInitialState() {
        let subject = createSubject()

        XCTAssertNotNil(subject.browserViewController)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
    }

    func testWithoutLaunchType_startsBrowserOnly() {
        let subject = createSubject()
        subject.start(with: nil)

        XCTAssertNotNil(mockRouter.rootViewController as? BrowserViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testWithLaunchType_startsLaunchCoordinator() {
        let subject = createSubject()
        subject.start(with: .defaultBrowser)

        XCTAssertNotNil(mockRouter.rootViewController as? BrowserViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }

    func testChildLaunchCoordinatorIsDone_deallocatesAndDismiss() throws {
        let subject = createSubject()
        subject.start(with: .defaultBrowser)

        let childLaunchCoordinator = try XCTUnwrap(subject.childCoordinators[0] as? LaunchCoordinator)
        subject.didFinishLaunch(from: childLaunchCoordinator)

        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> BrowserCoordinator {
        let subject = BrowserCoordinator(router: mockRouter, profile: profile)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
