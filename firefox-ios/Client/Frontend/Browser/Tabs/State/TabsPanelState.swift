// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct TabsPanelState: ScreenState, Equatable {
    struct ScrollState: Equatable {
        let toIndex: Int
        let isInactiveTabSection: Bool
        let withAnimation: Bool
    }

    var isPrivateMode: Bool
    var tabs: [TabModel]
    var inactiveTabs: [InactiveTabsModel]
    var isInactiveTabsExpanded: Bool
    var toastType: ToastType?
    var windowUUID: WindowUUID
    var scrollState: ScrollState?
    var didTapAddTab: Bool
    var urlRequest: URLRequest?

    var isPrivateTabsEmpty: Bool {
        guard isPrivateMode else { return false }
        return tabs.isEmpty
    }

    init(appState: AppState, uuid: WindowUUID) {
        guard let panelState = store.state.screenState(TabsPanelState.self,
                                                       for: .tabsPanel,
                                                       window: uuid) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: panelState.windowUUID,
                  isPrivateMode: panelState.isPrivateMode,
                  tabs: panelState.tabs,
                  inactiveTabs: panelState.inactiveTabs,
                  isInactiveTabsExpanded: panelState.isInactiveTabsExpanded,
                  toastType: panelState.toastType,
                  scrollState: panelState.scrollState,
                  didTapAddTab: panelState.didTapAddTab,
                  urlRequest: panelState.urlRequest)
    }

    init(windowUUID: WindowUUID, isPrivateMode: Bool = false) {
        self.init(
            windowUUID: windowUUID,
            isPrivateMode: isPrivateMode,
            tabs: [TabModel](),
            inactiveTabs: [InactiveTabsModel](),
            isInactiveTabsExpanded: false,
            toastType: nil,
            scrollState: nil,
            didTapAddTab: false,
            urlRequest: nil)
    }

    init(windowUUID: WindowUUID,
         isPrivateMode: Bool,
         tabs: [TabModel],
         inactiveTabs: [InactiveTabsModel],
         isInactiveTabsExpanded: Bool,
         toastType: ToastType? = nil,
         scrollState: ScrollState? = nil,
         didTapAddTab: Bool = false,
         urlRequest: URLRequest? = nil) {
        self.isPrivateMode = isPrivateMode
        self.tabs = tabs
        self.inactiveTabs = inactiveTabs
        self.isInactiveTabsExpanded = isInactiveTabsExpanded
        self.toastType = toastType
        self.windowUUID = windowUUID
        self.scrollState = scrollState
        self.didTapAddTab = didTapAddTab
        self.urlRequest = urlRequest
    }

    /// Returns a new `TabsPanelState` which clears any transient data (e.g. scroll animations).
    static func defaultState(fromPreviousState state: TabsPanelState) -> TabsPanelState {
        return TabsPanelState(windowUUID: state.windowUUID,
                              isPrivateMode: state.isPrivateMode,
                              tabs: state.tabs,
                              inactiveTabs: state.inactiveTabs,
                              isInactiveTabsExpanded: state.isInactiveTabsExpanded)
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        if let action = action as? TabPanelMiddlewareAction {
            return TabsPanelState.reduceTabPanelMiddlewareAction(action: action, state: state)
        } else if let action = action as? TabPanelViewAction {
            return TabsPanelState.reduceTabsPanelViewAction(action: action, state: state)
        }

        return defaultState(fromPreviousState: state)
    }

    static func reduceTabPanelMiddlewareAction(action: TabPanelMiddlewareAction,
                                               state: TabsPanelState) -> TabsPanelState {
        switch action.actionType {
        case TabPanelMiddlewareActionType.didLoadTabPanel,
            TabPanelMiddlewareActionType.didChangeTabPanel:
            guard let tabsModel = action.tabDisplayModel else { return defaultState(fromPreviousState: state) }

            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: tabsModel.isPrivateMode,
                                  tabs: tabsModel.tabs,
                                  inactiveTabs: tabsModel.inactiveTabs,
                                  isInactiveTabsExpanded: tabsModel.isInactiveTabsExpanded)

        case TabPanelMiddlewareActionType.willAppearTabPanel:
            let scrollModel = createTabScrollBehavior(
                forState: state,
                withScrollBehavior: .scrollToSelectedTab(shouldAnimate: false)
            )
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded,
                                  scrollState: scrollModel)

        case TabPanelMiddlewareActionType.refreshTabs:
            guard let tabModel = action.tabDisplayModel else { return defaultState(fromPreviousState: state) }
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: tabModel.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded)

        case TabPanelMiddlewareActionType.refreshInactiveTabs:
            guard let inactiveTabs = action.inactiveTabModels else { return defaultState(fromPreviousState: state) }
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded)

        case TabPanelMiddlewareActionType.showToast:
            guard let type = action.toastType else { return state }
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded,
                                  toastType: type)

        case TabPanelMiddlewareActionType.scrollToTab:
            guard let scrollBehavior = action.scrollBehavior else { return defaultState(fromPreviousState: state) }
            let scrollModel = createTabScrollBehavior(forState: state, withScrollBehavior: scrollBehavior)
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded,
                                  scrollState: scrollModel)

