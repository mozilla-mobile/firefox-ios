// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

struct MainState: StateType {
    var themeSettings: ThemeSettingsState

//    init() {
//        self.themeSettings = ThemeSettingsState(useSystemAppearance: true,
//                                                switchMode: .manual(.light),
//                                                manualThemeMode: .light,
//                                                systemBrightnessValue: 1.0,
//                                                userBrightnessThreshold: 0.1)
//    }
    init(themeSettings: ThemeSettingsState) {
        self.themeSettings = themeSettings
    }

    static let reducer: Reducer<Self> = { state, action in
        MainState(
            themeSettings: ThemeSettingsState.reducer(state.themeSettings, action)
        )
    }
}

let thunksMiddleware: Middleware<MainState> = createThunkMiddleware()

let store = Store(state: MainState(themeSettings: ThemeSettingsState()),
                  reducer: MainState.reducer,
                  middlewares: [thunksMiddleware])
