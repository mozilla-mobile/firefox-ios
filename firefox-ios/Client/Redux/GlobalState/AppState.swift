// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct AppState: StateType {
    let activeScreens: ActiveScreensState

    static let reducer: Reducer<Self> = { state, action in
        AppState(activeScreens: ActiveScreensState.reducer(state.activeScreens, action))
    }

    func screenState<S: ScreenState>(_ s: S.Type,
                                     for screen: AppScreen,
                                     window: WindowUUID?) -> S? {
        return activeScreens.screens
            .compactMap {
                switch ($0, screen) {
                case (.browserViewController(let state), .browserViewController): return state as? S
                case (.mainMenu(let state), .mainMenu): return state as? S
                case (.mainMenuDetails(let state), .mainMenuDetails): return state as? S
                case (.microsurvey(let state), .microsurvey): return state as? S
                case (.remoteTabsPanel(let state), .remoteTabsPanel): return state as? S
                case (.tabsPanel(let state), .tabsPanel): return state as? S
                case (.tabPeek(let state), .tabPeek): return state as? S
                case (.tabsTray(let state), .tabsTray): return state as? S
                case (.themeSettings(let state), .themeSettings): return state as? S
                case (.toolbar(let state), .toolbar): return state as? S
                case (.trackingProtection(let state), .trackingProtection): return state as? S
                default: return nil
                }
            }.first(where: {
                // Most screens should be filtered based on the specific identifying UUID.
                // This is necessary to allow us to have more than 1 of the same type of
                // screen in Redux at the same time. If no UUID is provided we return `first`.
                guard let expectedUUID = window else { return true }
                // Generally this should be considered a code smell, attempting to select the
                // screen for an .unavailable window is nonsensical and may indicate a bug.
                guard expectedUUID != .unavailable else { return true }

                return $0.windowUUID == expectedUUID
            })
    }
}

extension AppState {
    init() {
        activeScreens = ActiveScreensState()
    }
}

let middlewares = [
    FeltPrivacyMiddleware().privacyManagerProvider,
    MainMenuMiddleware().mainMenuProvider,
    MicrosurveyMiddleware().microsurveyProvider,
    MicrosurveyPromptMiddleware().microsurveyProvider,
    RemoteTabsPanelMiddleware().remoteTabsPanelProvider,
    TabManagerMiddleware().tabsPanelProvider,
    ThemeManagerMiddleware().themeManagerProvider,
    ToolbarMiddleware().toolbarProvider,
    TrackingProtectionMiddleware().trackingProtectionProvider
]

// In order for us to mock and test the middlewares easier,
// we change the store to be instantiated as a variable.
// For non testing builds, we leave the store as a constant.
#if TESTING
var store = Store(state: AppState(),
                  reducer: AppState.reducer,
                  middlewares: middlewares)
#else
let store = Store(state: AppState(),
                  reducer: AppState.reducer,
                  middlewares: middlewares)
#endif
