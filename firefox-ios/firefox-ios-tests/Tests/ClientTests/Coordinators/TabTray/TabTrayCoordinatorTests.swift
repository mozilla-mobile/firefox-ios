// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class TabTrayCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var profile: MockProfile!
    private var parentCoordinator: MockTabTrayCoordinatorDelegate!
    private var tabManager: TabManager!

    override func setUp() async throws {
        try await super.setUp()
        let mockTabManager = MockTabManager()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: mockTabManager)
        mockRouter = MockRouter(navigationController: MockNavigationController())
        profile = makeProfile()
        parentCoordinator = MockTabTrayCoordinatorDelegate()
        tabManager = mockTabManager
    }

    override func tearDown() async throws {
        mockRouter = nil
        profile = nil
        parentCoordinator = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
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

    func testStart_RemoteTabsPanel() {
        let subject = createSubject()
        subject.start(panelType: .syncedTabs, navigationController: UINavigationController())

        XCTAssertFalse(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testStart_reselectingSamePanel_reusesTabsCoordinator() {
        let subject = createSubject()
        let navigationController = UINavigationController()

        subject.start(panelType: .tabs, navigationController: navigationController)
        subject.start(panelType: .tabs, navigationController: navigationController)
        subject.start(panelType: .tabs, navigationController: navigationController)

        XCTAssertEqual(subject.childCoordinators.count, 1)
    }

    func testStart_switchingBetweenPanels_createsOneCoordinatorPerPanel() {
        let subject = createSubject()
        let regularNavigationController = UINavigationController()
        let privateNavigationController = UINavigationController()

        for _ in 0..<3 {
            subject.start(panelType: .tabs, navigationController: regularNavigationController)
            subject.start(panelType: .privateTabs, navigationController: privateNavigationController)
        }

        XCTAssertEqual(subject.childCoordinators.count, 2)
    }

    func testDidFinishCalled() {
        let subject = createSubject()
        subject.start(panelType: .tabs, navigationController: UINavigationController())
        subject.didFinish()

        XCTAssertEqual(parentCoordinator.didDismissWasCalled, 1)
    }

    // MARK: - Preloading before presentation
    func testStartWith_withExperiment_loadsTrayAndSelectedTabsPanel() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: true)
        let subject = createSubject()

        subject.start(with: .tabs)

        let tray = try XCTUnwrap(subject.tabTrayViewController)
        let panel = try XCTUnwrap(tray.currentExperimentPanel)
        let tabsPanel = try XCTUnwrap(panel.topViewController as? TabDisplayPanelViewController)
        XCTAssertTrue(tray.isViewLoaded)
        XCTAssertTrue(panel.isViewLoaded)
        XCTAssertTrue(tabsPanel.isViewLoaded)
    }

    func testStartWith_withoutExperiment_loadsTrayAndSelectedTabsPanel() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        let subject = createSubject(panelType: .privateTabs)

        subject.start(with: .privateTabs)

        let tray = try XCTUnwrap(subject.tabTrayViewController)
        let panel = try XCTUnwrap(tray.currentPanel)
        let tabsPanel = try XCTUnwrap(panel.topViewController as? TabDisplayPanelViewController)
        XCTAssertTrue(tray.isViewLoaded)
        XCTAssertTrue(tabsPanel.isViewLoaded)
    }

    func testStartWith_syncedTabs_doesNotPreloadRemoteTabsPanel() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: true)
        let subject = createSubject(panelType: .syncedTabs)

        subject.start(with: .syncedTabs)

        let tray = try XCTUnwrap(subject.tabTrayViewController)
        let panel = try XCTUnwrap(tray.currentExperimentPanel)
        let remotePanel = try XCTUnwrap(panel.topViewController as? RemoteTabsPanel)
        XCTAssertTrue(tray.isViewLoaded)
        XCTAssertFalse(remotePanel.isViewLoaded)
    }

    // MARK: - Helpers
    private func createSubject(panelType: TabTrayPanelType = .tabs,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabTrayCoordinator {
        let subject = TabTrayCoordinator(router: mockRouter,
                                         tabTraySection: panelType,
                                         profile: profile,
                                         tabManager: tabManager)
        subject.parentCoordinator = parentCoordinator

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func setupNimbusTabTrayUIExperimentTesting(isEnabled: Bool) {
        FxNimbus.shared.features.tabTrayUiExperiments.with { _, _ in
            return TabTrayUiExperiments(enabled: isEnabled)
        }
    }
}
