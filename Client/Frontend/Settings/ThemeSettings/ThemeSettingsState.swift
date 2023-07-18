// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

enum SwitchMode: Equatable {
    case manual(ThemeType)
    case automatic
}

struct ThemeSettingsState: Equatable {
    var useSystemAppearance: Bool
    var switchMode: SwitchMode
    var systemBrightnessValue: Float
    var userBrightnessThreshold: Float

    init(_ appState: AppState) {
        print("screens \(store.state.activeScreens.screens)")
//        guard let themeState = appState.screenState(for: .themeSettings) as? ThemeSettingsState else {
//            self.init()
//            return
//        }
        let themeState: ThemeSettingsState = store.state.screenState(for: .themeSettings) as! ThemeSettingsState

//        self.useSystemAppearance = false
//        self.switchMode = .manual(ThemeType.light)
//        self.systemBrightnessValue =  1
//        self.userBrightnessThreshold = 0.1
        self.init()
    }

    init() {
        self.useSystemAppearance = false
        self.switchMode = .manual(ThemeType.light)
        self.systemBrightnessValue =  1
        self.userBrightnessThreshold = 0.1
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
        case ThemeSettingsAction.systemThemeChanged(let isEnabled):
            return ThemeSettingsState(useSystemAppearance: isEnabled,
                                      switchMode: state.switchMode,
                                      systemBrightnessValue: state.systemBrightnessValue,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
        case ThemeSettingsAction.receivedThemeManagerValues(let themeState):
            return themeState
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
        default:
            return state
        }
    }
}
