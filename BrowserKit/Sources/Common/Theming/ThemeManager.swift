// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol ThemeManager {
    var currentTheme: Theme { get }
    var window: UIWindow? { get set }

    func getInterfaceStyle() -> UIUserInterfaceStyle
    func getStatusBarStyle() -> UIStatusBarStyle
    func changeCurrentTheme(_ newTheme: ThemeType)
    func systemThemeChanged()
    func isSystemThemeOn() -> Bool
    func setSystemTheme(isOn: Bool)
    func updateThemeBasedOnBrightness()
    func isAutomaticBrightnessOn() -> Bool
    func setAutomaticBrightness(isOn: Bool)
    func getAutomaticBrightnessValue() -> Float
    func setAutomaticBrightnessValue(_ value: Float)
}
