// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A theme manager whose theme can be swapped mid-test, so a `Themeable` screen can be asked to
/// restyle. The Client's `MockThemeManager` isn't reachable from here.
@MainActor
final class MockThemeManager: ThemeManager {
    var currentTheme: Theme = LightTheme()

    var systemThemeIsOn = false
    var automaticBrightnessIsOn = false
    var automaticBrightnessValue: Float = 0

    func getCurrentTheme(for window: WindowUUID?) -> Theme {
        return currentTheme
    }

    func resolvedTheme(with shouldShowPrivateTheme: Bool) -> Theme {
        return currentTheme
    }

    func windowNonspecificTheme() -> Theme {
        return currentTheme
    }

    func setManualTheme(to newTheme: ThemeType) {
        currentTheme = newTheme == .dark ? DarkTheme() : LightTheme()
    }

    func getUserManualTheme() -> ThemeType {
        return currentTheme.type
    }

    func setSystemTheme(isOn: Bool) {}
    func setAutomaticBrightness(isOn: Bool) {}
    func setAutomaticBrightnessValue(_ value: Float) {}
    func applyThemeUpdatesToWindows() {}
    func setPrivateTheme(isOn: Bool, for window: WindowUUID) {}
    func getPrivateThemeIsOn(for window: WindowUUID) -> Bool { return false }
    func setWindow(_ window: UIWindow, for uuid: WindowUUID) {}
    func windowDidClose(uuid: WindowUUID) {}
}
