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
    }

    override func tearDown() {
        mockProfile = nil
        mockWindowManager = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_homepageInitializeAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
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
        appState = AppState()
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
