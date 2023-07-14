// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

protocol ThemeManagerProvider {
    var systemThemeIsOn: Bool { get }
    func setSystemTheme(isOn: Bool)
    func setAutomaticBrightness(isOn: Bool)
    func brightnessChanged(_ value: Float)
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
        case ThemeSettingsAction.enableSystemAppearance(let enabled):
            self.themeManager.systemThemeIsOn = enabled
            store.dispatch(ThemeSettingsAction.systemThemeChanged(enabled))
        default:
            break
        }
    }

    func setSystemTheme(isOn: Bool) {
        themeManager.systemThemeIsOn = isOn
    }

    func setAutomaticBrightness(isOn: Bool) {
        themeManager.automaticBrightnessIsOn = isOn
    }

    func brightnessChanged(_ value: Float) {
        themeManager.automaticBrightnessValue = value
    }
}
