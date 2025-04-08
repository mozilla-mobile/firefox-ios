// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class TabManagerMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockProfile: MockProfile!
    private var mockWindowManager: MockWindowManager!
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var appState: AppState!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: MockTabManager(
                recentlyAccessedNormalTabs: [createTab(profile: mockProfile)]
            )
        )
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: mockWindowManager)
        setupStore()
        appState = setupAppState()
    }

    override func tearDown() {
        mockProfile = nil
        mockWindowManager = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_screenshotAction_triggersRefresh() throws {
        let subject = createSubject()
        let action = ScreenshotAction(
            windowUUID: .XCTestDefaultUUID,
            tab: Tab(profile: mockProfile, windowUUID: .XCTestDefaultUUID),
            actionType: ScreenshotActionType.screenshotTaken
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)
        wait(for: [expectation])
        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabPanelMiddlewareAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabPanelMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabPanelMiddlewareActionType.refreshTabs)
    }

    // MARK: - Recent Tabs
    func test_viewWillAppearHomeAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.viewWillAppear
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_jumpBackInAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = JumpBackInAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: JumpBackInActionType.fetchLocalTabs
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_tabTrayDismissAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TabTrayAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabTrayActionType.dismissTabTray
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_tabTrayModalSwipedToCloseAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TabTrayAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabTrayActionType.modalSwipedToClose
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_tabTrayDoneButtonTappedAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TabTrayAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabTrayActionType.doneButtonTapped
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_topTabsNewTabAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TopTabsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopTabsActionType.didTapNewTab
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_topTabsCloseTabAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TopTabsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopTabsActionType.didTapCloseTab
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_tapOnCell_fromJumpBackInAction_selectsCorrectTabs() {
        let subject = createSubject()
        let action = JumpBackInAction(
            tab: createTab(profile: mockProfile),
            windowUUID: .XCTestDefaultUUID,
            actionType: JumpBackInActionType.tapOnCell
        )

        subject.tabsPanelProvider(appState, action)
        let selectedTab = mockWindowManager.tabManager(for: .XCTestDefaultUUID).selectedTab
        XCTAssertEqual(selectedTab?.displayTitle, "www.mozilla.org")
        XCTAssertEqual(selectedTab?.url?.absoluteString, "www.mozilla.org")
    }

    // MARK: - Helpers
    private func createSubject() -> TabManagerMiddleware {
        return TabManagerMiddleware(profile: mockProfile)
    }

    private func createTab(
        profile: MockProfile,
        urlString: String? = "www.mozilla.org"
    ) -> Tab {
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)

        if let urlString = urlString {
            tab.url = URL(string: urlString)!
        }
        return tab
    }

    // MARK: StoreTestUtility
    func setupAppState() -> Client.AppState {
        let appState = AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .tabsPanel(
                        TabsPanelState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    )
                ]
            )
        )
        self.appState = appState
        return appState
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
