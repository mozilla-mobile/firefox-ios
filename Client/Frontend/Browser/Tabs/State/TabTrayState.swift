// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

enum TabTrayLayoutType: Equatable {
    case regular // iPad
    case compact // iPhone
}

struct TabTrayState: ScreenState, Equatable {
    var isPrivateMode: Bool
    var selectedPanel: TabTrayPanelType
    var tabsState: TabsState
    var remoteTabsState: RemoteTabsPanelState?

    var layout: TabTrayLayoutType = .compact
    // TODO: FXIOS-7359 Move logic to show "\u{221E}" over 100 tabs to reducer
    var normalTabsCount: String
    var navigationTitle: String {
        return selectedPanel.navTitle
    }

    var isSyncTabsPanel: Bool {
        return selectedPanel == .syncedTabs
    }

    init(_ appState: AppState) {
        guard let panelState = store.state.screenState(TabTrayState.self, for: .tabsPanel) else {
            self.init()
            return
        }

        self.init(isPrivateMode: panelState.isPrivateMode,
                  selectedPanel: panelState.selectedPanel,
                  tabsState: panelState.tabsState,
                  remoteTabsState: panelState.remoteTabsState,
                  normalTabsCount: panelState.normalTabsCount)
    }

    init() {
        self.init(isPrivateMode: false,
                  selectedPanel: .tabs,
                  tabsState: TabsState(),
                  remoteTabsState: nil,
                  normalTabsCount: "0")
    }

    init(isPrivateMode: Bool,
         selectedPanel: TabTrayPanelType,
         tabsState: TabsState,
         remoteTabsState: RemoteTabsPanelState?,
         normalTabsCount: String) {
        self.isPrivateMode = isPrivateMode
        self.selectedPanel = selectedPanel
        self.tabsState = tabsState
        self.remoteTabsState = remoteTabsState
        self.normalTabsCount = normalTabsCount
    }

    static let reducer: Reducer<Self> = {
        state,
        action in
        switch action {
        case TabTrayAction.didLoadTabData(let tabsState):
            return TabTrayState(isPrivateMode: state.isPrivateMode,
                                selectedPanel: state.selectedPanel,
                                tabsState: tabsState,
                                remoteTabsState: nil,
                                normalTabsCount: state.normalTabsCount)
        case TabTrayAction.refreshTab(let tabs):
            let newTabState = TabsState(isPrivateMode: state.tabsState.isPrivateMode,
                                        tabs: tabs,
                                        inactiveTabs: state.tabsState.inactiveTabs,
                                        isInactiveTabsExpanded: state.tabsState.isInactiveTabsExpanded)
            return TabTrayState(isPrivateMode: state.isPrivateMode,
                                selectedPanel: state.selectedPanel,
                                tabsState: newTabState,
                                remoteTabsState: nil,
                                normalTabsCount: state.normalTabsCount)
        case TabTrayAction.toggleInactiveTabs(let tabsExpandedNewState):
            let newTabState = TabsState(isPrivateMode: state.tabsState.isPrivateMode,
                                        tabs: state.tabsState.tabs,
                                        inactiveTabs: state.tabsState.inactiveTabs,
                                        isInactiveTabsExpanded: tabsExpandedNewState)
            return TabTrayState(isPrivateMode: state.isPrivateMode,
                                selectedPanel: state.selectedPanel,
                                tabsState: newTabState,
                                remoteTabsState: nil,
                                normalTabsCount: state.normalTabsCount)
        default:
            return state
        }
    }

    static func == (lhs: TabTrayState, rhs: TabTrayState) -> Bool {
        return lhs.isPrivateMode == rhs.isPrivateMode
        && lhs.selectedPanel == rhs.selectedPanel
        && lhs.layout == rhs.layout
    }
}
