// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

final class SearchEngineSelectionCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
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
    }

    func testNavigateToSearchSettings_callsDismiss() throws {
        let subject = createSubject()

        subject.start()
        subject.navigateToSearchSettings(animated: false)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    private func createSubject(file: StaticString = #file, line: UInt = #line) -> SearchEngineSelectionCoordinator {
        let subject = SearchEngineSelectionCoordinator(router: mockRouter, windowUUID: .XCTestDefaultUUID)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
