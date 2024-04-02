// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct ThemeSettingsState: ScreenState, Equatable {
    var useSystemAppearance: Bool
    var isAutomaticBrightnessEnabled: Bool
    var manualThemeSelected: ThemeType
    var userBrightnessThreshold: Float
    var systemBrightness: Float
    var windowUUID: WindowUUID

    init(appState: AppState, uuid: WindowUUID) {
        guard let themeState = store.state.screenState(
            ThemeSettingsState.self,
            for: .themeSettings,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: themeState.windowUUID,
                  useSystemAppearance: themeState.useSystemAppearance,
                  isAutomaticBrightnessEnable: themeState.isAutomaticBrightnessEnabled,
                  manualThemeSelected: themeState.manualThemeSelected,
                  userBrightnessThreshold: themeState.userBrightnessThreshold,
                  systemBrightness: themeState.systemBrightness)
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  useSystemAppearance: false,
                  isAutomaticBrightnessEnable: false,
                  manualThemeSelected: ThemeType.light,
                  userBrightnessThreshold: 0,
                  systemBrightness: 1)
    }

    init(windowUUID: WindowUUID,
         useSystemAppearance: Bool,
         isAutomaticBrightnessEnable: Bool,
         manualThemeSelected: ThemeType,
         userBrightnessThreshold: Float,
         systemBrightness: Float) {
        self.windowUUID = windowUUID
        self.useSystemAppearance = useSystemAppearance
        self.isAutomaticBrightnessEnabled = isAutomaticBrightnessEnable
        self.manualThemeSelected = manualThemeSelected
        self.userBrightnessThreshold = userBrightnessThreshold
        self.systemBrightness = systemBrightness
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action {
        case ThemeSettingsAction.receivedThemeManagerValues(let themeState):
            let state = themeState.state
            return state

        case ThemeSettingsAction.toggleUseSystemAppearance(let context),
            ThemeSettingsAction.systemThemeChanged(let context):
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: context.boolValue,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.enableAutomaticBrightness(let context),
            ThemeSettingsAction.automaticBrightnessChanged(let context):
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: context.boolValue,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.switchManualTheme(let context),
            ThemeSettingsAction.manualThemeChanged(let context):
            let theme = context.themeType
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                      manualThemeSelected: theme,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.updateUserBrightness(let context),
            ThemeSettingsAction.userBrightnessChanged(let context):
            let brightnessValue = context.floatValue
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: brightnessValue,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.systemBrightnessChanged(let context):
            let brightnessValue = context.floatValue
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: brightnessValue)
        default:
            return state
        }
    }

    static func == (lhs: ThemeSettingsState, rhs: ThemeSettingsState) -> Bool {
        return lhs.useSystemAppearance == rhs.useSystemAppearance
        && lhs.isAutomaticBrightnessEnabled == rhs.isAutomaticBrightnessEnabled
        && lhs.manualThemeSelected == rhs.manualThemeSelected
        && lhs.userBrightnessThreshold == rhs.userBrightnessThreshold
    }
}
