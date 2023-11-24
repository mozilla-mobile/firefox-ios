// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

enum AppScreenState: Equatable {
    case themeSettings(ThemeSettingsState)
    case tabsTray(TabTrayState)
    case tabsPanel(TabsPanelState)
    case remoteTabsPanel(RemoteTabsPanelState)
    case fakespot(FakespotState)

    static let reducer: Reducer<Self> = { state, action in
        switch state {
        case .themeSettings(let state): return .themeSettings(ThemeSettingsState.reducer(state, action))
        case .tabsTray(let state): return .tabsTray(TabTrayState.reducer(state, action))
        case .tabsPanel(let state): return .tabsPanel(TabsPanelState.reducer(state, action))
        case .remoteTabsPanel(let state): return .remoteTabsPanel(RemoteTabsPanelState.reducer(state, action))
        case .fakespot(let state): return .fakespot(FakespotState.reducer(state, action))
        }
    }

    /// Returns the matching AppScreen enum for a given AppScreenState
    var associatedAppScreen: AppScreen {
        switch self {
        case .themeSettings: return .themeSettings
        case .tabsTray: return .tabsTray
        case .tabsPanel: return .tabsPanel
        case .fakespot: return .fakespot
        case .remoteTabsPanel: return .remoteTabsPanel
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
            case .showScreen(.tabsTray):
                screens += [.tabsTray(TabTrayState())]
            case .showScreen(.tabsPanel):
                screens += [.tabsPanel(TabsPanelState())]
            case .showScreen(.remoteTabsPanel):
                screens += [.remoteTabsPanel(RemoteTabsPanelState())]
            case .showScreen(.fakespot):
                screens += [.fakespot(FakespotState())]
            }
        }

        // Reduce each screen state
        screens = screens.map { AppScreenState.reducer($0, action) }

        return ActiveScreensState(screens: screens)
    }
}
