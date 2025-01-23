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
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
         let action = action as? ThemeSettingsMiddlewareAction else { return defaultState(from: state) }

        switch action.actionType {
        case ThemeSettingsMiddlewareActionType.receivedThemeManagerValues:
            return action.themeSettingsState ?? defaultState(from: state)

        case ThemeSettingsMiddlewareActionType.systemThemeChanged:
            return handleSystemThemeChangedAction(state: state, action: action)

        case ThemeSettingsMiddlewareActionType.automaticBrightnessChanged:
            return handleAutomaticBrightnessChangedAction(state: state, action: action)

        case ThemeSettingsMiddlewareActionType.manualThemeChanged:
            return handleManualThemeChangedAction(state: state, action: action)

        case ThemeSettingsMiddlewareActionType.userBrightnessChanged:
            return handleUserBrightnessChangedAction(state: state, action: action)

        case ThemeSettingsMiddlewareActionType.systemBrightnessChanged:
            return handleSystemBrightnessChangedAction(state: state, action: action)
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: ThemeSettingsState) -> ThemeSettingsState {
        return ThemeSettingsState(windowUUID: state.windowUUID,
                                  useSystemAppearance: state.useSystemAppearance,
                                  isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                  manualThemeSelected: state.manualThemeSelected,
                                  userBrightnessThreshold: state.userBrightnessThreshold,
                                  systemBrightness: state.systemBrightness)
    }

    private static func handleSystemThemeChangedAction(state: Self, action: ThemeSettingsMiddlewareAction) -> Self {
        let useSystemAppearance = action.themeSettingsState?.useSystemAppearance ?? state.useSystemAppearance
        return ThemeSettingsState(windowUUID: state.windowUUID,
                                  useSystemAppearance: useSystemAppearance,
                                  isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                  manualThemeSelected: state.manualThemeSelected,
                                  userBrightnessThreshold: state.userBrightnessThreshold,
                                  systemBrightness: state.systemBrightness)
    }

    private static func handleAutomaticBrightnessChangedAction(state: Self, action: ThemeSettingsMiddlewareAction) -> Self {
        let enabled = action.themeSettingsState?.isAutomaticBrightnessEnabled ?? state.isAutomaticBrightnessEnabled
        return ThemeSettingsState(windowUUID: state.windowUUID,
                                  useSystemAppearance: state.useSystemAppearance,
                                  isAutomaticBrightnessEnable: enabled,
                                  manualThemeSelected: state.manualThemeSelected,
                                  userBrightnessThreshold: state.userBrightnessThreshold,
                                  systemBrightness: state.systemBrightness)
    }

    private static func handleManualThemeChangedAction(state: Self, action: ThemeSettingsMiddlewareAction) -> Self {
        let theme = action.themeSettingsState?.manualThemeSelected ?? state.manualThemeSelected
        return ThemeSettingsState(windowUUID: state.windowUUID,
                                  useSystemAppearance: state.useSystemAppearance,
                                  isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                  manualThemeSelected: theme,
                                  userBrightnessThreshold: state.userBrightnessThreshold,
                                  systemBrightness: state.systemBrightness)
    }

    private static func handleUserBrightnessChangedAction(state: Self, action: ThemeSettingsMiddlewareAction) -> Self {
        let brightnessValue = action.themeSettingsState?.userBrightnessThreshold ?? state.userBrightnessThreshold
        return ThemeSettingsState(windowUUID: state.windowUUID,
                                  useSystemAppearance: state.useSystemAppearance,
                                  isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                  manualThemeSelected: state.manualThemeSelected,
                                  userBrightnessThreshold: brightnessValue,
                                  systemBrightness: state.systemBrightness)
    }

    private static func handleSystemBrightnessChangedAction(state: Self, action: ThemeSettingsMiddlewareAction) -> Self {
        let brightnessValue = action.themeSettingsState?.systemBrightness ?? state.systemBrightness
        return ThemeSettingsState(windowUUID: state.windowUUID,
                                  useSystemAppearance: state.useSystemAppearance,
                                  isAutomaticBrightnessEnable: state.isAutomaticBrightnessEnabled,
                                  manualThemeSelected: state.manualThemeSelected,
                                  userBrightnessThreshold: state.userBrightnessThreshold,
                                  systemBrightness: brightnessValue)
    }

    static func == (lhs: ThemeSettingsState, rhs: ThemeSettingsState) -> Bool {
        return lhs.useSystemAppearance == rhs.useSystemAppearance
        && lhs.isAutomaticBrightnessEnabled == rhs.isAutomaticBrightnessEnabled
        && lhs.manualThemeSelected == rhs.manualThemeSelected
        && lhs.userBrightnessThreshold == rhs.userBrightnessThreshold
    }
}
