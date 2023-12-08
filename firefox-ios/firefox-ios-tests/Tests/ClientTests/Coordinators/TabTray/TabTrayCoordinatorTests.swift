// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TabTrayCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        super.tearDown()
        self.mockRouter = nil
        DependencyHelperMock().reset()
    }

    func testInitialState() {
        let subject = createSubject()

        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testStart_RegularTabsPanel() {
        let subject = createSubject()
        subject.start(panelType: .tabs, navigationController: UINavigationController())

        XCTAssertFalse(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testStart_PrivateTabsPanel() {
        let subject = createSubject()
        subject.start(panelType: .privateTabs, navigationController: UINavigationController())

        XCTAssertFalse(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testStart_SyncedTabsPanel() {
        let subject = createSubject()
        subject.start(panelType: .syncedTabs, navigationController: UINavigationController())

        XCTAssertFalse(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testDismissCalled() {
        let subject = createSubject()
        subject.start(panelType: .tabs, navigationController: UINavigationController())
        subject.didFinish()

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    // MARK: - Helpers
    private func createSubject(panelType: TabTrayPanelType = .tabs,
                               file: StaticString = #file,
                               line: UInt = #line) -> TabTrayCoordinator {
        let subject = TabTrayCoordinator(router: mockRouter,
                                         tabTraySection: panelType)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
