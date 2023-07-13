// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol ThemeManager {
    var currentTheme: Theme { get }
    var window: UIWindow? { get set }

    func getInterfaceStyle() -> UIUserInterfaceStyle
    func changeCurrentTheme(_ newTheme: ThemeType)
    func systemThemeChanged()
    func setSystemTheme(isOn: Bool)
    func setAutomaticBrightness(isOn: Bool)
    func setAutomaticBrightnessValue(_ value: Float)
}
