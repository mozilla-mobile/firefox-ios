// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ReduxState {}

struct ThemeSettingsState: ReduxState, Equatable {
    var useSystemAppearance: Bool
    var isAutomaticBrightnessEnable: Bool
    var manualThemeSelected: ThemeType
    var systemBrightnessValue: Float
    var userBrightnessThreshold: Float

    init(_ appState: AppState) {
        guard let themeState = store.state.screenState(ThemeSettingsState.self, for: .themeSettings) else {
            self.init()
            return
        }

        self.init(useSystemAppearance: themeState.useSystemAppearance,
                  isAutomaticBrightnessEnable: themeState.isAutomaticBrightnessEnable,
                  manualThemeSelected: themeState.manualThemeSelected,
                  systemBrightnessValue: themeState.systemBrightnessValue,
                  userBrightnessThreshold: themeState.userBrightnessThreshold)
    }

    init() {
        self.useSystemAppearance = false
        self.isAutomaticBrightnessEnable = false
        self.manualThemeSelected = .light
        self.systemBrightnessValue =  0.3
        self.userBrightnessThreshold = 0.4
    }

    init(useSystemAppearance: Bool,
         isAutomaticBrightnessEnable: Bool,
         manualThemeSelected: ThemeType,
         systemBrightnessValue: Float,
         userBrightnessThreshold: Float) {
        self.useSystemAppearance = useSystemAppearance
        self.isAutomaticBrightnessEnable = isAutomaticBrightnessEnable
        self.manualThemeSelected = manualThemeSelected
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
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
                                      manualThemeSelected: state.manualThemeSelected,
                                      systemBrightnessValue: state.systemBrightnessValue,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
        default:
            return state
        }
    }
}
