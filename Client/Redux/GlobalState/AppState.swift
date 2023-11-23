// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct AppState: StateType {
    let activeScreens: ActiveScreensState
    let isInPrivateMode: Bool

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case AppStateAction.setPrivateModeTo(let privateState):
            AppState(
                activeScreens: ActiveScreensState.reducer(state.activeScreens, action),
                isInPrivateMode: privateState
            )
        default:
            AppState(
                activeScreens: ActiveScreensState.reducer(state.activeScreens, action),
                isInPrivateMode: state.isInPrivateMode
            )
        }
    }

    func screenState<S: ScreenState>(_ s: S.Type, for screen: AppScreen) -> S? {
        return activeScreens.screens
            .compactMap {
                switch ($0, screen) {
                case (.themeSettings(let state), .themeSettings): return state as? S
                case (.tabsTray(let state), .tabsTray): return state as? S
                case (.tabsPanel(let state), .tabsPanel): return state as? S
                case (.remoteTabsPanel(let state), .remoteTabsPanel): return state as? S
                case (.fakespot(let state), .fakespot): return state as? S
                default: return nil
                }
            }
            .first
    }
}

extension AppState {
    init() {
        activeScreens = ActiveScreensState()
        isInPrivateMode = false
    }
}

let store = Store(state: AppState(),
                  reducer: AppState.reducer,
                  middlewares: [ThemeManagerMiddleware().themeManagerProvider,
                                TabsPanelMiddleware().tabsPanelProvider,
                                RemoteTabsPanelMiddleware().remoteTabsPanelProvider])
