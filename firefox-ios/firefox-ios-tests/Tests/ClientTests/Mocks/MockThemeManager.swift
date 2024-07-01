// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

class MockThemeManager: ThemeManager {
    private var currentThemeStorage: Theme = LightTheme()

    func getCurrentTheme(for window: UUID?) -> Theme {
        return currentThemeStorage
    }

    var window: UIWindow?
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    var systemThemeIsOn = true

    var automaticBrightnessIsOn: Bool { return false}

    var automaticBrightnessValue: Float { return 0.4}

    func getInterfaceStyle() -> UIUserInterfaceStyle {
        return .light
    }

    func setManualTheme(to newTheme: ThemeType) {
        switch newTheme {
        case .light:
            currentThemeStorage = LightTheme()
        case .dark:
            currentThemeStorage = DarkTheme()
        case .nightMode:
            currentThemeStorage = NightModeTheme()
        case .privateMode:
            currentThemeStorage = PrivateModeTheme()
        }
    }

    func applyThemeUpdatesToWindows() { }

    func systemThemeChanged() {}

    func setSystemTheme(isOn: Bool) {
        systemThemeIsOn = isOn
    }

    func setPrivateTheme(isOn: Bool, for window: UUID) {}

    func getPrivateThemeIsOn(for window: UUID) -> Bool { return false }

    func setAutomaticBrightness(isOn: Bool) {}

    func setAutomaticBrightnessValue(_ value: Float) {
        let screenLessThanPref = Float(UIScreen.main.brightness) < value

        if screenLessThanPref, getCurrentTheme(for: windowUUID).type == .light {
            setManualTheme(to: .dark)
        } else if !screenLessThanPref, getCurrentTheme(for: windowUUID).type == .dark {
            setManualTheme(to: .light)
        }
    }

    func updateThemeBasedOnBrightess() { }

    func getUserManualTheme() -> ThemeType { return currentThemeStorage.type }

    func reloadTheme(for window: UUID) { }

    func setWindow(_ window: UIWindow, for uuid: UUID) { }

    func windowDidClose(uuid: UUID) { }

    func windowNonspecificTheme() -> Theme { return currentThemeStorage }
}
