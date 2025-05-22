// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// A helper for reading user preference values from a profile-based `UserDefaults` store
/// without requiring access to the `Profile` object.
///
/// This is useful in contexts where only the app group suite is available (e.g., startup code,
/// experiments), and certain known preference keys need to be queried.
struct ProfilePrefsReader {
    /// Prefix used to simulate the `NSUserDefaultsPrefs` profile key namespace.
    static let prefix = "profile."
    private let userDefaults: UserDefaultsInterface

    init(userDefaults: UserDefaultsInterface? = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)) {
        guard let userDefaults = userDefaults else {
            fatalError("Failed to create UserDefaults with suite: \(AppInfo.sharedContainerIdentifier)")
        }
        self.userDefaults = userDefaults
    }

    /// Returns `true` if the saved search bar position for the user is `.bottom`.
    ///
    /// This checks the `SearchBarPositionUsersPrefsKey` and deserializes it into
    /// a `SearchBarPosition` enum. If the key is missing or not `SearchBarPosition.bottom`, it returns `false`.
    func isBottomToolbarUser() -> Bool {
        let key = ProfilePrefsReader.prefix + PrefsKeys.FeatureFlags.SearchBarPosition
        if let rawValue = userDefaults.string(forKey: key),
           let position = SearchBarPosition(rawValue: rawValue) {
            return position == .bottom
        }

        return false
    }

    /// Returns `true` if the user has enabled tips and feature notifications.
    ///
    /// This checks a boolean flag stored under `TipsAndFeaturesNotifications`.
    /// If the key is missing, the result is `false`.
    func hasEnabledTipsNotifications() -> Bool {
        let key = ProfilePrefsReader.prefix + PrefsKeys.Notifications.TipsAndFeaturesNotifications
        return userDefaults.bool(forKey: key)
    }
}
