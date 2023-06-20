// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

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

    // TODO: Ask if should use new Theming system
    init(themeManager: LegacyThemeManager) {
        self.themeManager = themeManager
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
