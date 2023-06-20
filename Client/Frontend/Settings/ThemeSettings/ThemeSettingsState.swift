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
    var systemBrightnessValue: Float
    var userBrightnessThreshold: Float

    static let reducer: Reducer<Self> = { state, action in
        guard let action = action as? ThemeSettingsAction else { return state }

        switch action {
        case .enableSystemAppearance(let isEnabled):
            return ThemeSettingsState(useSystemAppearance: isEnabled,
                                      switchMode: state.switchMode,
                                      systemBrightnessValue: state.systemBrightnessValue,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
        case .toggleSwitchMode(let switchMode):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      switchMode: switchMode,
                                      systemBrightnessValue: state.systemBrightnessValue,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
        case .brightnessValueChanged(let systemValue):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      switchMode: state.switchMode,
                                      systemBrightnessValue: systemValue,
                                      userBrightnessThreshold: state.userBrightnessThreshold)
        case .updateUserBrightnessThreshold(let userValue):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      switchMode: state.switchMode,
                                      systemBrightnessValue: state.systemBrightnessValue,
                                      userBrightnessThreshold: userValue)
        }
    }
}
