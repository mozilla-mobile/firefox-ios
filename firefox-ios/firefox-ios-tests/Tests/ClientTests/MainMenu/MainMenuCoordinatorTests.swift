// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
        super.tearDown()
        AppContainer.shared.reset()
    }

    func testInitialState() {
        _ = createSubject()

        XCTAssertFalse(mockRouter.presentedViewController is MainMenuViewController)
        XCTAssertEqual(mockRouter.presentCalled, 0)
    }

    func testStart_presentsMainMenuController() throws {
        let subject = createSubject()

        subject.showMenuModal()

        XCTAssertTrue(mockRouter.presentedViewController is MainMenuViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    func testMainMenu_dismissFlow_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.showMenuModal()
        subject.dismissMenuModal(animated: false)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    private func createSubject(
        file: StaticString = #file,
        line: UInt = #line
    ) -> MainMenuCoordinator {
        let subject = MainMenuCoordinator(router: mockRouter, tabManager: mockTabManager)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
