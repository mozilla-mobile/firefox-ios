// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum ThemePicker: Equatable {
    case light
    case dark
}

enum SwitchMode: Equatable {
    case manual(ThemePicker)
    case automatic(Float)
}

struct ThemeSettingsState: Equatable {
    // Use system Light/Dark mode
    var useSystemAppearance: Bool
    var switchMode: SwitchMode
    var manualThemeMode: ThemePicker
    var systemBrightnessValue: Float
    var userBrightnessThreshold: Float

    init(_ appState: AppState) {
        self.useSystemAppearance = false
        self.switchMode = .manual(ThemePicker.light)
        self.manualThemeMode = .light
        self.systemBrightnessValue =  1
        self.userBrightnessThreshold = 0.1
    }

    init() {
        self.useSystemAppearance = false
        self.switchMode = .manual(ThemePicker.light)
        self.manualThemeMode = .light
        self.systemBrightnessValue =  1
        self.userBrightnessThreshold = 0.1
    }

    init(useSystemAppearance: Bool,
         switchMode: SwitchMode,
         manualThemeMode: ThemePicker,
         systemBrightnessValue: Float,
         userBrightnessThreshold: Float) {
        self.useSystemAppearance = useSystemAppearance
        self.switchMode = switchMode
        self.manualThemeMode = manualThemeMode
        self.systemBrightnessValue =  systemBrightnessValue
        self.userBrightnessThreshold = userBrightnessThreshold
    }

    // TODO: Add action to fetchThemeValues and receivedThemeValues
    static let reducer: Reducer<Self> = { state, action in
        switch action {
//        case ActiveScreensStateAction.showScreen(.themeSettings(let themeSettingsState)):
//            return ThemeSettingsState(useSystemAppearance: themeSettingsState.useSystemAppearance,
//                                      switchMode: themeSettingsState.switchMode,
//                                      manualThemeMode: themeSettingsState.manualThemeMode,
//                                      systemBrightnessValue: themeSettingsState.systemBrightnessValue,
//                                      userBrightnessThreshold: themeSettingsState.userBrightnessThreshold)
        case ThemeSettingsAction.enableSystemAppearance(let isEnabled):
            return ThemeSettingsState(useSystemAppearance: isEnabled,
                                      switchMode: state.switchMode,
                                      manualThemeMode: state.manualThemeMode,
                                      systemBrightnessValue: state.systemBrightnessValue,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
//        case ThemeSettingsAction.systemThemeChanged(let isEnabled):
//            return ThemeSettingsState(useSystemAppearance: isEnabled,
//                                      switchMode: state.switchMode,
//                                      manualThemeMode: state.manualThemeMode,
//                                      systemBrightnessValue: state.systemBrightnessValue,
//                                      userBrightnessThreshold: state.userBrightnessThreshold)
//        case ThemeSettingsAction.toggleSwitchMode(let switchMode):
//            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
//                                      switchMode: switchMode,
//                                      manualThemeMode: state.manualThemeMode,
//                                      systemBrightnessValue: state.systemBrightnessValue,
//                                      userBrightnessThreshold: state.userBrightnessThreshold)
//        case ThemeSettingsAction.selectManualMode(let manualMode):
//            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
//                                      switchMode: state.switchMode,
//                                      manualThemeMode: manualMode,
//                                      systemBrightnessValue: state.systemBrightnessValue,
//                                      userBrightnessThreshold: state.userBrightnessThreshold)
//        case ThemeSettingsAction.brightnessValueChanged(let systemValue):
//            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
//                                      switchMode: state.switchMode,
//                                      manualThemeMode: state.manualThemeMode,
//                                      systemBrightnessValue: systemValue,
//                                      userBrightnessThreshold: state.userBrightnessThreshold)
//        case ThemeSettingsAction.updateUserBrightnessThreshold(let userValue):
//            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
//                                      switchMode: state.switchMode,
//                                      manualThemeMode: state.manualThemeMode,
//                                      systemBrightnessValue: state.systemBrightnessValue,
//                                      userBrightnessThreshold: userValue)
            // TODO: Handle correctly
        default:
            return state
        }
    }
}
