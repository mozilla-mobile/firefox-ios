// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class TabsCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() async throws {
        mockRouter = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testInitialState() {
        let subject = createSubject()

        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> TabsCoordinator {
        let subject = TabsCoordinator(router: mockRouter)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
