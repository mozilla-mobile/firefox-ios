// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum ThemeSettingsScreen: Equatable {
    case show(ThemeSettingsState)
    case close
}

struct MainState: StateType, Equatable {
    var themeSettingsState: ThemeSettingsState
    var themeManagerScreen: ThemeSettingsScreen
}

let store = Store(state: AppState(),
                  reducer: AppState.reducer,
                  middlewares: [ThemeManagerMiddleware().setSystemTheme])
