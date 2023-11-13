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
    var tabs: [TabCellState]

    // MARK: Inactive tabs
    var inactiveTabs: [String]
    var isInactiveTabsExpanded = true

    var isPrivateTabsEmpty: Bool {
        guard isPrivateMode else { return false }
        return tabs.isEmpty
    }

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
                  tabs: panelState.tabs,
                  remoteTabsState: panelState.remoteTabsState,
                  normalTabsCount: panelState.normalTabsCount,
                  inactiveTabs: panelState.inactiveTabs)
    }

    init() {
        self.init(isPrivateMode: false,
                  selectedPanel: .tabs,
                  tabs: [TabCellState](),
                  remoteTabsState: nil,
                  normalTabsCount: "0",
                  inactiveTabs: [String]())
    }

    init(isPrivateMode: Bool,
         selectedPanel: TabTrayPanelType,
         tabs: [TabCellState],
         remoteTabsState: RemoteTabsPanelState?,
         normalTabsCount: String,
         inactiveTabs: [String] = [String]()) {
        self.isPrivateMode = isPrivateMode
        self.selectedPanel = selectedPanel
        self.tabs = tabs
        self.remoteTabsState = remoteTabsState
        self.normalTabsCount = normalTabsCount
        self.inactiveTabs = inactiveTabs
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case TabTrayAction.didLoadTabData(let newState):
            return newState
        case TabTrayAction.refreshTab(let tabs):
            return TabTrayState(isPrivateMode: state.isPrivateMode,
                                selectedPanel: state.selectedPanel,
                                tabs: tabs,
                                remoteTabsState: nil,
                                normalTabsCount: state.normalTabsCount,
                                inactiveTabs: state.inactiveTabs)
        default:
            return state
        }
    }

    static func == (lhs: TabTrayState, rhs: TabTrayState) -> Bool {
        return lhs.isPrivateMode == rhs.isPrivateMode
        && lhs.selectedPanel == rhs.selectedPanel
        && lhs.layout == rhs.layout
        && lhs.tabs == rhs.tabs
    }
}
