// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class TabTrayStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Initializers

    func test_default_init() {
        let subject = createSubject()
        XCTAssertEqual(subject.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(subject.isNormalTabsPanel)
        XCTAssertEqual(subject.isPrivateMode, false)
        XCTAssertEqual(subject.isSyncTabsPanel, false)
    }

    func test_init_withPanelType_tabs() {
          let state = TabTrayState(windowUUID: .XCTestDefaultUUID, panelType: .tabs)

          XCTAssertEqual(state.selectedPanel, .tabs)
          XCTAssertFalse(state.isPrivateMode)
      }

      func test_init_withPanelType_privateTabs() {
          let state = TabTrayState(windowUUID: .XCTestDefaultUUID, panelType: .privateTabs)

          XCTAssertEqual(state.selectedPanel, .privateTabs)
          XCTAssertTrue(state.isPrivateMode)
      }

      func test_init_withPanelType_syncedTabs() {
          let state = TabTrayState(windowUUID: .XCTestDefaultUUID, panelType: .syncedTabs)

          XCTAssertEqual(state.selectedPanel, .syncedTabs)
          XCTAssertFalse(state.isPrivateMode)
      }

    // MARK: - DidLoadTabTray action

    @MainActor
    func test_reduceTabTray_DidLoadPrivateTabTrayAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertEqual(initialState.selectedPanel, .tabs)
        XCTAssertEqual(initialState.isPrivateMode, false)

        let model = TabTrayModel(isPrivateMode: true,
                                 selectedPanel: .privateTabs,
                                 normalTabsCount: "5",
                                 privateTabsCount: "2",
                                 hasSyncableAccount: false,
                                 enableDeleteTabsButton: false)

        let action = getAction(for: .didLoadTabTray, with: model)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.selectedPanel, .privateTabs)
        XCTAssertTrue(newState.isPrivateMode)
        XCTAssertFalse(newState.isNormalTabsPanel)
        XCTAssertFalse(newState.isSyncTabsPanel)
    }

    @MainActor
    func test_reduceTabTray_DidLoadSyncTabTrayAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertEqual(initialState.selectedPanel, .tabs)
        XCTAssertEqual(initialState.isPrivateMode, false)

        let model = TabTrayModel(isPrivateMode: false,
                                 selectedPanel: .syncedTabs,
                                 normalTabsCount: "5",
                                 privateTabsCount: "2",
                                 hasSyncableAccount: false,
                                 enableDeleteTabsButton: false)

        let action = getAction(for: .didLoadTabTray, with: model)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.selectedPanel, .syncedTabs)
        XCTAssertFalse(newState.isPrivateMode)
        XCTAssertTrue(newState.isSyncTabsPanel)
    }

    @MainActor
    func test_reduceTabTray_didLoadTabTray_withNilModel_returnsDefaultState() {
         let initialState = createSubject()
         let reducer = tabTrayReducer()

         let action = TabTrayAction(windowUUID: .XCTestDefaultUUID,
                                    actionType: TabTrayActionType.didLoadTabTray)
         let newState = reducer(initialState, action)

         // Should return defaultState when tabTrayModel is nil
         XCTAssertEqual(newState, TabTrayState.defaultState(from: initialState))
     }

    // MARK: - changePanel action

    @MainActor
    func test_reduceTabTray_ChangePrivatePanelAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertEqual(initialState.selectedPanel, .tabs)
        XCTAssertFalse(initialState.isPrivateMode)

        let action = TabTrayAction(panelType: .privateTabs,
                                   windowUUID: .XCTestDefaultUUID,
                                   actionType: TabTrayActionType.changePanel)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.selectedPanel, .privateTabs)
        XCTAssertTrue(newState.isPrivateMode)
    }

    @MainActor
    func test_reduceTabTray_ChangeSyncPanelAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertEqual(initialState.selectedPanel, .tabs)
        XCTAssertFalse(initialState.isPrivateMode)

        let action = TabTrayAction(panelType: .syncedTabs,
                                   windowUUID: .XCTestDefaultUUID,
                                   actionType: TabTrayActionType.changePanel)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.selectedPanel, .syncedTabs)
        XCTAssertFalse(newState.isPrivateMode)
    }

     @MainActor
     func test_reduceTabTray_changePanel_withNilPanelType_returnsDefaultState() {
         let initialState = createSubject()
         let reducer = tabTrayReducer()

         let action = TabTrayAction(windowUUID: .XCTestDefaultUUID,
                                    actionType: TabTrayActionType.changePanel)
         let newState = reducer(initialState, action)

         XCTAssertEqual(newState, TabTrayState.defaultState(from: initialState))
     }

    // MARK: - TabPanelMiddlewareAction Tests

    @MainActor
    func test_reduceTabTray_DismissTabTrayAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertFalse(initialState.shouldDismiss)

        let action = TabTrayAction(windowUUID: .XCTestDefaultUUID,
                                   actionType: TabTrayActionType.dismissTabTray)
        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.shouldDismiss)
    }

    @MainActor
    func test_reduceTabTray_FirefoxAccountChangedAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertFalse(initialState.hasSyncableAccount)

        let action = TabTrayAction(hasSyncableAccount: true,
                                   windowUUID: .XCTestDefaultUUID,
                                   actionType: TabTrayActionType.firefoxAccountChanged)
        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.hasSyncableAccount)
    }

    @MainActor
    func test_reduceTabPanelMiddleware_DidChangeTabPanelAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertEqual(initialState.normalTabsCount, "0")
        XCTAssertEqual(initialState.privateTabsCount, "0")

        let tabs = [
            TabModel.emptyState(tabUUID: "tab1", title: "Tab 1", isPrivate: false),
            TabModel.emptyState(tabUUID: "tab2", title: "Tab 2", isPrivate: true)
        ]
        let displayModel = TabDisplayModel(isPrivateMode: false,
                                           tabs: tabs,
                                           normalTabsCount: "5",
                                           privateTabsCount: "3",
                                           enableDeleteTabsButton: true)

        let action = TabPanelMiddlewareAction(tabDisplayModel: displayModel,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.didChangeTabPanel)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.normalTabsCount, "5")
        XCTAssertEqual(newState.privateTabsCount, "1")
        XCTAssertEqual(newState.selectedPanel, .tabs)
    }

    // MARK: refreshTabs Action

    @MainActor
    func test_reduceTabPanelMiddleware_RefreshTabs_withPrivateTabs() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertEqual(initialState.privateTabsCount, "0")

        let tabs = [
            TabModel.emptyState(tabUUID: "tab1", title: "Private 1", isPrivate: true),
            TabModel.emptyState(tabUUID: "tab2", title: "Private 2", isPrivate: true)
        ]
        let displayModel = TabDisplayModel(isPrivateMode: false,
                                           tabs: tabs,
                                           normalTabsCount: "5",
                                           privateTabsCount: "2",
                                           enableDeleteTabsButton: false)

        let action = TabPanelMiddlewareAction(tabDisplayModel: displayModel,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.refreshTabs)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.privateTabsCount, "2")
        XCTAssertEqual(newState.normalTabsCount, "0")
    }

    @MainActor
     func test_reduceTabPanelMiddleware_refreshTabs_withNormalTabs() {
         let initialState = createSubject()
         let reducer = tabTrayReducer()

         let tabs = [
             TabModel.emptyState(tabUUID: "tab1", title: "Normal 1", isPrivate: false),
             TabModel.emptyState(tabUUID: "tab2", title: "Normal 2", isPrivate: false)
         ]
         let displayModel = TabDisplayModel(isPrivateMode: false,
                                            tabs: tabs,
                                            normalTabsCount: "10",
                                            privateTabsCount: "3",
                                            enableDeleteTabsButton: true)

         let action = TabPanelMiddlewareAction(tabDisplayModel: displayModel,
                                               windowUUID: .XCTestDefaultUUID,
                                               actionType: TabPanelMiddlewareActionType.refreshTabs)
         let newState = reducer(initialState, action)

         XCTAssertEqual(newState.normalTabsCount, "10") // Should update for normal tabs
         XCTAssertEqual(newState.privateTabsCount, "3")
     }

    @MainActor
    func test_reduceTabPanelMiddleware_ShowToastAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertNil(initialState.toastType)

        let action = TabPanelMiddlewareAction(toastType: .closedSingleTab,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.showToast)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.toastType, .closedSingleTab)
    }

    // MARK: - TabPanelViewAction Tests

    @MainActor
    func test_reduceTabPanelView_CloseAllTabsAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        XCTAssertFalse(initialState.showCloseConfirmation)

        let action = TabPanelViewAction(panelType: .tabs,
                                        windowUUID: .XCTestDefaultUUID,
                                        actionType: TabPanelViewActionType.closeAllTabs)
        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.showCloseConfirmation)
    }

    // MARK: - Computed Properties
      func test_navigationTitle_forTabsPanel() {
          let state = TabTrayState(windowUUID: .XCTestDefaultUUID,
                                   isPrivateMode: false,
                                   selectedPanel: .tabs,
                                   normalTabsCount: "5",
                                   privateTabsCount: "0",
                                   hasSyncableAccount: false)

          XCTAssertEqual(state.navigationTitle, TabTrayPanelType.tabs.navTitle)
      }

      func test_navigationTitle_forPrivateTabsPanel() {
          let state = TabTrayState(windowUUID: .XCTestDefaultUUID,
                                   isPrivateMode: true,
                                   selectedPanel: .privateTabs,
                                   normalTabsCount: "0",
                                   privateTabsCount: "3",
                                   hasSyncableAccount: false)

          XCTAssertEqual(state.navigationTitle, TabTrayPanelType.privateTabs.navTitle)
      }

      func test_navigationTitle_forSyncedTabsPanel() {
          let state = TabTrayState(windowUUID: .XCTestDefaultUUID,
                                   isPrivateMode: false,
                                   selectedPanel: .syncedTabs,
                                   normalTabsCount: "5",
                                   privateTabsCount: "0",
                                   hasSyncableAccount: true)

          XCTAssertEqual(state.navigationTitle, TabTrayPanelType.syncedTabs.navTitle)
      }

    // MARK: Private helpers
    private func createSubject() -> TabTrayState {
        return TabTrayState(windowUUID: .XCTestDefaultUUID)
    }

    private func tabTrayReducer() -> Reducer<TabTrayState> {
        return TabTrayState.reducer
    }

    private func getAction(for actionType: TabTrayActionType, with model: TabTrayModel) -> TabTrayAction {
        return TabTrayAction(tabTrayModel: model, windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
