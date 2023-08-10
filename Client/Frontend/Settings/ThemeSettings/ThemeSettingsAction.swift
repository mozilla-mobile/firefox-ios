// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum ThemeSettingsAction: Action {
    // UI trigger actions
    case themeSettingsDidAppear
    case toggleUseSystemAppearance(Bool)
    case enableAutomaticBrightness(Bool)
    case switchManualTheme(BuiltinThemeName)
    case updateUserBrightness(Float)
    case receivedSystemBrightnessChange

    // Middleware trigger actions
    case receivedThemeManagerValues(ThemeSettingsState)
    case systemThemeChanged(Bool)
    case automaticBrightnessChanged(Bool)
    case manualThemeChanged(BuiltinThemeName)
    case userBrightnessChanged(Float)
    case systemBrightnessChanged(Float)
}
