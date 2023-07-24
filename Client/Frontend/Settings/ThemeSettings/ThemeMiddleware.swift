// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ThemeManagerProvider {
    var systemThemeIsOn: Bool { get }
}

class ThemeManagerMiddleware: ThemeManagerProvider {
    var legacyThemeManager: LegacyThemeManager
    var themeManager: ThemeManager

    var systemThemeIsOn: Bool {
        legacyThemeManager.systemThemeIsOn
    }

    init(legacyThemeManager: LegacyThemeManager = LegacyThemeManager.instance,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.legacyThemeManager = legacyThemeManager
        self.themeManager = themeManager
    }

    lazy var setSystemTheme: Middleware<AppState> = { state, action in
        switch action {
        case ThemeSettingsAction.fetchThemeManagerValues:
            let currentThemeState = self.getCurrentThemeManagerState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                store.dispatch(ThemeSettingsAction.receivedThemeManagerValues(currentThemeState))
            }
        case ThemeSettingsAction.enableSystemAppearance(let enabled):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.toggleUseSystemAppearance(enabled)
                store.dispatch(ThemeSettingsAction.systemThemeChanged(self.legacyThemeManager.systemThemeIsOn))
            }
        case ThemeSettingsAction.enableAutomaticBrightness(let enabled):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.toggleAutomaticBrightness(enabled)
                store.dispatch(ThemeSettingsAction.automaticBrightnessChanged(self.legacyThemeManager.automaticBrightnessIsOn))
            }
        case ThemeSettingsAction.switchManualTheme(let theme):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateManualTheme(theme)
                store.dispatch(ThemeSettingsAction.manualThemeChanged(theme))
            }
        case ThemeSettingsAction.updateUserBrightness(let value):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateUserBrightness(value)
                store.dispatch(ThemeSettingsAction.userBrightnessChanged(value))
            }
        default:
            break
        }
    }

    func getCurrentThemeManagerState() -> ThemeSettingsState {
        ThemeSettingsState(useSystemAppearance: legacyThemeManager.systemThemeIsOn,
                           isAutomaticBrightnessEnable: legacyThemeManager.automaticBrightnessIsOn,
                           manualThemeSelected: legacyThemeManager.currentName,
                           userBrightnessThreshold: legacyThemeManager.automaticBrightnessValue)
    }

    func toggleUseSystemAppearance(_ enabled: Bool) {
        legacyThemeManager.systemThemeIsOn = enabled
        themeManager.setSystemTheme(isOn: enabled)
    }

    func toggleAutomaticBrightness(_ enabled: Bool) {
        self.legacyThemeManager.automaticBrightnessIsOn = enabled
        self.themeManager.setAutomaticBrightness(isOn: enabled)
    }

    func updateManualTheme(_ theme: BuiltinThemeName) {
        let isLightTheme = theme == .normal
        LegacyThemeManager.instance.current = isLightTheme ? LegacyNormalTheme() : LegacyDarkTheme()
        themeManager.changeCurrentTheme(isLightTheme ? .light : .dark)
    }

    func updateUserBrightness(_ value: Float) {
        themeManager.setAutomaticBrightnessValue(value)
        LegacyThemeManager.instance.automaticBrightnessValue = value
    }
}
