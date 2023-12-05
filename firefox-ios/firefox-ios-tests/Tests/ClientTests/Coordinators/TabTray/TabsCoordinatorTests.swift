// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TabsCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var parentCoordinator: MockTabTrayCoordinatorDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockTabTrayCoordinatorDelegate()
    }

    override func tearDown() {
        super.tearDown()
        mockRouter = nil
        parentCoordinator = nil
        DependencyHelperMock().reset()
    }

    func testInitialState() {
        let subject = createSubject()

        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> TabsCoordinator {
        let subject = TabsCoordinator(parentCoordinator: parentCoordinator, router: mockRouter)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
