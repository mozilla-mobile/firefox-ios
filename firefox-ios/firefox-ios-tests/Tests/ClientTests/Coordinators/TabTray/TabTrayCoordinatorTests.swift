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
        FxNimbus.shared.features.bookmarkAllTabsFeature.with { _, _ in
            BookmarkAllTabsFeature(enabled: true)
        }
        let mockTabManager = MockTabManager()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: mockTabManager)
        mockRouter = MockRouter(navigationController: MockNavigationController())
        profile = MockProfile()
        parentCoordinator = MockTabTrayCoordinatorDelegate()
        tabManager = mockTabManager
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.bookmarkAllTabsFeature.with { _, _ in
            BookmarkAllTabsFeature(enabled: false)
        }
        mockRouter = nil
        profile = nil
        parentCoordinator = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testBookmarkAllTabs_disabledDoesNotPresentOrCloseTabs() throws {
        FxNimbus.shared.features.bookmarkAllTabsFeature.with { _, _ in
            BookmarkAllTabsFeature(enabled: false)
        }
        let manager = try XCTUnwrap(tabManager as? MockTabManager)
        manager.normalTabs = makeBookmarkTabs()
        let subject = createSubject()

        subject.bookmarkAllTabs(isPrivate: false)
        subject.bookmarkAllTabs(isPrivate: false, closeAfterSaving: true)

        XCTAssertEqual(mockRouter.presentCalled, 0)
        XCTAssertTrue(manager.removedTabUUIDs.isEmpty)
    }

    func testBookmarks_filtersInternalPagesAndPreservesTabOrderAndTitles() {
        let urls = ["https://example.com/first", "about:home", "file:///tmp/test", "https://example.com/second"]
        let tabs = urls.map { value in
            let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
            tab.url = URL(string: value)
            tab.lastTitle = value
            return tab
        }
        let bookmarks = TabTrayCoordinator.bookmarks(from: tabs)
        XCTAssertEqual(bookmarks.map(\.url), [urls[0], urls[3]])
        XCTAssertEqual(bookmarks.map(\.title), [urls[0], urls[3]])
        XCTAssertTrue(bookmarks.allSatisfy { $0.parentGUID == nil })
    }

    func testBookmarkAllTabs_presentsFolderEditorForRegularTabsOnly() throws {
        let manager = try XCTUnwrap(tabManager as? MockTabManager)
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: "https://example.com")
        manager.normalTabs = [tab]
        let subject = createSubject()

        subject.bookmarkAllTabs(isPrivate: false)
        let navigation = try XCTUnwrap(mockRouter.presentedViewController as? UINavigationController)
        XCTAssertTrue(navigation.topViewController is EditFolderViewController)

        subject.bookmarkAllTabs(isPrivate: true)
        XCTAssertTrue(mockRouter.presentedViewController is UIAlertController)
    }

    func testBookmarkAndClose_closesOnlyOriginalTabsAfterTrayDismissal() async throws {
        parentCoordinator.completesDismissalImmediately = false
        let manager = try XCTUnwrap(tabManager as? MockTabManager)
        let tabs = makeBookmarkTabs()
        manager.normalTabs = tabs
        let saver = MockBookmarksSaver()
        saver.mockCreateGuid = "saved-folder"
        let subject = createSubject()
        let viewModel = subject.makeBookmarkAllTabsViewModel(tabs: tabs,
                                                             closeAfterSaving: true,
                                                             bookmarkSaver: saver)
        XCTAssertTrue(manager.removedTabUUIDs.isEmpty)
        manager.normalTabs.append(Tab(profile: profile, windowUUID: .XCTestDefaultUUID))
        viewModel.updateFolderTitle("Reading")

        await viewModel.save()?.value

        XCTAssertTrue(viewModel.saveSucceeded)
        XCTAssertEqual(saver.savedNodes.first?.title, "Reading")
        XCTAssertEqual(saver.saveCalled, 3)
        XCTAssertEqual(parentCoordinator.didDismissWasCalled, 1)
        XCTAssertTrue(manager.removedTabUUIDs.isEmpty)

        let completion = try XCTUnwrap(parentCoordinator.dismissalCompletion)
        completion()

        XCTAssertEqual(manager.removedTabUUIDs, tabs.map(\.tabUUID))
    }

    func testBookmarkAndClose_keepsTabsOpenOnFailureUntilRetrySucceeds() async throws {
        let manager = try XCTUnwrap(tabManager as? MockTabManager)
        let tabs = makeBookmarkTabs()
        let saver = MockBookmarksSaver()
        saver.mockCreateGuid = "saved-folder"
        saver.failingSaveCalls = [3]
        let subject = createSubject()
        let viewModel = subject.makeBookmarkAllTabsViewModel(tabs: tabs,
                                                             closeAfterSaving: true,
                                                             bookmarkSaver: saver)
        viewModel.updateFolderTitle("Reading")
        await viewModel.save()?.value
        XCTAssertFalse(viewModel.saveSucceeded)
        XCTAssertTrue(manager.removedTabUUIDs.isEmpty)
        XCTAssertEqual(parentCoordinator.didDismissWasCalled, 0)

        await viewModel.save()?.value

        XCTAssertTrue(viewModel.saveSucceeded)
        XCTAssertEqual(manager.removedTabUUIDs, tabs.map(\.tabUUID))
    }

    func testBookmarkWithoutClosing_keepsTabsOpenAfterSaving() async throws {
        let manager = try XCTUnwrap(tabManager as? MockTabManager)
        let saver = MockBookmarksSaver()
        saver.mockCreateGuid = "saved-folder"
        let subject = createSubject()
        let viewModel = subject.makeBookmarkAllTabsViewModel(tabs: makeBookmarkTabs(),
                                                             closeAfterSaving: false,
                                                             bookmarkSaver: saver)
        viewModel.updateFolderTitle("Reading")
        await viewModel.save()?.value

        XCTAssertTrue(viewModel.saveSucceeded)
        XCTAssertTrue(manager.removedTabUUIDs.isEmpty)
    }

    private func makeBookmarkTabs() -> [Tab] {
        return ["https://example.com/first", "https://example.com/second"].map { url in
            let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
            tab.url = URL(string: url)
            return tab
        }
    }

    func testBookmarks_emptyTabs() {
        XCTAssertTrue(TabTrayCoordinator.bookmarks(from: []).isEmpty)
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
}
