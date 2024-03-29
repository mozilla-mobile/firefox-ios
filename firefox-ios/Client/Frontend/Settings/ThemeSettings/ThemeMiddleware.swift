// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ThemeManagerProvider {
    func getCurrentThemeManagerState(windowUUID: WindowUUID) -> ThemeSettingsState
    func toggleUseSystemAppearance(_ enabled: Bool)
    func toggleAutomaticBrightness(_ enabled: Bool)
    func updateManualTheme(_ theme: ThemeType, for window: WindowUUID)
    func updateUserBrightness(_ value: Float)
}

class ThemeManagerMiddleware: ThemeManagerProvider {
    var themeManager: ThemeManager

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
    }

    lazy var themeManagerProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action {
        case ThemeSettingsAction.themeSettingsDidAppear:
            let currentThemeState = self.getCurrentThemeManagerState(windowUUID: action.windowUUID)
            let context = ThemeSettingsStateContext(state: currentThemeState, windowUUID: windowUUID)
            store.dispatch(ThemeSettingsAction.receivedThemeManagerValues(context))
        case ThemeSettingsAction.toggleUseSystemAppearance(let context):
            let enabled = context.boolValue
            self.toggleUseSystemAppearance(enabled)
            let context = BoolValueContext(boolValue: self.themeManager.systemThemeIsOn, windowUUID: windowUUID)
            store.dispatch(ThemeSettingsAction.systemThemeChanged(context))
        case ThemeSettingsAction.enableAutomaticBrightness(let context):
            let enabled = context.boolValue
            self.toggleAutomaticBrightness(enabled)
            store.dispatch(
                ThemeSettingsAction.automaticBrightnessChanged(
                    BoolValueContext(boolValue: self.themeManager.automaticBrightnessIsOn, windowUUID: windowUUID)
                )
            )
        case ThemeSettingsAction.switchManualTheme(let context):
            let theme = context.themeType
            self.updateManualTheme(theme, for: windowUUID)
            store.dispatch(ThemeSettingsAction.manualThemeChanged(context))
        case ThemeSettingsAction.updateUserBrightness(let context):
            let value = context.floatValue
            self.updateUserBrightness(value)
            store.dispatch(ThemeSettingsAction.userBrightnessChanged(context))
        case ThemeSettingsAction.receivedSystemBrightnessChange:
            self.updateThemeBasedOnSystemBrightness()
            let systemBrightness = self.getScreenBrightness()
            let context = FloatValueContext(floatValue: systemBrightness, windowUUID: windowUUID)
            store.dispatch(ThemeSettingsAction.systemBrightnessChanged(context))
        case PrivateModeMiddlewareAction.privateModeUpdated(let context):
            let newState = context.boolValue
            self.toggleUsePrivateTheme(to: newState, for: windowUUID)
        default:
            break
        }
    }

    // MARK: - Helper func
    func getCurrentThemeManagerState(windowUUID: WindowUUID) -> ThemeSettingsState {
        ThemeSettingsState(windowUUID: windowUUID,
                           useSystemAppearance: themeManager.systemThemeIsOn,
                           isAutomaticBrightnessEnable: themeManager.automaticBrightnessIsOn,
                           manualThemeSelected: themeManager.getNormalSavedTheme(),
                           userBrightnessThreshold: themeManager.automaticBrightnessValue,
                           systemBrightness: getScreenBrightness())
    }

    func toggleUseSystemAppearance(_ enabled: Bool) {
        themeManager.setSystemTheme(isOn: enabled)
    }

    func toggleUsePrivateTheme(to state: Bool, for window: WindowUUID) {
        themeManager.setPrivateTheme(isOn: state, for: window)
    }

    func toggleAutomaticBrightness(_ enabled: Bool) {
        themeManager.setAutomaticBrightness(isOn: enabled)
    }

    func updateManualTheme(_ newTheme: ThemeType, for window: UUID) {
        themeManager.changeCurrentTheme(newTheme, for: window)
    }

    func updateUserBrightness(_ value: Float) {
        themeManager.setAutomaticBrightnessValue(value)
    }

    func updateThemeBasedOnSystemBrightness() {
        themeManager.brightnessChanged()
    }

    func getScreenBrightness() -> Float {
        return Float(UIScreen.main.brightness)
    }
}
