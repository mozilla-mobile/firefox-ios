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
        guard let panelState = store.state.screenState(TabTrayState.self, for: .tabsTray) else {
            self.init()
            return
        }

        self.init(isPrivateMode: panelState.isPrivateMode,
                  selectedPanel: panelState.selectedPanel,
                  normalTabsCount: panelState.normalTabsCount)
    }

    init() {
        self.init(isPrivateMode: false,
                  selectedPanel: .tabs,
                  normalTabsCount: "0")
    }

    init(isPrivateMode: Bool,
         selectedPanel: TabTrayPanelType,
         normalTabsCount: String) {
        self.isPrivateMode = isPrivateMode
        self.selectedPanel = selectedPanel
        self.normalTabsCount = normalTabsCount
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case TabTrayAction.didLoadTabTray(let tabTrayModel):
            return TabTrayState(isPrivateMode: tabTrayModel.isPrivateMode,
                                selectedPanel: tabTrayModel.selectedPanel,
                                normalTabsCount: tabTrayModel.normalTabsCount)
        case TabTrayAction.changePanel(let panelType):
            return TabTrayState(isPrivateMode: panelType == .privateTabs,
                                selectedPanel: panelType,
                                normalTabsCount: state.normalTabsCount)
        case TabPanelAction.didLoadTabPanel(let tabState):
            let panelType = tabState.isPrivateMode ? TabTrayPanelType.privateTabs : TabTrayPanelType.tabs
            return TabTrayState(isPrivateMode: tabState.isPrivateMode,
                                selectedPanel: panelType,
                                normalTabsCount: "\(tabState.tabs.count)")
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
