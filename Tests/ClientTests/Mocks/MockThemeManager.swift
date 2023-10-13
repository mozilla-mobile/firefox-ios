// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

class MockThemeManager: ThemeManager {
    var currentTheme: Theme = LightTheme()
    var window: UIWindow?

    func getInterfaceStyle() -> UIUserInterfaceStyle {
        return .light
    }

    func getStatusBarStyle() -> UIStatusBarStyle {
        .default
    }
    
    func changeCurrentTheme(_ newTheme: ThemeType) {
        switch newTheme {
        case .light:
            currentTheme = LightTheme()
        case .dark:
            currentTheme = DarkTheme()
        }
    }

    func systemThemeChanged() {}

    func isSystemThemeOn() -> Bool { true }
    
    func setSystemTheme(isOn: Bool) {}

    func isAutomaticBrightnessOn() -> Bool { false }
    
    func updateThemeBasedOnBrightness() { }
    
    func setAutomaticBrightness(isOn: Bool) {}

    func getAutomaticBrightnessValue() -> Float { return 1 }
    
    func setAutomaticBrightnessValue(_ value: Float) {
        let screenLessThanPref = Float(UIScreen.main.brightness) < value

        if screenLessThanPref, currentTheme.type == .light {
            changeCurrentTheme(.dark)
        } else if !screenLessThanPref, currentTheme.type == .dark {
            changeCurrentTheme(.light)
        }
    }
}
