// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

final class ThemeableMockThemeManager: ThemeManager {
    var currentTheme: Theme = LightTheme()
    var themeChangeHandler: ((Theme) -> Void)?

    func getCurrentTheme(for window: WindowUUID?) -> Theme {
        return currentTheme
    }

    func setCurrentTheme(_ theme: Theme) {
        currentTheme = theme
        themeChangeHandler?(theme)
    }

    var systemThemeIsOn: Bool = false
    var automaticBrightnessIsOn: Bool = false
    var automaticBrightnessValue: Float = 0.5

    func setSystemTheme(isOn: Bool) {}
    func setManualTheme(to newTheme: ThemeType) {}
    func getUserManualTheme() -> ThemeType { return .light }
    func setAutomaticBrightness(isOn: Bool) {}
    func setAutomaticBrightnessValue(_ value: Float) {}
    func applyThemeUpdatesToWindows() {}
    func setPrivateTheme(isOn: Bool, for window: WindowUUID) {}
    func getPrivateThemeIsOn(for window: WindowUUID) -> Bool { return false }
    func setWindow(_ window: UIWindow, for uuid: WindowUUID) {}
    func windowDidClose(uuid: WindowUUID) {}
    func windowNonspecificTheme() -> Theme { return currentTheme }
}
