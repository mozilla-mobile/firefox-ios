// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct TabsPanelState: ScreenState, Equatable {
    struct Scroll: Equatable {
        let toIndex: Int
        let withAnimation: Bool
    }

    var isPrivateMode: Bool
    var tabs: [TabModel]
    var inactiveTabs: [InactiveTabsModel]
    var isInactiveTabsExpanded: Bool
    var toastType: ToastType?
    var windowUUID: WindowUUID
    var scroll: Scroll?
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
                  scroll: panelState.scroll,
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
            didTapAddTab: false,
            urlRequest: nil)
    }

    init(windowUUID: WindowUUID,
         isPrivateMode: Bool,
         tabs: [TabModel],
         inactiveTabs: [InactiveTabsModel],
         isInactiveTabsExpanded: Bool,
         toastType: ToastType? = nil,
         scroll: Scroll? = nil,
         didTapAddTab: Bool = false,
         urlRequest: URLRequest? = nil) {
        self.isPrivateMode = isPrivateMode
        self.tabs = tabs
        self.inactiveTabs = inactiveTabs
        self.isInactiveTabsExpanded = isInactiveTabsExpanded
        self.toastType = toastType
        self.windowUUID = windowUUID
        self.scroll = scroll
        self.didTapAddTab = didTapAddTab
        self.urlRequest = urlRequest
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        if let action = action as? TabPanelMiddlewareAction {
            return TabsPanelState.reduceTabPanelMiddlewareAction(action: action, state: state)
        } else if let action = action as? TabPanelViewAction {
            return TabsPanelState.reduceTabsPanelViewAction(action: action, state: state)
        }

        return state
    }

    static func reduceTabPanelMiddlewareAction(action: TabPanelMiddlewareAction,
                                               state: TabsPanelState) -> TabsPanelState {
        switch action.actionType {
        case TabPanelMiddlewareActionType.didLoadTabPanel,
            TabPanelMiddlewareActionType.didChangeTabPanel:
            guard let tabsModel = action.tabDisplayModel else { return state }

            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: tabsModel.isPrivateMode,
                                  tabs: tabsModel.tabs,
                                  inactiveTabs: tabsModel.inactiveTabs,
                                  isInactiveTabsExpanded: tabsModel.isInactiveTabsExpanded)

        case TabPanelMiddlewareActionType.willAppearTabPanel:
            guard let tabsModel = action.tabDisplayModel else { return state }
            var scroll: TabsPanelState.Scroll?
            if let selectedTabIndex = tabsModel.tabs.firstIndex(where: { $0.isSelected }) {
                scroll = TabsPanelState.Scroll(toIndex: selectedTabIndex, withAnimation: false)
            }
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded,
                                  scroll: scroll)

        case TabPanelMiddlewareActionType.refreshTabs:
            guard let tabModel = action.tabDisplayModel else { return state }
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: tabModel.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded)

        case TabPanelMiddlewareActionType.refreshInactiveTabs:
            guard let inactiveTabs = action.inactiveTabModels else { return state }
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
            guard let scrollBehavior = action.scrollBehavior else { return state }
            var scroll: TabsPanelState.Scroll?
            if case .scrollToSelectedTab(let shouldAnimate) = scrollBehavior,
               let selectedTabIndex = state.tabs.firstIndex(where: { $0.isSelected }) {
                scroll = Scroll(toIndex: selectedTabIndex, withAnimation: shouldAnimate)
            } else if case .scrollToTabAtIndex(let index, let shouldAnimate) = scrollBehavior {
                scroll = Scroll(toIndex: index, withAnimation: shouldAnimate)
            }
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded,
                                  scroll: scroll)

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
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded)
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
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded)
        }
    }
}
