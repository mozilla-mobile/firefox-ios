// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class TabPanelStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    // MARK: - TabPanelMiddlewareActionType
    @MainActor
    func testTabsState_didLoadTabPanel() {
        let initialState = createInitialState()
        XCTAssertTrue(initialState.tabs.isEmpty)
        let reducer = tabsPanelReducer()
        let tabs = createTabs()
        let privateTabs = createTabs(isPrivate: true)
        let tabDisplayModel = TabDisplayModel(isPrivateMode: true,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              privateTabsCount: "\(privateTabs.count)",
                                              enableDeleteTabsButton: true)
        let action = TabPanelMiddlewareAction(tabDisplayModel: tabDisplayModel,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.didLoadTabPanel)
        let newState = reducer(initialState, action)
        XCTAssertEqual(newState.tabs, tabs)
        XCTAssertTrue(newState.isPrivateMode)
    }

    @MainActor
    func testTabsState_didChangeTabPanel() {
        let initialState = createInitialState()
        XCTAssertTrue(initialState.tabs.isEmpty)
        let reducer = tabsPanelReducer()
        let tabs = createTabs()
        let privateTabs = createTabs(isPrivate: true)
        let tabDisplayModel = TabDisplayModel(isPrivateMode: true,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              privateTabsCount: "\(privateTabs.count)",
                                              enableDeleteTabsButton: true)
        let action = TabPanelMiddlewareAction(tabDisplayModel: tabDisplayModel,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.didChangeTabPanel)
        let newState = reducer(initialState, action)
        XCTAssertEqual(newState.tabs, tabs)
        XCTAssertTrue(newState.isPrivateMode)
    }

    @MainActor
    func testTabsState_willAppearTabPanel() throws {
        let tabs = createOneSelectedTab()
        let expectedIndex = tabs.firstIndex(where: \.isSelected)
        let initialState = TabsPanelState(windowUUID: .XCTestDefaultUUID,
                                          isPrivateMode: false,
                                          tabs: tabs)
        let reducer = tabsPanelReducer()
        let action = TabPanelMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabPanelMiddlewareActionType.willAppearTabPanel
        )
        let newState = reducer(initialState, action)

        let scrollState = try XCTUnwrap(newState.scrollState)
        XCTAssertEqual(expectedIndex, scrollState.toIndex)
    }

    @MainActor
    func testTabsState_refreshTabs() throws {
        let initialState = createInitialState()
        let reducer = tabsPanelReducer()
        let tabs = createOneSelectedTab()
        let privateTabs = createTabs(isPrivate: true)
        let tabDisplayModel = TabDisplayModel(isPrivateMode: false,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              privateTabsCount: "\(privateTabs.count)",
                                              enableDeleteTabsButton: true)
        let action = TabPanelMiddlewareAction(
            tabDisplayModel: tabDisplayModel,
            windowUUID: .XCTestDefaultUUID,
            actionType: TabPanelMiddlewareActionType.refreshTabs
        )
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.tabs, tabs)
    }

    // MARK: - createTabScrollBehavior

    func testCreateTabScrollBehavior_forScrollToSelectedTab_noTabs() {
        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: []
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNil(scrollState)
    }

    func testCreateTabScrollBehavior_forScrollToSelectedTab_forTabs() {
        let tabCount = 3
        var tabModels = createTabs(count: tabCount)
        let selectedTab = TabModel.emptyState(tabUUID: createTabUUID(), title: "Selected Tab", isSelected: true)
        tabModels.append(selectedTab) // At index tabCount

        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabModels
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNotNil(scrollState)
        XCTAssertEqual(scrollState?.toIndex, tabCount)
    }

    func testCreateTabScrollBehavior_forScrollToSelectedTab_noSelectedTab_returnsLastTab_ifTabsNotEmpty() {
        let tabCount = 3
        let tabModels: [TabModel] = createTabs(count: tabCount)
        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabModels
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNotNil(scrollState)
        XCTAssertEqual(scrollState?.toIndex, tabCount - 1, "Should return the last tab if there is no selected tab")
    }

    func testCreateTabScrollBehavior_forScrollToSelectedTab_noSelectedTab_returnsNil_ifTabsEmpty() {
        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: []
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNil(scrollState)
    }

    func testCreateTabScrollBehavior_forScrollToTab_noTabs() {
        let scrollBehavior: TabScrollBehavior = .scrollToTab(withTabUUID: createTabUUID(), shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: []
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNil(scrollState)
    }

    func testCreateTabScrollBehavior_forScrollToTab_aNormalOrPrivateTab_forTabs() {
        let testTabUUID = createTabUUID()
        let tabCount = 3
        var tabModels = createTabs(count: tabCount)
        let selectedTab = TabModel.emptyState(tabUUID: testTabUUID, title: "Selected Tab", isSelected: true)
        tabModels.append(selectedTab) // At index tabCount

        let scrollBehavior: TabScrollBehavior = .scrollToTab(withTabUUID: testTabUUID, shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabModels
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNotNil(scrollState)
        XCTAssertEqual(scrollState?.toIndex, tabCount)
    }

    func testCreateTabScrollBehavior_forScrollToTab_tabDoesntExist() {
        let tabModels = createTabs()
        let scrollBehavior: TabScrollBehavior = .scrollToTab(withTabUUID: createTabUUID(), shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabModels
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNil(scrollState)
    }

    // MARK: - Private
    private func createTabUUID() -> TabUUID {
        return UUID().uuidString
    }

    private func tabsPanelReducer() -> Reducer<TabsPanelState> {
        return TabsPanelState.reducer
    }

    private func createInitialState() -> TabsPanelState {
        return TabsPanelState(windowUUID: .XCTestDefaultUUID)
    }

    private func createOneSelectedTab() -> [TabModel] {
        return [
            .emptyState(tabUUID: createTabUUID(), title: "Tab 0"),
            .emptyState(tabUUID: createTabUUID(), title: "Tab 1", isSelected: true),
            .emptyState(tabUUID: createTabUUID(), title: "Tab 2")
        ]
    }

    private func createTabs(count: Int = 3, isPrivate: Bool = false) -> [TabModel] {
        return (0 ..< count).map { index in
            .emptyState(tabUUID: createTabUUID(), title: "Tab\(index)", isPrivate: isPrivate)
        }
    }
}
