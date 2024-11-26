// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage
import Shared
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
    func testTabsState_didLoadTabPanel() {
        let initialState = createInitialState()
        XCTAssertTrue(initialState.tabs.isEmpty)
        let reducer = tabsPanelReducer()
        let tabs = createTabs()
        let inactiveTabs = createInactiveTabs()
        let tabDisplayModel = TabDisplayModel(isPrivateMode: true,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              inactiveTabs: inactiveTabs,
                                              isInactiveTabsExpanded: false)
        let action = TabPanelMiddlewareAction(tabDisplayModel: tabDisplayModel,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.didLoadTabPanel)
        let newState = reducer(initialState, action)
        XCTAssertEqual(newState.tabs, tabs)
        XCTAssertTrue(newState.isPrivateMode)
        XCTAssertEqual(newState.inactiveTabs, inactiveTabs)
        XCTAssertFalse(newState.isInactiveTabsExpanded)
    }

    func testTabsState_didChangeTabPanel() {
        let initialState = createInitialState()
        XCTAssertTrue(initialState.tabs.isEmpty)
        let reducer = tabsPanelReducer()
        let tabs = createTabs()
        let inactiveTabs = createInactiveTabs()
        let tabDisplayModel = TabDisplayModel(isPrivateMode: true,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              inactiveTabs: inactiveTabs,
                                              isInactiveTabsExpanded: false)
        let action = TabPanelMiddlewareAction(tabDisplayModel: tabDisplayModel,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.didChangeTabPanel)
        let newState = reducer(initialState, action)
        XCTAssertEqual(newState.tabs, tabs)
        XCTAssertTrue(newState.isPrivateMode)
        XCTAssertEqual(newState.inactiveTabs, inactiveTabs)
        XCTAssertFalse(newState.isInactiveTabsExpanded)
    }

    func testTabsState_willAppearTabPanel() throws {
        let tabs = createOneSelectedTab()
        let expectedIndex = tabs.firstIndex(where: \.isSelected)
        let initialState = TabsPanelState(windowUUID: .XCTestDefaultUUID,
                                          isPrivateMode: false,
                                          tabs: tabs,
                                          inactiveTabs: createInactiveTabs(),
                                          isInactiveTabsExpanded: false)
        let reducer = tabsPanelReducer()
        let action = TabPanelMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabPanelMiddlewareActionType.willAppearTabPanel
        )
        let newState = reducer(initialState, action)

        let scrollState = try XCTUnwrap(newState.scrollState)
        XCTAssertEqual(expectedIndex, scrollState.toIndex)
    }

    func testTabsState_refreshTabs() throws {
        let initialState = createInitialState()
        let reducer = tabsPanelReducer()
        let tabs = createOneSelectedTab()
        let tabDisplayModel = TabDisplayModel(isPrivateMode: false,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              inactiveTabs: [InactiveTabsModel](),
                                              isInactiveTabsExpanded: false)
        let action = TabPanelMiddlewareAction(
            tabDisplayModel: tabDisplayModel,
            windowUUID: .XCTestDefaultUUID,
            actionType: TabPanelMiddlewareActionType.refreshTabs
        )
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.tabs, tabs)
    }

    func testTabsState_refreshInactiveTabs() throws {
        let initialState = createInitialState()
        XCTAssertTrue(initialState.inactiveTabs.isEmpty)
        let reducer = tabsPanelReducer()
        let tabs = createTabs()
        let inactiveTabs = createInactiveTabs()
        let tabDisplayModel = TabDisplayModel(isPrivateMode: false,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              inactiveTabs: [InactiveTabsModel](),
                                              isInactiveTabsExpanded: false)
        let action = TabPanelMiddlewareAction(
            tabDisplayModel: tabDisplayModel,
            inactiveTabModels: inactiveTabs,
            windowUUID: .XCTestDefaultUUID,
            actionType: TabPanelMiddlewareActionType.refreshInactiveTabs
        )
        let newState = reducer(initialState, action)
        XCTAssertEqual(newState.inactiveTabs, inactiveTabs, "Expected inactive tabs were: \(inactiveTabs)")
    }

    func testTabsState_IsInactiveTabsExpanded() {
        let initialState = createInitialState()
        XCTAssertFalse(initialState.isInactiveTabsExpanded)
        let reducer = tabsPanelReducer()
        let action = TabPanelViewAction(panelType: .tabs,
                                        windowUUID: .XCTestDefaultUUID,
                                        actionType: TabPanelViewActionType.toggleInactiveTabs)
        let newState = reducer(initialState, action)
        XCTAssertTrue(newState.isInactiveTabsExpanded)
    }

    // MARK: - createTabScrollBehavior

    func testCreateTabScrollBehavior_forScrollToSelectedTab_noTabs() {
        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: [],
            inactiveTabs: [],
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNil(scrollState)
    }

    func testCreateTabScrollBehavior_forScrollToSelectedTab_forOnlyInactiveTabs() {
        let inactiveTabModels = createInactiveTabs()
        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: [],
            inactiveTabs: inactiveTabModels,
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNil(scrollState)
    }

    func testCreateTabScrollBehavior_forScrollToSelectedTab_forTabsAndInactiveTabs() {
        let tabCount = 3
        var tabModels = createTabs(count: tabCount)
        let selectedTab = TabModel.emptyState(tabUUID: createTabUUID(), title: "Selected Tab", isSelected: true)
        tabModels.append(selectedTab) // At index tabCount

        let inactiveTabModels = createInactiveTabs()
        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabModels,
            inactiveTabs: inactiveTabModels,
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNotNil(scrollState)
        XCTAssertEqual(scrollState?.toIndex, tabCount)
        XCTAssertEqual(scrollState?.isInactiveTabSection, false)
    }

    func testCreateTabScrollBehavior_forScrollToSelectedTab_noSelectedTab_returnsLastTab_ifTabsNotEmpty() {
        let tabCount = 3
        let tabModels: [TabModel] = createTabs(count: tabCount)
        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabModels,
            inactiveTabs: [],
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNotNil(scrollState)
        XCTAssertEqual(scrollState?.toIndex, tabCount - 1, "Should return the last tab if there is no selected tab")
        XCTAssertEqual(scrollState?.isInactiveTabSection, false)
    }

    func testCreateTabScrollBehavior_forScrollToSelectedTab_noSelectedTab_returnsNil_ifTabsEmpty() {
        let inactiveTabModels = createInactiveTabs()
        let scrollBehavior: TabScrollBehavior = .scrollToSelectedTab(shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: [],
            inactiveTabs: inactiveTabModels,
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNil(scrollState)
    }

    func testCreateTabScrollBehavior_forScrollToTab_noTabs() {
        let scrollBehavior: TabScrollBehavior = .scrollToTab(withTabUUID: createTabUUID(), shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: [],
            inactiveTabs: [],
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNil(scrollState)
    }

    func testCreateTabScrollBehavior_forScrollToTab_anInactiveTab_forOnlyInactiveTabs() {
        let inactiveTabCount = 3
        let testTabUUID = createTabUUID()
        var inactiveTabModels = createInactiveTabs(count: inactiveTabCount)
        let inactiveTab = InactiveTabsModel.emptyState(tabUUID: testTabUUID, title: "Special")
        inactiveTabModels.append(inactiveTab) // At index inactiveTabCount
        let scrollBehavior: TabScrollBehavior = .scrollToTab(withTabUUID: testTabUUID, shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: [],
            inactiveTabs: inactiveTabModels,
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNotNil(scrollState)
        XCTAssertEqual(scrollState?.toIndex, inactiveTabCount)
        XCTAssertEqual(scrollState?.isInactiveTabSection, true)
    }

    func testCreateTabScrollBehavior_forScrollToTab_anInactiveTab_forTabsAndInactiveTabs() {
        let inactiveTabCount = 3
        let testTabUUID = createTabUUID()
        let tabs = createTabs()
        var inactiveTabModels = createInactiveTabs(count: inactiveTabCount)
        let inactiveTab = InactiveTabsModel.emptyState(tabUUID: testTabUUID, title: "Special")
        inactiveTabModels.append(inactiveTab) // At index inactiveTabCount
        let scrollBehavior: TabScrollBehavior = .scrollToTab(withTabUUID: testTabUUID, shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabs,
            inactiveTabs: inactiveTabModels,
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNotNil(scrollState)
        XCTAssertEqual(scrollState?.toIndex, inactiveTabCount)
        XCTAssertEqual(scrollState?.isInactiveTabSection, true)
    }

    func testCreateTabScrollBehavior_forScrollToTab_aNormalOrPrivateTab_forTabsAndInactiveTabs() {
        let testTabUUID = createTabUUID()
        let tabCount = 3
        var tabModels = createTabs(count: tabCount)
        let selectedTab = TabModel.emptyState(tabUUID: testTabUUID, title: "Selected Tab", isSelected: true)
        tabModels.append(selectedTab) // At index tabCount

        let inactiveTabModels = createInactiveTabs()
        let scrollBehavior: TabScrollBehavior = .scrollToTab(withTabUUID: testTabUUID, shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabModels,
            inactiveTabs: inactiveTabModels,
            isInactiveTabsExpanded: true
        )

        let scrollState = TabsPanelState.createTabScrollBehavior(forState: initialState, withScrollBehavior: scrollBehavior)

        XCTAssertNotNil(scrollState)
        XCTAssertEqual(scrollState?.toIndex, tabCount)
        XCTAssertEqual(scrollState?.isInactiveTabSection, false)
    }

    func testCreateTabScrollBehavior_forScrollToTab_tabDoesntExist() {
        let tabModels = createTabs()
        let inactiveTabModels = createInactiveTabs()
        let scrollBehavior: TabScrollBehavior = .scrollToTab(withTabUUID: createTabUUID(), shouldAnimate: false)

        let initialState = TabsPanelState(
            windowUUID: .XCTestDefaultUUID,
            isPrivateMode: false,
            tabs: tabModels,
            inactiveTabs: inactiveTabModels,
            isInactiveTabsExpanded: true
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

    private func createInactiveTabs(count: Int = 3) -> [InactiveTabsModel] {
        return (0 ..< count).map { index in
            InactiveTabsModel(tabUUID: createTabUUID(),
                              title: "InactiveTab\(index)",
                              url: URL(string: "https://www.test\(index).com"))
        }
    }
}
