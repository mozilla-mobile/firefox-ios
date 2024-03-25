// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol ThemeManager {
    // Current theme
    func currentTheme(for window: UUID?) -> Theme

    // System theme and brightness settings
    var systemThemeIsOn: Bool { get }
    var automaticBrightnessIsOn: Bool { get }
    var automaticBrightnessValue: Float { get }
    func systemThemeChanged()
    func setSystemTheme(isOn: Bool)
    func setAutomaticBrightness(isOn: Bool)
    func setAutomaticBrightnessValue(_ value: Float)
    func brightnessChanged()
    func getNormalSavedTheme() -> ThemeType

    // Window-specific themeing
    func changeCurrentTheme(_ newTheme: ThemeType, for window: UUID)
    func setPrivateTheme(isOn: Bool, for window: UUID)
    func reloadTheme(for window: UUID)
}
