// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

enum AppScreenState: Equatable {
   case themeSettings(ThemeSettingsState)

    static let reducer: Reducer<Self> = { state, action in
        switch state {
        case .themeSettings(let state): return .themeSettings(ThemeSettingsState.reducer(state, action))
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
            case .showScreen(.themeSettings):
                screens += [.themeSettings(ThemeSettingsState())]
            case .closeScreen(let screen): break
            }
        }

        // Reduce each screen state
        screens = screens.map { AppScreenState.reducer($0, action) }

        return ActiveScreensState(screens: screens)
    }
}
