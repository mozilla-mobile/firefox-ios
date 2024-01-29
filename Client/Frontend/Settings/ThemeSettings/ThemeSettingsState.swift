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

<<<<<<< HEAD:Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
    init(_ appState: AppState) {
        guard let themeState = store.state.screenState(ThemeSettingsState.self, for: .themeSettings) else {
            self.init()
            return
        }

        self.init(useSystemAppearance: themeState.useSystemAppearance,
                  isAutomaticBrightnessEnable: themeState.isAutomaticBrightnessEnable,
=======
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
>>>>>>> eaa0121c1 (Remove FXIOS-5064/8318/3960 [v123] LegacyThemeManager removal (#18437)):firefox-ios/Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
                  manualThemeSelected: themeState.manualThemeSelected,
                  userBrightnessThreshold: themeState.userBrightnessThreshold,
                  systemBrightness: themeState.systemBrightness)
    }

    init() {
        self.init(useSystemAppearance: false,
                  isAutomaticBrightnessEnable: false,
                  manualThemeSelected: ThemeType.light,
                  userBrightnessThreshold: 0,
                  systemBrightness: 1)
    }

    init(useSystemAppearance: Bool,
         isAutomaticBrightnessEnable: Bool,
         manualThemeSelected: ThemeType,
         userBrightnessThreshold: Float,
         systemBrightness: Float) {
        self.useSystemAppearance = useSystemAppearance
        self.isAutomaticBrightnessEnabled = isAutomaticBrightnessEnable
        self.manualThemeSelected = manualThemeSelected
        self.userBrightnessThreshold = userBrightnessThreshold
        self.systemBrightness = systemBrightness
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case ThemeSettingsAction.receivedThemeManagerValues(let themeState):
            return themeState

<<<<<<< HEAD:Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
        case ThemeSettingsAction.toggleUseSystemAppearance(let isEnabled), ThemeSettingsAction.systemThemeChanged(let isEnabled):
            return ThemeSettingsState(useSystemAppearance: isEnabled,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
=======
        case ThemeSettingsAction.toggleUseSystemAppearance(let isEnabled),
            ThemeSettingsAction.systemThemeChanged(let isEnabled):
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: isEnabled,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
>>>>>>> eaa0121c1 (Remove FXIOS-5064/8318/3960 [v123] LegacyThemeManager removal (#18437)):firefox-ios/Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.enableAutomaticBrightness(let isEnabled),
            ThemeSettingsAction.automaticBrightnessChanged(let isEnabled):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: isEnabled,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.switchManualTheme(let theme),
            ThemeSettingsAction.manualThemeChanged(let theme):
<<<<<<< HEAD:Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
=======
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
>>>>>>> eaa0121c1 (Remove FXIOS-5064/8318/3960 [v123] LegacyThemeManager removal (#18437)):firefox-ios/Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
                                      manualThemeSelected: theme,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.updateUserBrightness(let brightnessValue),
            ThemeSettingsAction.userBrightnessChanged(let brightnessValue):
<<<<<<< HEAD:Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
=======
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
>>>>>>> eaa0121c1 (Remove FXIOS-5064/8318/3960 [v123] LegacyThemeManager removal (#18437)):firefox-ios/Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: brightnessValue,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.systemBrightnessChanged(let brightnessValue):
<<<<<<< HEAD:Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
=======
            return ThemeSettingsState(windowUUID: state.windowUUID,
                                      useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
>>>>>>> eaa0121c1 (Remove FXIOS-5064/8318/3960 [v123] LegacyThemeManager removal (#18437)):firefox-ios/Client/Frontend/Settings/ThemeSettings/ThemeSettingsState.swift
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
