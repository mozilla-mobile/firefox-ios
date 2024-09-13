// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import XCTest

@testable import Client

final class MainMenuCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var mockTabManager: MockTabManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
        mockTabManager = MockTabManager()
    }

    override func tearDown() {
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(mockRouter.presentCalled, 0)
    }

    func testStart_presentsMainMenuController() throws {
        let subject = createSubject()

        subject.start()

        guard let presentedVC = mockRouter.presentedViewController else {
            XCTFail("No view controller is presented.")
            return
        }

        XCTAssertTrue(presentedVC is UINavigationController)
        XCTAssertEqual(mockRouter.presentCalled, 1)

        let navController = presentedVC as? UINavigationController

        XCTAssertTrue(navController?.topViewController is MainMenuViewController)
    }

    func testShowDetailViewController() {
        let subject = createSubject()
        let mockData = [MenuSection(options: [])]

        subject.start()
        guard let presentedVC = mockRouter.presentedViewController else {
            XCTFail("No view controller is presented.")
            return
        }

        subject.showDetailViewController(with: mockData)

        let expectation = self.expectation(description: "Detail View Controller Presented")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let navController = presentedVC as? UINavigationController
            if navController?.topViewController is MainMenuDetailViewController {
                expectation.fulfill()
            } else {
                XCTFail("MainMenuDetailViewController is not visible.")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDismissDetailViewController() {
        let subject = createSubject()
        let mockData = [MenuSection(options: [])]

        subject.start()
        guard let presentedVC = mockRouter.presentedViewController else {
            XCTFail("No view controller is presented.")
            return
        }

        subject.showDetailViewController(with: mockData)
        subject.dismissDetailViewController()

        let expectation = self.expectation(description: "Menu View Controller Presented")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let navController = presentedVC as? UINavigationController
            if navController?.topViewController is MainMenuViewController {
                expectation.fulfill()
            } else {
                XCTFail("MainMenuViewController is not visible.")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
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
