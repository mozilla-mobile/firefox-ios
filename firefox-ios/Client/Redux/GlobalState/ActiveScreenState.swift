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

    static let reducer: Reducer<Self> = { screen, action in
        let actionUUID = action.windowUUID

        func applyReducer(_ actionUUID: UUID?, _ incomingState: ScreenState) -> Bool {
            // TODO: [8188] UUID will eventually be non-optional. Forthcoming.
            // If the action UUID does not match this screen, we do not apply the
            // reducer (the screen state remains unchanged, we simply return it).
            return (actionUUID == nil || actionUUID == incomingState.windowUUID)
        }

        switch screen {
        case .tabPeek(let state):
            guard applyReducer(actionUUID, state) else { return screen }
            return .tabPeek(TabPeekState.reducer(state, action))

        case .themeSettings(let state):
            guard applyReducer(actionUUID, state) else { return screen }
            return .themeSettings(ThemeSettingsState.reducer(state, action))

        case .tabsTray(let state):
            guard applyReducer(actionUUID, state) else { return screen }
            return .tabsTray(TabTrayState.reducer(state, action))

        case .tabsPanel(let state):
            guard applyReducer(actionUUID, state) else { return screen }
            return .tabsPanel(TabsPanelState.reducer(state, action))

        case .remoteTabsPanel(let state):
            guard applyReducer(actionUUID, state) else { return screen }
            return .remoteTabsPanel(RemoteTabsPanelState.reducer(state, action))

        case .browserViewController(let state):
            guard applyReducer(actionUUID, state) else { return screen }
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
                switch screenType {
                case .browserViewController:
                    screens += [.browserViewController(BrowserViewControllerState(windowUUID: context.windowUUID))]
                case .remoteTabsPanel:
                    screens += [.remoteTabsPanel(RemoteTabsPanelState(windowUUID: context.windowUUID))]
                case .tabsTray:
                    screens += [.tabsTray(TabTrayState(windowUUID: context.windowUUID))]
                case .tabsPanel:
                    screens += [.tabsPanel(TabsPanelState(windowUUID: context.windowUUID))]
                case .themeSettings:
                    screens += [.themeSettings(ThemeSettingsState(windowUUID: context.windowUUID))]
                case .tabPeek:
                    screens += [.tabPeek(TabPeekState(windowUUID: context.windowUUID))]
                }
            }
        }

        // Reduce each screen state
        screens = screens.map { AppScreenState.reducer($0, action) }

        return ActiveScreensState(screens: screens)
    }
}
