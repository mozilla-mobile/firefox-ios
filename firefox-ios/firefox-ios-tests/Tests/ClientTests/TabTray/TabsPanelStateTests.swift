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
    func testTabsState_DidLoadTabPanel() {
        testTabsState_newTabsIsEmptyHelper(actionType: TabPanelMiddlewareActionType.didLoadTabPanel)
    }

    func testTabsState_didChangeTabPanel() {
        testTabsState_newTabsIsEmptyHelper(actionType: TabPanelMiddlewareActionType.didChangeTabPanel)
    }

    private func testTabsState_newTabsIsEmptyHelper(actionType: TabPanelMiddlewareActionType,
                                                    file: StaticString = #file,
                                                    line: UInt = #line) {
        let initialState = createInitialState()
        XCTAssertTrue(initialState.tabs.isEmpty, file: file, line: line)
        let reducer = tabsPanelReducer()
        let tabs = createTabs()
        let tabDisplayModel = TabDisplayModel(isPrivateMode: false,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              inactiveTabs: [InactiveTabsModel](),
                                              isInactiveTabsExpanded: false)
        let action = TabPanelMiddlewareAction(tabDisplayModel: tabDisplayModel,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.didChangeTabPanel)
        let newState = reducer(initialState, action)
        XCTAssertFalse(newState.tabs.isEmpty, file: file, line: line)
    }

    func testTabsState_willAppearTabPanel() throws {
        let tabs = createOneSelectedTab()
        let tabDisplayModel = TabDisplayModel(isPrivateMode: false,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              inactiveTabs: [InactiveTabsModel](),
                                              isInactiveTabsExpanded: false,
                                              shouldScrollToTab: false)
        try testTabsState_scrollToIndexHelper(actionType: .willAppearTabPanel, tabDisplayModel: tabDisplayModel)
    }

    func testTabsState_refreshTabs() throws {
        let tabs = createOneSelectedTab()
        let tabDisplayModel = TabDisplayModel(isPrivateMode: false,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              inactiveTabs: [InactiveTabsModel](),
                                              isInactiveTabsExpanded: false,
                                              shouldScrollToTab: true)
        try testTabsState_scrollToIndexHelper(actionType: .refreshTabs, tabDisplayModel: tabDisplayModel)
    }

    func testTabsState_scrollToIndexHelper(actionType: TabPanelMiddlewareActionType,
                                           tabDisplayModel: TabDisplayModel,
                                           file: StaticString = #file,
                                           line: UInt = #line) throws {
        let initialState = createInitialState()
        XCTAssertNil(initialState.scrollToIndex, file: file, line: line)
        let selectedIndex = try XCTUnwrap(tabDisplayModel.tabs.firstIndex(where: \.isSelected), file: file, line: line)
        let reducer = tabsPanelReducer()
        let action = TabPanelMiddlewareAction(
            tabDisplayModel: tabDisplayModel,
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
        let newState = reducer(initialState, action)
        XCTAssertEqual(newState.scrollToIndex, selectedIndex, "Expected index was: \(selectedIndex)", file: file, line: line)
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
                                              isInactiveTabsExpanded: false,
                                              shouldScrollToTab: false)
        let action = TabPanelMiddlewareAction(
            tabDisplayModel: tabDisplayModel,
            inactiveTabModels: inactiveTabs,
            windowUUID: .XCTestDefaultUUID,
            actionType: TabPanelMiddlewareActionType.refreshInactiveTabs
        )
        let newState = reducer(initialState, action)
        XCTAssertEqual(newState.inactiveTabs, inactiveTabs, "Expected inactive tabs were: \(inactiveTabs)")
    }

    func testTabsState_showToast() {
        for toastType in toastTypes() {
            let initialState = createInitialState()
            XCTAssertNil(initialState.toastType)
            let reducer = tabsPanelReducer()
            let action = TabPanelMiddlewareAction(
                toastType: toastType,
                windowUUID: .XCTestDefaultUUID,
                actionType: TabPanelMiddlewareActionType.showToast
            )
            let newState = reducer(initialState, action)
            XCTAssertEqual(newState.toastType, toastType, "Failed toast type: \(toastType)")
        }
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
            MockTabModel(tabTitle: "Tab 0"),
            MockTabModel(isSelected: true, tabTitle: "Tab 1"),
            MockTabModel(tabTitle: "Tab 2")
        ]
    }

    private func createTabs() -> [TabModel] {
        return (0...2).map { index in
            MockTabModel(tabTitle: "Tab\(index)")
        }
    }

    private func createInactiveTabs() -> [InactiveTabsModel] {
        return (0...2).map { index in
            InactiveTabsModel(tabUUID: "4233-2323-3578",
                              title: "InactiveTab\(index)",
                              url: URL(string: "https://www.test\(index).com"))
        }
    }

    private func MockTabModel(tabUUID: TabUUID = "",
                              isSelected: Bool = false,
                              isPrivate: Bool = false,
                              isFxHomeTab: Bool = false,
                              tabTitle: String = "",
                              url: URL? = nil,
                              screenshot: UIImage? = nil,
                              hasHomeScreenshot: Bool = false) -> TabModel {
        TabModel(tabUUID: tabUUID,
                 isSelected: isSelected,
                 isPrivate: isPrivate,
                 isFxHomeTab: isFxHomeTab,
                 tabTitle: tabTitle,
                 url: url,
                 screenshot: screenshot,
                 hasHomeScreenshot: hasHomeScreenshot)
    }

    private func toastTypes() -> [ToastType] {
        return [
            .addBookmark,
            .addToReadingList,
            .addShortcut,
            .closedSingleTab,
            .closedSingleInactiveTab,
            .closedAllTabs(count: 3),
            .closedAllInactiveTabs(count: 3),
            .copyURL,
            .removeFromReadingList,
            .removeShortcut
        ]
    }
}
