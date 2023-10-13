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
    var themeManager: ThemeManager

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
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
                store.dispatch(ThemeSettingsAction.systemThemeChanged(self.themeManager.isSystemThemeOn()))
            }
        case ThemeSettingsAction.enableAutomaticBrightness(let enabled):
            DispatchQueue.main.async {
                self.toggleAutomaticBrightness(enabled)
                store.dispatch(ThemeSettingsAction.automaticBrightnessChanged(self.themeManager.isAutomaticBrightnessOn()))
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

    // MARK: - Helper func
    func getCurrentThemeManagerState() -> ThemeSettingsState {
        ThemeSettingsState(useSystemAppearance: themeManager.isSystemThemeOn(),
                           isAutomaticBrightnessEnable: themeManager.isAutomaticBrightnessOn(),
                           manualThemeSelected: themeManager.currentTheme.type,
                           userBrightnessThreshold: themeManager.getAutomaticBrightnessValue(),
                           systemBrightness: getScreenBrightness())
    }

    func toggleUseSystemAppearance(_ enabled: Bool) {
        themeManager.setSystemTheme(isOn: enabled)
    }

    func toggleAutomaticBrightness(_ enabled: Bool) {
        themeManager.setAutomaticBrightness(isOn: enabled)
    }

    func updateManualTheme(_ theme: ThemeType) {
        let isLightTheme = theme == .light
        themeManager.changeCurrentTheme(isLightTheme ? .light : .dark)
    }

    func updateUserBrightness(_ value: Float) {
        themeManager.setAutomaticBrightnessValue(value)
    }

    func updateThemeBasedOnSystemBrightness() {
        themeManager.updateThemeBasedOnBrightness()
    }

    func getScreenBrightness() -> Float {
        return Float(UIScreen.main.brightness)
    }
}
