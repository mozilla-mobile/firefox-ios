// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

enum LegacyThemeManagerPrefs: String {
    case systemThemeIsOn = "prefKeySystemThemeSwitchOnOff"
    case automaticSwitchIsOn = "prefKeyAutomaticSwitchOnOff"
    case automaticSliderValue = "prefKeyAutomaticSliderValue"
    case themeName = "prefKeyThemeName"
}

class LegacyThemeManager {
    static let instance = LegacyThemeManager()

    var current: LegacyTheme = themeFrom(name: UserDefaults.standard.string(
        forKey: LegacyThemeManagerPrefs.themeName.rawValue))

    private init() {
        UserDefaults.standard.register(defaults: [LegacyThemeManagerPrefs.systemThemeIsOn.rawValue: true])
    }
}

private func themeFrom(name: String?) -> LegacyTheme {
    guard let name = name, let theme = BuiltinThemeName(rawValue: name) else { return LegacyNormalTheme() }
    switch theme {
    case .dark:
        return LegacyDarkTheme()
    default:
        return LegacyNormalTheme()
    }
}
