// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import XCTest

@testable import Client

final class MainMenuCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() {
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testInitialState() {
        _ = createSubject()

        XCTAssertFalse(mockRouter.rootViewController is MicrosurveyViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        XCTAssertEqual(mockRouter.pushCalled, 0)
        XCTAssertEqual(mockRouter.popViewControllerCalled, 0)
    }

    func testStart_presentsMainMenuController() throws {
        let subject = createSubject()

        subject.start()

        XCTAssertTrue(mockRouter.rootViewController is MainMenuViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testShowDetailViewController() {
        let subject = createSubject()
        let mockData = [MenuSection(options: [])]

        subject.start()
        subject.showDetailViewController(with: mockData)

        XCTAssertTrue(mockRouter.pushedViewController is MainMenuDetailViewController)
        XCTAssertEqual(mockRouter.pushCalled, 1)
    }

    func testDismissDetailViewController() {
        let subject = createSubject()
        let mockData = [MenuSection(options: [])]

        subject.start()
        subject.showDetailViewController(with: mockData)
        subject.dismissDetailViewController()

        XCTAssertTrue(mockRouter.rootViewController is MainMenuViewController)
        XCTAssertEqual(mockRouter.popViewControllerCalled, 1)
    }

    func testMainMenu_dismissFlow_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.start()
        subject.dismissMenuModal(animated: false)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    private func createSubject(
        file: StaticString = #file,
        line: UInt = #line
    ) -> MainMenuCoordinator {
        let subject = MainMenuCoordinator(router: mockRouter, windowUUID: .XCTestDefaultUUID)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
