// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
@testable import Client

final class EcosiaMockThemeManager: ThemeManager {

    var currentTheme: Theme = EcosiaLightTheme()
    var window: UIWindow?

    func getInterfaceStyle() -> UIUserInterfaceStyle {
        currentTheme.type.getInterfaceStyle()
    }

    func changeCurrentTheme(_ newTheme: ThemeType) {
        switch newTheme {
        case .light:
            currentTheme = EcosiaLightTheme()
        case .dark:
            currentTheme = EcosiaDarkTheme()
        case .privateMode:
            currentTheme = PrivateModeTheme()
        }
    }

    func systemThemeChanged() {}

    func setSystemTheme(isOn: Bool) {}

    func setPrivateTheme(isOn: Bool) {}

    func setAutomaticBrightness(isOn: Bool) {}

    func setAutomaticBrightnessValue(_ value: Float) {
        let screenLessThanPref = Float(UIScreen.main.brightness) < value

        if screenLessThanPref, currentTheme.type == .light {
            changeCurrentTheme(.dark)
        } else if !screenLessThanPref, currentTheme.type == .dark {
            changeCurrentTheme(.light)
        }
    }
}
