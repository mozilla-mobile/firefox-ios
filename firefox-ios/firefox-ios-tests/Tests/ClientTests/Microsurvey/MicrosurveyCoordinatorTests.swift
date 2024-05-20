// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class MicrosurveyCoordinatorTests: XCTestCase {
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

        XCTAssertFalse(mockRouter.rootViewController is MicrosurveyViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
    }

    func testStart_presentsMicrosurveyController() throws {
        let subject = createSubject()

        subject.start()

        XCTAssertTrue(mockRouter.rootViewController is MicrosurveyViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testMicrosurveyDelegate_dismissFlow_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.start()
        subject.dismissFlow()

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    func testMicrosurveyDelegate_showPrivacy_callsRouterDismiss_andCreatesNewTab() throws {
        let subject = createSubject()

        subject.start()
        subject.showPrivacy()

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertEqual(mockTabManager.addTabsForURLsCalled, 1)
        XCTAssertEqual(mockTabManager.addTabsURLs, [URL(string: "https://www.mozilla.org/privacy/firefox")])
    }

    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> MicrosurveyCoordinator {
        let subject = MicrosurveyCoordinator(model: MicrosurveyModel(), router: mockRouter, tabManager: mockTabManager)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
