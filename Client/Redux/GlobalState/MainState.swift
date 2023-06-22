// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum ThemeSettingsState: Equatable {
    case show(ThemeManagerState)
    case close
}

struct MainState: StateType, Equatable {
    var themeSettingsState: ThemeSettingsState
    var themeManagerState: ThemeManagerState

    func mainReducer(action: Action, state: MainState?) -> MainState {
    }
}

let mainState = MainState()
let store = Store(state: mainState(),
                  reducer: mainState.mainReducer(action: <#T##Action#>, state: <#T##MainState?#>),
                  middlewares: [ThemeManagerMiddleware().setSystemTheme])
