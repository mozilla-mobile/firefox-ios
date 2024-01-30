// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

enum AppScreenState: Equatable {
    case browserViewController(BrowserViewControllerState)
    case remoteTabsPanel(RemoteTabsPanelState)
    case tabsPanel(TabsPanelState)
    case tabsTray(TabTrayState)
    case themeSettings(ThemeSettingsState)
    case tabPeek(TabPeekState)

    static let reducer: Reducer<Self> = { state, action in
        switch state {
        case .tabPeek(let state):
            return .tabPeek(TabPeekState.reducer(state, action))
        case .themeSettings(let state):
            return .themeSettings(ThemeSettingsState.reducer(state, action))
        case .tabsTray(let state):
            return .tabsTray(TabTrayState.reducer(state, action))
        case .tabsPanel(let state):
            return .tabsPanel(TabsPanelState.reducer(state, action))
        case .remoteTabsPanel(let state):
            return .remoteTabsPanel(RemoteTabsPanelState.reducer(state, action))
        case .browserViewController(let state):
            return .browserViewController(BrowserViewControllerState.reducer(state, action))
        }
    }

    /// Returns the matching AppScreen enum for a given AppScreenState
    var associatedAppScreen: AppScreen {
        switch self {
        case .browserViewController: return .browserViewController
        case .themeSettings: return .themeSettings
        case .tabsTray: return .tabsTray
        case .tabsPanel: return .tabsPanel
        case .remoteTabsPanel: return .remoteTabsPanel
        case .tabPeek: return .tabPeek
        }
    }

    var windowUUID: WindowUUID? {
        switch self {
        case .browserViewController(let state): return state.windowUUID
        case .remoteTabsPanel(let state): return state.windowUUID
        case .tabsTray(let state): return state.windowUUID
        case .tabsPanel(let state): return state.windowUUID
        case .themeSettings(let state): return state.windowUUID
        case .tabPeek(let state): return state.windowUUID
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
            case .closeScreen(let context):
                let uuid = context.windowUUID
                let screenType = context.screen
                screens = screens.filter({
                    return $0.associatedAppScreen != screenType || $0.windowUUID != uuid
                })
            case .showScreen(let context):
                let screenType = context.screen
                let uuid = context.windowUUID
                switch screenType {
                case .browserViewController:
                    screens.append(.browserViewController(BrowserViewControllerState(windowUUID: uuid)))
                case .remoteTabsPanel:
                    screens.append(.remoteTabsPanel(RemoteTabsPanelState(windowUUID: uuid)))
                case .tabsTray:
                    screens.append(.tabsTray(TabTrayState(windowUUID: uuid)))
                case .tabsPanel:
                    screens.append(.tabsPanel(TabsPanelState(windowUUID: uuid)))
                case .themeSettings:
                    screens.append(.themeSettings(ThemeSettingsState(windowUUID: uuid)))
                case .tabPeek:
                    screens.append(.tabPeek(TabPeekState(windowUUID: uuid)))
                }
            }
        }

        // Reduce each screen state
        screens = screens.map { AppScreenState.reducer($0, action) }

        return ActiveScreensState(screens: screens)
    }
}
