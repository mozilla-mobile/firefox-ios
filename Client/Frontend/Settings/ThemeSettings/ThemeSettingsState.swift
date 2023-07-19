// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

enum SwitchMode: Equatable {
    case manual(ThemeType)
    case automatic
}

protocol ReduxState {}

struct ThemeSettingsState: ReduxState, Equatable {
    var useSystemAppearance: Bool
    var switchMode: SwitchMode
    var systemBrightnessValue: Float
    var userBrightnessThreshold: Float

    init(_ appState: AppState) {
        guard let themeState = store.state.screenState(ThemeSettingsState.self, for: .themeSettings) else {
            print("YRD themeSettings state failed")
            self.init()
            return
        }

        print("YRD themeState \(themeState)")
        self.init(useSystemAppearance: themeState.useSystemAppearance,
                  switchMode: themeState.switchMode,
                  systemBrightnessValue: themeState.systemBrightnessValue,
                  userBrightnessThreshold: themeState.userBrightnessThreshold)
    }

    init() {
        self.useSystemAppearance = false
        self.switchMode = .manual(ThemeType.light)
        self.systemBrightnessValue =  0.3
        self.userBrightnessThreshold = 0.4
    }

    init(useSystemAppearance: Bool,
         switchMode: SwitchMode,
         systemBrightnessValue: Float,
         userBrightnessThreshold: Float) {
        self.useSystemAppearance = useSystemAppearance
        self.switchMode = switchMode
        self.systemBrightnessValue =  systemBrightnessValue
        self.userBrightnessThreshold = userBrightnessThreshold
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case ThemeSettingsAction.fetchThemeManagerValues:
            return ThemeSettingsState()

        case ThemeSettingsAction.receivedThemeManagerValues(let themeState):
            return themeState

        case ThemeSettingsAction.systemThemeChanged(let isEnabled):
            return ThemeSettingsState(useSystemAppearance: isEnabled,
                                      switchMode: state.switchMode,
                                      systemBrightnessValue: state.systemBrightnessValue,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
        default:
            return state
        }
    }
}