//        case TabPanelAction.didTapAddTab:
//        let didTapNewTab = context.didTapAddTab
//        let urlRequest = context.urlRequest
//        let isPrivateMode = context.isPrivate
//        return TabsPanelState(windowUUID: state.windowUUID,
//        isPrivateMode: isPrivateMode,
//        tabs: state.tabs,
//        inactiveTabs: state.inactiveTabs,
//        isInactiveTabsExpanded: state.isInactiveTabsExpanded,
//        didTapAddTab: didTapNewTab)

        default:
            return defaultState(fromPreviousState: state)
        }
    }

    static func reduceTabsPanelViewAction(action: TabPanelViewAction,
                                          state: TabsPanelState) -> TabsPanelState {
        switch action.actionType {
        case TabPanelViewActionType.toggleInactiveTabs:
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: !state.isInactiveTabsExpanded)

        case TabPanelViewActionType.hideUndoToast:
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded)

        default:
            return defaultState(fromPreviousState: state)
        }
    }

    // Note that the `TabsPanelState` contains a subset of all available tabs (i.e. private, normal). That means we can
    // provide a scroll index within this tabs subarray directly as this is what the UI consumes (e.g. `TabsDisplayView`).
    static func createTabScrollBehavior(
        forState state: TabsPanelState,
        withScrollBehavior scrollBehavior: TabScrollBehavior
    ) -> TabsPanelState.ScrollState? {
        guard !(state.tabs.isEmpty && state.inactiveTabs.isEmpty) else { return nil }

        if case .scrollToSelectedTab(let shouldAnimate) = scrollBehavior {
            if let selectedTabIndex = state.tabs.firstIndex(where: { $0.isSelected }) {
                return ScrollState(toIndex: selectedTabIndex, isInactiveTabSection: false, withAnimation: shouldAnimate)
            } else if !state.tabs.isEmpty {
                // If the user switches between the normal and private tab panels, there's a chance this subset of tabs does
                // not contain a selected tab. In that case, we should scroll to the bottom of the panel.
                // Note: Could optimize further by scrolling to the most recent tab if we had `lastExecutedTime` in our model
                return ScrollState(toIndex: state.tabs.count - 1, isInactiveTabSection: false, withAnimation: shouldAnimate)
            }
        } else if case .scrollToTab(let tabUUID, let shouldAnimate) = scrollBehavior {
            if let tabIndex = state.tabs.firstIndex(where: { $0.tabUUID == tabUUID }) {
                return ScrollState(toIndex: tabIndex, isInactiveTabSection: false, withAnimation: shouldAnimate)
            } else if let tabIndex = state.inactiveTabs.firstIndex(where: { $0.tabUUID == tabUUID }) {
                return ScrollState(toIndex: tabIndex, isInactiveTabSection: true, withAnimation: shouldAnimate)
            } else {
                assertionFailure("Couldn't find a tab with the given TabUUID for scrolling")
                return nil
            }
        }

        // We can arrive here if the user changes tab panels and one of the panels is empty (nothing to scroll to)
        return nil
    }
}
