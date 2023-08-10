// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ThemeManagerProvider {
    func getCurrentThemeManagerState() -> ThemeSettingsState
    func toggleUseSystemAppearance(_ enabled: Bool)
    func toggleAutomaticBrightness(_ enabled: Bool)
    func updateManualTheme(_ theme: BuiltinThemeName)
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
            DispatchQueue.main.async {
                store.dispatch(ThemeSettingsAction.receivedThemeManagerValues(currentThemeState))
            }
        case ThemeSettingsAction.toggleUseSystemAppearance(let enabled):
            DispatchQueue.main.async {
                self.toggleUseSystemAppearance(enabled)
                store.dispatch(ThemeSettingsAction.systemThemeChanged(self.legacyThemeManager.systemThemeIsOn))
            }
        case ThemeSettingsAction.enableAutomaticBrightness(let enabled):
            DispatchQueue.main.async {
                self.toggleAutomaticBrightness(enabled)
                store.dispatch(ThemeSettingsAction.automaticBrightnessChanged(self.legacyThemeManager.automaticBrightnessIsOn))
            }
        case ThemeSettingsAction.switchManualTheme(let theme):
            DispatchQueue.main.async {
                self.updateManualTheme(theme)
                store.dispatch(ThemeSettingsAction.manualThemeChanged(theme))
            }
        case ThemeSettingsAction.updateUserBrightness(let value):
            DispatchQueue.main.async {
                self.updateUserBrightness(value)
                store.dispatch(ThemeSettingsAction.userBrightnessChanged(value))
            }
        case ThemeSettingsAction.receivedSystemBrightnessChange:
            DispatchQueue.main.async {
                self.updateThemeBasedOnSystemBrightness()
                let systemBrightness = self.getScreenBrightness()
                store.dispatch(ThemeSettingsAction.systemBrightnessChanged(systemBrightness))
            }
        default:
            break
        }
    }

    func getCurrentThemeManagerState() -> ThemeSettingsState {
        ThemeSettingsState(useSystemAppearance: legacyThemeManager.systemThemeIsOn,
                           isAutomaticBrightnessEnable: legacyThemeManager.automaticBrightnessIsOn,
                           manualThemeSelected: legacyThemeManager.currentName,
                           userBrightnessThreshold: legacyThemeManager.automaticBrightnessValue,
                           systemBrightness: getScreenBrightness())
    }

    func toggleUseSystemAppearance(_ enabled: Bool) {
        legacyThemeManager.systemThemeIsOn = enabled
        themeManager.setSystemTheme(isOn: enabled)
    }

    func toggleAutomaticBrightness(_ enabled: Bool) {
        legacyThemeManager.automaticBrightnessIsOn = enabled
        themeManager.setAutomaticBrightness(isOn: enabled)
    }

    func updateManualTheme(_ theme: BuiltinThemeName) {
        let isLightTheme = theme == .normal
        legacyThemeManager.current = isLightTheme ? LegacyNormalTheme() : LegacyDarkTheme()
        themeManager.changeCurrentTheme(isLightTheme ? .light : .dark)
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
