// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
@testable import Client

final class HistoryCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var profile: MockProfile!
    private var parentCoordinator: MockLibraryCoordinatorDelegate!
    private var notificationCenter: MockNotificationCenter!
    private var navigationHandler: MockLibraryNavigationHandler!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        router = MockRouter(navigationController: UINavigationController())
        profile = MockProfile()
        notificationCenter = MockNotificationCenter()
        parentCoordinator = MockLibraryCoordinatorDelegate()
        navigationHandler = MockLibraryNavigationHandler()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        router = nil
        profile = nil
        parentCoordinator = nil
        notificationCenter = nil
        navigationHandler = nil
    }

    func testShowRecentlyClosedTabs() {
        let subject = createSubject()

        subject.showRecentlyClosedTab()

        XCTAssertTrue(router.pushedViewController is RecentlyClosedTabsPanel)
        XCTAssertEqual(router.pushCalled, 1)
    }

    func testShowSearchGroupedItems() {
        let subject = createSubject()

        subject.showSearchGroupedItems(ASGroup(searchTerm: "", groupedItems: [], timestamp: .zero))

        XCTAssertTrue(router.pushedViewController is SearchGroupedItemsViewController)
        XCTAssertEqual(router.pushCalled, 1)
    }

    func testOpenClearRecentSearch_receiveNotificationCorrectly() {
        _ = createSubject()

        notificationCenter.post(name: .OpenClearRecentHistory)

        XCTAssertEqual(notificationCenter.addObserverCallCount, 1)
        XCTAssertEqual(notificationCenter.postCallCount, 1)
    }

    func testShowShareSheet_callsNavigationHandlerShareFunction() {
        let subject = createSubject()

        subject.shareLibraryItem(
            url: URL(
                string: "https://www.google.com"
            )!,
            sourceView: UIView()
        )

        XCTAssertEqual(navigationHandler.didShareLibraryItemCalled, 1)
    }

    private func createSubject() -> HistoryCoordinator {
        let subject = HistoryCoordinator(
            profile: profile,
            windowUUID: .XCTestDefaultUUID,
            router: router,
            notificationCenter: notificationCenter,
            parentCoordinator: parentCoordinator,
            navigationHandler: navigationHandler
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
