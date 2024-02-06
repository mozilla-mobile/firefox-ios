// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol ThemeManager {
    var currentTheme: Theme { get }
    var window: UIWindow? { get set }

    var systemThemeIsOn: Bool { get }
    var automaticBrightnessIsOn: Bool { get }
    var automaticBrightnessValue: Float { get }

    func changeCurrentTheme(_ newTheme: ThemeType)
    func systemThemeChanged()
    func setSystemTheme(isOn: Bool)
    func setPrivateTheme(isOn: Bool)
    func setAutomaticBrightness(isOn: Bool)
    func setAutomaticBrightnessValue(_ value: Float)
    func brightnessChanged()
    func getNormalSavedTheme() -> ThemeType
}
