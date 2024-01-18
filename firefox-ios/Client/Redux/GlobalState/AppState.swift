// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct AppState: StateType {
    let activeScreens: ActiveScreensState

    static let reducer: Reducer<Self> = { state, action in
        AppState(activeScreens: ActiveScreensState.reducer(state.activeScreens, action))
    }

    func screenState<S: ScreenState>(_ s: S.Type,
                                     for screen: AppScreen,
                                     /* TODO: Fix me. This shouldn't be optional? */
                                     window: WindowUUID?) -> S? {
        // TODO: Need to fix this?
        return activeScreens.screens
            .compactMap {
                switch ($0, screen) {
                case (.tabPeek(let state), .tabPeek): return state as? S
                case (.themeSettings(let state), .themeSettings): return state as? S
                case (.tabsTray(let state), .tabsTray): return state as? S
                case (.tabsPanel(let state), .tabsPanel): return state as? S
                case (.remoteTabsPanel(let state), .remoteTabsPanel): return state as? S
                case (.browserViewController(let state), .browserViewController): return state as? S
                default: return nil
                }
            }
            .first(where: { 
                // Only the screen state for the specific window
                guard let windowUUIDFilter = window else { return true }
                return $0.windowUUID == window
            })
    }
}

extension AppState {
    init() {
        activeScreens = ActiveScreensState()
    }
}

// Client base ActionContext class.
class ActionContext {
    let windowUUID: WindowUUID

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
    }
}

let store = Store(state: AppState(),
                  reducer: AppState.reducer,
                  middlewares: [
                    FeltPrivacyMiddleware().privacyManagerProvider,
                    ThemeManagerMiddleware().themeManagerProvider,
                    TabManagerMiddleware().tabsPanelProvider,
                    RemoteTabsPanelMiddleware().remoteTabsPanelProvider
                  ])
