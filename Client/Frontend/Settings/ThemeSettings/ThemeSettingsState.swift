// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct ThemeSettingsState: ScreenState, Equatable {
    var useSystemAppearance: Bool
    var isAutomaticBrightnessEnable: Bool
    var manualThemeSelected: BuiltinThemeName
    var userBrightnessThreshold: Float
    var systemBrightness: Float
    private var logger: Logger

    init(_ appState: AppState) {
        guard let themeState = store.state.screenState(ThemeSettingsState.self, for: .themeSettings) else {
            self.init()
            logger.log("Error retrieving screen state",
                       level: .debug,
                       category: .redux)
            return
        }

        self.init(useSystemAppearance: themeState.useSystemAppearance,
                  isAutomaticBrightnessEnable: themeState.isAutomaticBrightnessEnable,
                  manualThemeSelected: themeState.manualThemeSelected,
                  userBrightnessThreshold: themeState.userBrightnessThreshold,
                  systemBrightness: themeState.systemBrightness)
    }

    init() {
        self.init(useSystemAppearance: false,
                  isAutomaticBrightnessEnable: false,
                  manualThemeSelected: .normal,
                  userBrightnessThreshold: 0,
                  systemBrightness: 1)
    }

    init(useSystemAppearance: Bool,
         isAutomaticBrightnessEnable: Bool,
         manualThemeSelected: BuiltinThemeName,
         userBrightnessThreshold: Float,
         systemBrightness: Float,
         logger: Logger = DefaultLogger.shared) {
        self.useSystemAppearance = useSystemAppearance
        self.isAutomaticBrightnessEnable = isAutomaticBrightnessEnable
        self.manualThemeSelected = manualThemeSelected
        self.userBrightnessThreshold = userBrightnessThreshold
        self.systemBrightness = systemBrightness
        self.logger = logger
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case ThemeSettingsAction.receivedThemeManagerValues(let themeState):
            return themeState

        case ThemeSettingsAction.toggleUseSystemAppearance(let isEnabled), ThemeSettingsAction.systemThemeChanged(let isEnabled):
            return ThemeSettingsState(useSystemAppearance: isEnabled,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
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
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
                                      manualThemeSelected: theme,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.updateUserBrightness(let brightnessValue),
            ThemeSettingsAction.userBrightnessChanged(let brightnessValue):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: brightnessValue,
                                      systemBrightness: state.systemBrightness)

        case ThemeSettingsAction.systemBrightnessChanged(let brightnessValue):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: state.userBrightnessThreshold,
                                      systemBrightness: brightnessValue)
        default:
            return state
        }
    }

    static func == (lhs: ThemeSettingsState, rhs: ThemeSettingsState) -> Bool {
        return lhs.useSystemAppearance == rhs.useSystemAppearance
        && lhs.isAutomaticBrightnessEnable == rhs.isAutomaticBrightnessEnable
        && lhs.manualThemeSelected == rhs.manualThemeSelected
        && lhs.userBrightnessThreshold == rhs.userBrightnessThreshold
    }
}
