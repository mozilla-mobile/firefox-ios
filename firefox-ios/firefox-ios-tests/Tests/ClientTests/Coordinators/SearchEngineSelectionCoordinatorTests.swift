// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

final class SearchEngineSelectionCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var mockParentCoordinator: MockParentCoordinator!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
        mockParentCoordinator = MockParentCoordinator()
    }

    func testInitialState() {
        _ = createSubject()

        XCTAssertFalse(mockRouter.rootViewController is MicrosurveyViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        XCTAssertEqual(mockRouter.pushCalled, 0)
        XCTAssertEqual(mockRouter.popViewControllerCalled, 0)
    }

    func testStart_presentsSearchEngineSelectionViewController() throws {
        let subject = createSubject()

        subject.start()

        XCTAssertTrue(mockRouter.rootViewController is SearchEngineSelectionViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertEqual(mockRouter.isNavigationBarHidden, true)
    }

    func testDismissModal_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.start()
        subject.dismissModal(animated: false)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    func testDismissModal_callsParentCoordinatorDidFinish() throws {
        let subject = createSubject()

        subject.start()
        subject.dismissModal(animated: false)

        XCTAssertEqual(mockParentCoordinator.didFinishCalled, 1)
    }

    func testNavigateToSearchSettings_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.start()
        subject.navigateToSearchSettings(animated: false)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    private func createSubject(file: StaticString = #file, line: UInt = #line) -> SearchEngineSelectionCoordinator {
        let subject = SearchEngineSelectionCoordinator(router: mockRouter, windowUUID: .XCTestDefaultUUID)
        subject.parentCoordinator = mockParentCoordinator

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
