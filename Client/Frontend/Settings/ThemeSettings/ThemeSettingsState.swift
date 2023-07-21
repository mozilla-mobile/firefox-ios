// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ReduxState {}

struct ThemeSettingsState: ReduxState, Equatable {
    var useSystemAppearance: Bool
    var isAutomaticBrightnessEnable: Bool
    var manualThemeSelected: BuiltinThemeName
    var userBrightnessThreshold: Float

    init(_ appState: AppState) {
        guard let themeState = store.state.screenState(ThemeSettingsState.self, for: .themeSettings) else {
            self.init()
            return
        }

        self.init(useSystemAppearance: themeState.useSystemAppearance,
                  isAutomaticBrightnessEnable: themeState.isAutomaticBrightnessEnable,
                  manualThemeSelected: themeState.manualThemeSelected,
                  userBrightnessThreshold: themeState.userBrightnessThreshold)
    }

    init() {
        self.useSystemAppearance = false
        self.isAutomaticBrightnessEnable = false
        self.manualThemeSelected = .normal
        self.userBrightnessThreshold = 0.4
    }

    init(useSystemAppearance: Bool,
         isAutomaticBrightnessEnable: Bool,
         manualThemeSelected: BuiltinThemeName,
         userBrightnessThreshold: Float) {
        self.useSystemAppearance = useSystemAppearance
        self.isAutomaticBrightnessEnable = isAutomaticBrightnessEnable
        self.manualThemeSelected = manualThemeSelected
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
                                      userBrightnessThreshold: state.userBrightnessThreshold)

        case ThemeSettingsAction.automaticBrightnessChanged(let isEnabled):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: isEnabled,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
        case ThemeSettingsAction.manualThemeChanged(let theme):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
                                      manualThemeSelected: theme,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
        default:
            return state
        }
    }
}
