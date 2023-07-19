// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

protocol ThemeManagerProvider {
    var systemThemeIsOn: Bool { get }
}

class ThemeManagerMiddleware: ThemeManagerProvider {
    var themeManager: LegacyThemeManager

    var systemThemeIsOn: Bool {
        themeManager.systemThemeIsOn
    }

    init(themeManager: LegacyThemeManager = LegacyThemeManager.instance) {
        // TODO: Add support for LegacyThemeManager
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
                self.themeManager.systemThemeIsOn = enabled
                store.dispatch(ThemeSettingsAction.systemThemeChanged(self.themeManager.systemThemeIsOn))
            }
        default:
            break
        }
    }

    func getThemeManagerCurrentState() -> ThemeSettingsState {
        ThemeSettingsState(useSystemAppearance: themeManager.systemThemeIsOn,
                           switchMode: .manual(.dark),
                           systemBrightnessValue: 0.5,
                           userBrightnessThreshold: 0.6)
    }
}
