// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class HistoryCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var profile: MockProfile!
    private var parentCoordinator: MockLibraryCoordinatorDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        router = MockRouter(navigationController: UINavigationController())
        profile = MockProfile()
        parentCoordinator = MockLibraryCoordinatorDelegate()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        router = nil
        profile = nil
        parentCoordinator = nil
    }

    func testShowRecentlyClosedTabs() {
        let subject = createSubject()

        subject.showRecentlyClosedTab()

        XCTAssertTrue(router.pushedViewController is RecentlyClosedTabsPanel)
        XCTAssertEqual(router.pushCalled, 1)
    }

    private func createSubject() -> HistoryCoordinator {
        let subject = HistoryCoordinator(
            profile: profile,
            router: router,
            parentCoordinator: parentCoordinator
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
