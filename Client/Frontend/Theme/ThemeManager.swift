// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

/// The `Themable` protocol gives access to the `ThemeManager` singleton
/// through the `themeManager` variable, while using dependency injection.
protocol Themeable { }

extension Themeable {
    var themeSystem: ThemeManager { return ThemeManager.shared }
}

/// The `ThemeManager` will be responsible for providing the theme throughout the app
///
/// IMPORTANT NOTE:
/// The current functionality of `ThemeManager` is restricted to providing the default
/// theme. The rest of the functionality, is a sketching out of how implementing user
/// defined themes might work. It's a work in progress and needs not be touched until
/// such a feature is actually added.
final class ThemeManager {

    // MARK: Singleton
    static let shared = ThemeManager()

    // MARK: - Variables
    private var profile: Profile!

    /// The theme key of the current set theme. If no custom theme is set, then
    /// this will return the `defaultThemeKey`
    private var themeKey: String {
        if let key = profile.prefs.stringForKey(PrefsKeys.ThemeManagerCustomizationKey) { return key }
        return defaultThemeKey
    }

    private let defaultThemeKey = "FxDefaultThemeThemeManagerKey"

    /// The current theme set in the application.
    ///
    /// Currently, the `currentTheme` simply returns the default Firefox theme.
    /// However, in the future, this is expandable to allow custom themes to
    /// be set by the user.
    public var currentTheme: Theme {
        guard let customThemeKey = profile.prefs.stringForKey(themeKey),
              let customTheme = getTheme(from: customThemeKey)
        else { return FxDefaultTheme() }

        return customTheme
    }

    // MARK: - Public methods

    /// This is `ThemeManager`s initializer, essentially, as we require the profile
    /// to save custom themes to disk.
    ///
    /// This should only be called in AppDelegate.
    public func updateProfile(with profile: Profile) {
        self.profile = profile
    }

    // IMPORTANT NOTE:
    // The methods below are not finished. They are sketches for how updating themes
    // might work, should that feature be added.

//    public func updateTheme(named name: String, with customTheme: CustomTheme) {
//        let keyName = "UserCustomThemeNamed\(name)"
//
//        do {
//            let jsonData = try JSONEncoder().encode(customTheme)
//            let jsonString = String(data: jsonData, encoding: .utf8)!
//            profile.prefs.setString(jsonString, forKey: keyName)
//
//        } catch {
//            print("Something's gone wrong saving a custom theme.")
//        }
//    }

    // MARK: - Private methods

    /// Retrieves a `Theme` saved by the user, or, if none exists, the default theme.
    private func getTheme(from theme: String) -> Theme? {
        if themeKey != defaultThemeKey,
           let customThemeData = profile.prefs.stringForKey(themeKey) {

            let jsonData = Data(customThemeData.utf8)

            do {
                let decodedTheme = try JSONDecoder().decode(CustomTheme.self, from: jsonData)
                return verify(customTheme: decodedTheme)

            } catch {
                print("Something's gone wrong decoding a custom theme.")
            }
        }

        return nil
    }

    /// The verify function will return a true `Theme` object, as the `CustomTheme`
    /// might not have all values specified. Because the initial implementation of
    /// `ThemeManager` is a rough outline of how things might work for custom themes
    /// in the future, this empty function is merely serving as a placeholder.
    private func verify(customTheme: CustomTheme) -> Theme? {

        return nil
    }
}
