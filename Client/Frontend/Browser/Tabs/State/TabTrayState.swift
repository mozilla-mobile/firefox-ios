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
    var selectedPanel: TabTrayPanelType?
    var tabViewState: TabViewState
    var remoteTabsState: RemoteTabsPanelState?

    var layout: TabTrayLayoutType = .compact
    // TODO: FXIOS-7359 Move logic to show "\u{221E}" over 100 tabs to reducer
    var normalTabsCount: String
    var navigationTitle: String? {
        return selectedPanel?.navTitle
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
                  tabViewState: panelState.tabViewState,
                  remoteTabsState: panelState.remoteTabsState,
                  normalTabsCount: panelState.normalTabsCount)
    }

    init() {
        let tabViewState = TabViewState.getMockState(isPrivateMode: false)
        self.init(isPrivateMode: false,
                  tabViewState: tabViewState,
                  remoteTabsState: nil,
                  normalTabsCount: "2")
    }

    init(isPrivateMode: Bool,
         tabViewState: TabViewState,
         remoteTabsState: RemoteTabsPanelState?,
         normalTabsCount: String) {
        self.isPrivateMode = isPrivateMode
        self.tabViewState = tabViewState
        self.remoteTabsState = remoteTabsState
        self.normalTabsCount = normalTabsCount
    }

    static let reducer: Reducer<Self> = { state, action in
        // TODO: Complete in FXIOS-7359
        return state
    }

    static func == (lhs: TabTrayState, rhs: TabTrayState) -> Bool {
        return lhs.isPrivateMode == rhs.isPrivateMode
        && lhs.selectedPanel == rhs.selectedPanel
        && lhs.layout == rhs.layout
        && lhs.tabViewState == rhs.tabViewState
    }
}
