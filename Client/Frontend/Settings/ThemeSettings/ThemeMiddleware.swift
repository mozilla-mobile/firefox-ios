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
        // TODO: Add support for LegacyThemeManager
        self.legacyThemeManager = legacyThemeManager
        self.themeManager = themeManager
    }

    lazy var setSystemTheme: Middleware<AppState> = { state, action in
        switch action {
        case ThemeSettingsAction.fetchThemeManagerValues:
            let currentThemeState = self.getThemeManagerCurrentState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                store.dispatch(ThemeSettingsAction.receivedThemeManagerValues(currentThemeState))
            }
        case ThemeSettingsAction.enableSystemAppearance(let enabled):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.toggleUseSystemAppearance(enabled)
                store.dispatch(ThemeSettingsAction.systemThemeChanged(self.legacyThemeManager.systemThemeIsOn))
            }
        default:
            break
        }
    }

    func getThemeManagerCurrentState() -> ThemeSettingsState {
        ThemeSettingsState(useSystemAppearance: legacyThemeManager.systemThemeIsOn,
                           switchMode: .manual(.dark),
                           systemBrightnessValue: 0.5,
                           userBrightnessThreshold: 0.6)
    }

    func toggleUseSystemAppearance(_ enabled: Bool) {
        legacyThemeManager.systemThemeIsOn = enabled
        themeManager.setSystemTheme(isOn: enabled)
    }
}
