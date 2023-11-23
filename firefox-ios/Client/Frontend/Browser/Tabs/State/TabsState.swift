// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct TabsState: ScreenState, Equatable {
    var isPrivateMode: Bool
    var tabs: [TabCellModel]
    var isPrivateTabsEmpty: Bool {
        guard isPrivateMode else { return false }
        return tabs.isEmpty
    }

    // MARK: Inactive tabs
    var inactiveTabs: [String]
    var isInactiveTabsExpanded: Bool

    init(_ appState: AppState) {
        guard let panelState = store.state.screenState(TabsState.self, for: .tabsPanel) else {
            self.init()
            return
        }

        self.init(isPrivateMode: panelState.isPrivateMode,
                  tabs: panelState.tabs,
                  inactiveTabs: panelState.inactiveTabs,
                  isInactiveTabsExpanded: panelState.isInactiveTabsExpanded)
    }

    init(isPrivateMode: Bool = false) {
        self.init(isPrivateMode: isPrivateMode,
                  tabs: [TabCellModel](),
                  inactiveTabs: [String](),
                  isInactiveTabsExpanded: false)
    }

    init(isPrivateMode: Bool,
         tabs: [TabCellModel],
         inactiveTabs: [String],
         isInactiveTabsExpanded: Bool) {
        self.isPrivateMode = isPrivateMode
        self.tabs = tabs
        self.inactiveTabs = inactiveTabs
        self.isInactiveTabsExpanded = isInactiveTabsExpanded
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case TabPanelAction.didLoadTabPanel(let tabsModel):
            return TabsState(isPrivateMode: tabsModel.isPrivateMode,
                             tabs: tabsModel.tabs,
                             inactiveTabs: tabsModel.inactiveTabs,
                             isInactiveTabsExpanded: tabsModel.isInactiveTabsExpanded)
        case TabPanelAction.refreshTab(let tabs):
            return TabsState(isPrivateMode: state.isPrivateMode,
                             tabs: tabs,
                             inactiveTabs: state.inactiveTabs,
                             isInactiveTabsExpanded: state.isInactiveTabsExpanded)
        case TabPanelAction.toggleInactiveTabs:
            return TabsState(isPrivateMode: state.isPrivateMode,
                             tabs: state.tabs,
                             inactiveTabs: state.inactiveTabs,
                             isInactiveTabsExpanded: !state.isInactiveTabsExpanded)
        default: return state
        }
    }
}
