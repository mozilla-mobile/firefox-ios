// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

class MockThemeManager: ThemeManager {
    private var currentThemeStorage: Theme = LightTheme()

    func currentTheme(for window: UUID?) -> Theme {
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

    func changeCurrentTheme(_ newTheme: ThemeType, for window: UUID) {
        switch newTheme {
        case .light:
            currentThemeStorage = LightTheme()
        case .dark:
            currentThemeStorage = DarkTheme()
        case .privateMode:
            currentThemeStorage = PrivateModeTheme()
        }
    }

    func systemThemeChanged() {}

    func setSystemTheme(isOn: Bool) {
        systemThemeIsOn = isOn
    }

    func setPrivateTheme(isOn: Bool, for window: UUID) {}

    func getPrivateThemeIsOn(for window: UUID) -> Bool { return false }

    func setAutomaticBrightness(isOn: Bool) {}

    func setAutomaticBrightnessValue(_ value: Float) {
        let screenLessThanPref = Float(UIScreen.main.brightness) < value

        if screenLessThanPref, currentTheme(for: windowUUID).type == .light {
            changeCurrentTheme(.dark, for: windowUUID)
        } else if !screenLessThanPref, currentTheme(for: windowUUID).type == .dark {
            changeCurrentTheme(.light, for: windowUUID)
        }
    }

    func brightnessChanged() { }

    func getNormalSavedTheme() -> ThemeType { return currentThemeStorage.type }

    func reloadTheme(for window: UUID) { }

    func setWindow(_ window: UIWindow, for uuid: UUID) { }

    func windowDidClose(uuid: UUID) { }

    func windowNonspecificTheme() -> Theme { return currentThemeStorage }
}
