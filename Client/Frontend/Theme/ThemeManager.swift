// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

/// The `Themable` protocol gives access to the `ThemeManager` singleton
/// through the `themeManager` variable, while using dependency injection.
protocol Themeable { }

extension Themeable {}

enum ThemeType: String {
    case light = "normal" // This needs to match the string used in the legacy system
    case dark

    func getInterfaceStyle() -> UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

protocol ThemeManager {
    var currentTheme: Theme { get }

    func getInterfaceStyle() -> UIUserInterfaceStyle
}

/// The `ThemeManager` will be responsible for providing the theme throughout the app
final class DefaultThemeManager: ThemeManager {

    // These have been carried over from the legacy system to maintain backwards compatibility
    private enum ThemeKeys {
        static let themeName = "prefKeyThemeName"
        static let automaticBrightness = "prefKeyAutomaticSliderValue"
        static let systemThemeIsOn = "prefKeySystemThemeSwitchOnOff"
        static let automaticSwitchIsOn = "prefKeyAutomaticSwitchOnOff"
    }

    // MARK: Singleton

    static let shared = DefaultThemeManager()

    // MARK: - Variables

    var currentTheme: Theme = LightTheme()
    private var userDefaults: UserDefaults

    // MARK: - Init

    private init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        self.currentTheme = generateTheme()
    }

    // MARK: - ThemeManager

    func getInterfaceStyle() -> UIUserInterfaceStyle {
        return currentTheme.type.getInterfaceStyle()
    }

    // MARK: - Private methods

    private func generateTheme() -> Theme {
        let typeDescription = userDefaults.string(forKey: ThemeKeys.themeName) ?? ""
        let themeType = ThemeType(rawValue: typeDescription)
        switch themeType {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        default:
            return LightTheme()
        }
    }
}
