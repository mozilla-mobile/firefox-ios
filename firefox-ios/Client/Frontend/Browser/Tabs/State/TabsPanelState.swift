// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct TabsPanelState: ScreenState, Equatable {
    var isPrivateMode: Bool
    var tabs: [TabModel]
    var inactiveTabs: [InactiveTabsModel]
    var isInactiveTabsExpanded: Bool
    var toastType: ToastType?
    var windowUUID: WindowUUID
    var scrollToIndex: Int?

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
                  scrollToIndex: panelState.scrollToIndex)
    }

    init(windowUUID: WindowUUID, isPrivateMode: Bool = false) {
        self.init(
            windowUUID: windowUUID,
            isPrivateMode: isPrivateMode,
            tabs: [TabModel](),
            inactiveTabs: [InactiveTabsModel](),
            isInactiveTabsExpanded: false,
            toastType: nil)
    }

    init(windowUUID: WindowUUID,
         isPrivateMode: Bool,
         tabs: [TabModel],
         inactiveTabs: [InactiveTabsModel],
         isInactiveTabsExpanded: Bool,
         toastType: ToastType? = nil,
         scrollToIndex: Int? = nil) {
        self.isPrivateMode = isPrivateMode
        self.tabs = tabs
        self.inactiveTabs = inactiveTabs
        self.isInactiveTabsExpanded = isInactiveTabsExpanded
        self.toastType = toastType
        self.windowUUID = windowUUID
        self.scrollToIndex = scrollToIndex
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == nil || action.windowUUID == state.windowUUID else { return state }

        switch action {
        case TabPanelAction.didLoadTabPanel(let tabsModel):
            let selectedTabIndex = tabsModel.tabs.firstIndex(where: { $0.isSelected })
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: tabsModel.isPrivateMode,
                                  tabs: tabsModel.tabs,
                                  inactiveTabs: tabsModel.inactiveTabs,
                                  isInactiveTabsExpanded: tabsModel.isInactiveTabsExpanded,
                                  scrollToIndex: selectedTabIndex)
        case TabPanelAction.refreshTab(let tabModel):
            var selectedTabIndex: Int?
            if tabModel.shouldScrollToTab {
                selectedTabIndex = tabModel.tabs.firstIndex(where: { $0.isSelected })
            }
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: tabModel.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded,
                                  scrollToIndex: selectedTabIndex)
        case TabPanelAction.toggleInactiveTabs:
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: !state.isInactiveTabsExpanded)
        case TabPanelAction.refreshInactiveTabs(let inactiveTabs):
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded)
        case TabPanelAction.showToast(let type):
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded,
                                  toastType: type)
        case TabPanelAction.hideUndoToast:
            return TabsPanelState(windowUUID: state.windowUUID,
                                  isPrivateMode: state.isPrivateMode,
                                  tabs: state.tabs,
                                  inactiveTabs: state.inactiveTabs,
                                  isInactiveTabsExpanded: state.isInactiveTabsExpanded)
        default: return TabsPanelState(windowUUID: state.windowUUID,
                                       isPrivateMode: state.isPrivateMode,
                                       tabs: state.tabs,
                                       inactiveTabs: state.inactiveTabs,
                                       isInactiveTabsExpanded: state.isInactiveTabsExpanded)
        }
    }
}
