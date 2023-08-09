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
    private var logger: Logger

    var systemBrightness: Float {
        return Float(UIScreen.main.brightness)
    }

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
                  userBrightnessThreshold: themeState.userBrightnessThreshold)
    }

    init() {
        self.init(useSystemAppearance: false,
                  isAutomaticBrightnessEnable: false,
                  manualThemeSelected: .normal,
                  userBrightnessThreshold: 0)
    }

    init(useSystemAppearance: Bool,
         isAutomaticBrightnessEnable: Bool,
         manualThemeSelected: BuiltinThemeName,
         userBrightnessThreshold: Float,
         logger: Logger = DefaultLogger.shared) {
        self.useSystemAppearance = useSystemAppearance
        self.isAutomaticBrightnessEnable = isAutomaticBrightnessEnable
        self.manualThemeSelected = manualThemeSelected
        self.userBrightnessThreshold = userBrightnessThreshold
        self.logger = logger
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
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

        case ThemeSettingsAction.userBrightnessChanged(let brightnessValue):
            return ThemeSettingsState(useSystemAppearance: state.useSystemAppearance,
                                      isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnable,
                                      manualThemeSelected: state.manualThemeSelected,
                                      userBrightnessThreshold: brightnessValue)
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
