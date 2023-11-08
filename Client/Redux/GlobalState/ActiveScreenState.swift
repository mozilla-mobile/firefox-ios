// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

enum AppScreenState: Equatable {
    case themeSettings(ThemeSettingsState)
    case tabsPanel(TabTrayState)
    case remoteTabsPanel(RemoteTabsPanelState)

    static let reducer: Reducer<Self> = { state, action in
        switch state {
        case .themeSettings(let state): return .themeSettings(ThemeSettingsState.reducer(state, action))
        case .tabsPanel(let state): return
                .tabsPanel(TabTrayState.reducer(state, action))
        case .remoteTabsPanel(let state): return .remoteTabsPanel(RemoteTabsPanelState.reducer(state, action))
        }
    }

    /// Returns the matching AppScreen enum for a given AppScreenState
    var associatedAppScreen: AppScreen {
        switch self {
        case .themeSettings: return .themeSettings
        case .remoteTabsPanel: return .remoteTabsPanel
        case .tabsPanel: return .tabsPanel
        }
    }
}

struct ActiveScreensState: Equatable {
    let screens: [AppScreenState]

    init() {
        self.screens = []
    }

    init(screens: [AppScreenState]) {
        self.screens = screens
    }

    static let reducer: Reducer<Self> = { state, action in
        var screens = state.screens

        if let action = action as? ActiveScreensStateAction {
            switch action {
            case .closeScreen(let screenType):
                screens = screens.filter({ return $0.associatedAppScreen != screenType })
            case .showScreen(.themeSettings):
                screens += [.themeSettings(ThemeSettingsState())]
            case .showScreen(.tabsPanel):
                screens += [.tabsPanel(TabTrayState())]
            case .showScreen(.remoteTabsPanel):
                screens += [.remoteTabsPanel(RemoteTabsPanelState())]
            }
        }

        // Reduce each screen state
        screens = screens.map { AppScreenState.reducer($0, action) }

        return ActiveScreensState(screens: screens)
    }
}
