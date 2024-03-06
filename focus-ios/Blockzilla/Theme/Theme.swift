/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ThemeManager {

    enum Theme: Int {

        case device
        case light
        case dark

        var userInterfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .device:
                return .unspecified
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
        var telemetryValue: String {
            switch self {
            case .device:
                return "Follow device"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            }
        }
    }

    @Published public var selectedTheme: UIUserInterfaceStyle = UserDefaults.standard.theme.userInterfaceStyle

    public func set(_ theme: ThemeManager.Theme) {
        UserDefaults.standard.theme = theme
        selectedTheme = theme.userInterfaceStyle
    }
}

extension UserDefaults {
    var theme: ThemeManager.Theme {
        get {
            register(defaults: [#function: ThemeManager.Theme.device.rawValue])
            return ThemeManager.Theme(rawValue: integer(forKey: #function)) ?? .device
        }
        set {
            set(newValue.rawValue, forKey: #function)
        }
    }
}
