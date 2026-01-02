// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct TabsPanelState: ScreenState, Equatable {
    struct ScrollState: Equatable {
        let toIndex: Int
        let withAnimation: Bool
    }

    var isPrivateMode: Bool
    var tabs: [TabModel]
    var windowUUID: WindowUUID
    var scrollState: ScrollState?
    var didTapAddTab: Bool
    var urlRequest: URLRequest?

    var isPrivateTabsEmpty: Bool {
        guard isPrivateMode else { return true }
        return tabs.isEmpty
    }

    init(appState: AppState, uuid: WindowUUID) {
        guard let panelState = appState.screenState(
            TabsPanelState.self,
            for: .tabsPanel,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: panelState.windowUUID,
                  isPrivateMode: panelState.isPrivateMode,
                  tabs: panelState.tabs,
                  scrollState: panelState.scrollState,
                  didTapAddTab: panelState.didTapAddTab,
                  urlRequest: panelState.urlRequest)
    }

    init(windowUUID: WindowUUID, isPrivateMode: Bool = false) {
        self.init(
            windowUUID: windowUUID,
            isPrivateMode: isPrivateMode,
            tabs: [TabModel](),
            toastType: nil,
            scrollState: nil,
            didTapAddTab: false,
            urlRequest: nil)
    }

    init(windowUUID: WindowUUID,
         isPrivateMode: Bool,
         tabs: [TabModel],
         toastType: ToastType? = nil,
         scrollState: ScrollState? = nil,
         didTapAddTab: Bool = false,
         urlRequest: URLRequest? = nil) {
        self.isPrivateMode = isPrivateMode
        self.tabs = tabs
        self.windowUUID = windowUUID
        self.scrollState = scrollState
        self.didTapAddTab = didTapAddTab
        self.urlRequest = urlRequest
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        if let action = action as? TabPanelMiddlewareAction {
            return TabsPanelState.reduceTabPanelMiddlewareAction(action: action, state: state)
        }

        return defaultState(from: state)
    }

    static func reduceTabPanelMiddlewareAction(action: TabPanelMiddlewareAction,
                                               state: TabsPanelState) -> TabsPanelState {
        switch action.actionType {
        case TabPanelMiddlewareActionType.didLoadTabPanel,
            TabPanelMiddlewareActionType.didChangeTabPanel:
            guard let tabsModel = action.tabDisplayModel else { return defaultState(from: state) }

            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: tabsModel.isPrivateMode,
                                  tabs: tabsModel.tabs)

        case TabPanelMiddlewareActionType.willAppearTabPanel:
            let scrollModel = createTabScrollBehavior(
                forState: state,
                withScrollBehavior: .scrollToSelectedTab(shouldAnimate: false)
            )
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  scrollState: scrollModel)

        case TabPanelMiddlewareActionType.refreshTabs:
            guard let tabModel = action.tabDisplayModel else { return defaultState(from: state) }
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: tabModel.tabs)

        case TabPanelMiddlewareActionType.scrollToTab:
            guard let scrollBehavior = action.scrollBehavior else { return defaultState(from: state) }
            let scrollModel = createTabScrollBehavior(forState: state, withScrollBehavior: scrollBehavior)
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  scrollState: scrollModel)

        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: TabsPanelState) -> TabsPanelState {
        return TabsPanelState(windowUUID: state.windowUUID,
                              isPrivateMode: state.isPrivateMode,
                              tabs: state.tabs)
    }

    static func createTabScrollBehavior(
        forState state: TabsPanelState,
        withScrollBehavior scrollBehavior: TabScrollBehavior
    ) -> TabsPanelState.ScrollState? {
        guard !state.tabs.isEmpty else { return nil }

        if case .scrollToSelectedTab(let shouldAnimate) = scrollBehavior {
            if let selectedTabIndex = state.tabs.firstIndex(where: { $0.isSelected }) {
                return ScrollState(toIndex: selectedTabIndex, withAnimation: shouldAnimate)
            } else if !state.tabs.isEmpty {
                // If the user switches between the normal and private tab panels, there's a chance this subset of tabs does
                // not contain a selected tab. In that case, we should scroll to the bottom of the panel.
                // Note: Could optimize further by scrolling to the most recent tab if we had `lastExecutedTime` in our model
                return ScrollState(toIndex: state.tabs.count - 1, withAnimation: shouldAnimate)
            }
        } else if case .scrollToTab(let tabUUID, let shouldAnimate) = scrollBehavior {
            if let tabIndex = state.tabs.firstIndex(where: { $0.tabUUID == tabUUID }) {
                return ScrollState(toIndex: tabIndex, withAnimation: shouldAnimate)
            } else {
                // This can happen if the user closes a tab, switches to a different tab panel, and then taps "undo"
                return nil
            }
        }

        // This can happen if the user changes tab panels and one of the panels is empty (nothing to scroll to)
        return nil
    }
}
