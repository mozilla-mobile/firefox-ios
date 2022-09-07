// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

/// The `Themable` protocol gives access to the `ThemeManager` singleton
/// through the `themeManager` variable, while using dependency injection.
protocol Themeable { }

extension Themeable {
    //var themeSystem: ThemeManager { return ThemeManager.shared }
}

enum ThemeType: String {
    case normal
    case dark

//    func getTheme() {
//        switch self {
//        case .normal:
//            return
//        }
//    }
}

protocol ThemeManager {
    var currentTheme: Theme { get }
}

/// The `ThemeManager` will be responsible for providing the theme throughout the app
final class DefaultThemeManager: ThemeManager {

    private enum ThemeKeys: String {
        case themeName = "prefKeyThemeName"
        case automaticBrightness = "prefKeyAutomaticSliderValue"
        case systemThemeIsOn = "prefKeySystemThemeSwitchOnOff"
        case automaticSwitchIsOn = "prefKeyAutomaticSwitchOnOff"
    }

    // MARK: Singleton
    static let shared = DefaultThemeManager()

    // MARK: - Variables
    var currentTheme: Theme = FxDefaultTheme()
//    private var userDefaults: UserDefaults


//    private init() {
//        let themeDescription = userDefaults.string(forKey: ThemeKeys.themeName)
//
//    }

    /// The theme key of the current set theme. If no custom theme is set, then
    /// this will return the `defaultThemeKey`
//    private var themeKey: String {
//        if let key = profile.prefs.stringForKey(PrefsKeys.ThemeManagerCustomizationKey) { return key }
//        return defaultThemeKey
//    }

    private let defaultThemeKey = "FxDefaultThemeThemeManagerKey"

//    /// The current theme set in the application.
//    public var currentTheme: Theme {
//        guard let customThemeKey = profile.prefs.stringForKey(themeKey),
//              let customTheme = getTheme(from: customThemeKey)
//        else { return FxDefaultTheme() }
//
//        return customTheme
//    }

    // MARK: - Public methods


    // MARK: - Private methods

}
