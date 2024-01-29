// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ThemeManagerProvider {
    func getCurrentThemeManagerState() -> ThemeSettingsState
    func toggleUseSystemAppearance(_ enabled: Bool)
    func toggleAutomaticBrightness(_ enabled: Bool)
    func updateManualTheme(_ theme: ThemeType)
    func updateUserBrightness(_ value: Float)
}

class ThemeManagerMiddleware: ThemeManagerProvider {
    var legacyThemeManager: LegacyThemeManager
    var themeManager: ThemeManager

    init(legacyThemeManager: LegacyThemeManager = LegacyThemeManager.instance,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.legacyThemeManager = legacyThemeManager
        self.themeManager = themeManager
    }

    lazy var themeManagerProvider: Middleware<AppState> = { state, action in
        switch action {
        case ThemeSettingsAction.themeSettingsDidAppear:
            let currentThemeState = self.getCurrentThemeManagerState()
            store.dispatch(ThemeSettingsAction.receivedThemeManagerValues(currentThemeState))
        case ThemeSettingsAction.toggleUseSystemAppearance(let enabled):
            self.toggleUseSystemAppearance(enabled)
            store.dispatch(ThemeSettingsAction.systemThemeChanged(self.themeManager.systemThemeIsOn))
        case ThemeSettingsAction.enableAutomaticBrightness(let enabled):
            self.toggleAutomaticBrightness(enabled)
            store.dispatch(
                ThemeSettingsAction.automaticBrightnessChanged(self.legacyThemeManager.automaticBrightnessIsOn)
            )
        case ThemeSettingsAction.switchManualTheme(let theme):
            self.updateManualTheme(theme)
            store.dispatch(ThemeSettingsAction.manualThemeChanged(theme))
        case ThemeSettingsAction.updateUserBrightness(let value):
            self.updateUserBrightness(value)
            store.dispatch(ThemeSettingsAction.userBrightnessChanged(value))
        case ThemeSettingsAction.receivedSystemBrightnessChange:
            self.updateThemeBasedOnSystemBrightness()
            let systemBrightness = self.getScreenBrightness()
            store.dispatch(ThemeSettingsAction.systemBrightnessChanged(systemBrightness))
        case PrivateModeMiddlewareAction.privateModeUpdated(let newState):
            self.toggleUsePrivateTheme(to: newState)
        default:
            break
        }
    }

    // MARK: - Helper func
    func getCurrentThemeManagerState() -> ThemeSettingsState {
        ThemeSettingsState(useSystemAppearance: themeManager.systemThemeIsOn,
                           isAutomaticBrightnessEnable: legacyThemeManager.automaticBrightnessIsOn,
                           manualThemeSelected: themeManager.currentTheme.type,
                           userBrightnessThreshold: legacyThemeManager.automaticBrightnessValue,
                           systemBrightness: getScreenBrightness())
    }

    func toggleUseSystemAppearance(_ enabled: Bool) {
        themeManager.setSystemTheme(isOn: enabled)
    }

    func toggleUsePrivateTheme(to state: Bool) {
        themeManager.setPrivateTheme(isOn: state)
    }

    func toggleAutomaticBrightness(_ enabled: Bool) {
        legacyThemeManager.automaticBrightnessIsOn = enabled
        themeManager.setAutomaticBrightness(isOn: enabled)
    }

    func updateManualTheme(_ newTheme: ThemeType) {
        let isLightTheme = newTheme == .light
        legacyThemeManager.current = isLightTheme ? LegacyNormalTheme() : LegacyDarkTheme()
        themeManager.changeCurrentTheme(newTheme)
    }

    func updateUserBrightness(_ value: Float) {
        themeManager.setAutomaticBrightnessValue(value)
        legacyThemeManager.automaticBrightnessValue = value
    }

    func updateThemeBasedOnSystemBrightness() {
        legacyThemeManager.updateCurrentThemeBasedOnScreenBrightness()
    }

    func getScreenBrightness() -> Float {
        return Float(UIScreen.main.brightness)
    }
}
