// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

/// Extension handling previous version retrieval and saving current version.
extension Version {
    
    /// Save the specified app version to `UserDefaults`.
    ///
    /// This method takes a `Version` object and saves its description to `UserDefaults`
    /// using a parametrized key.
    ///
    /// - Parameters:
    ///   - key: The `String` representing the value by which we would like to store our version.
    ///   - prefs: The `UserDefaults` instance to use for saving the version.
    ///            Defaults to `UserDefaults.standard`.
    static func saved(forKey key: String, using prefs: UserDefaults = UserDefaults.standard) -> Version? {
        guard let savedKey = prefs.string(forKey: key) else { return nil }
        return Version(savedKey)
    }
    
    /// Update the specified app version to `UserDefaults`.
    ///
    /// This method takes a `String` key to utilize to its `UserDefaults`
    ///
    /// - Parameters:
    ///   - key: The `String` representing the value by which we would like to store our version.
    ///   - provider: The `AppVersionInfoProvider` serving the `version` `String`.
    ///               Defaults to `DefaultAppVersionInfoProvider`.
    ///   - prefs: The `UserDefaults` instance to use for saving the version.
    ///            Defaults to `UserDefaults.standard`.
    static func updateFromCurrent(forKey key: String,
                                  provider: AppVersionInfoProvider = DefaultAppVersionInfoProvider(),
                                  using prefs: UserDefaults = UserDefaults.standard) {
        prefs.set(provider.version, forKey: key)
    }
}

/// Extension handling the gather of the current Ecosia App Version.
extension Version {
    
    /// A string representation of the current Ecosia App Version.
    static var ecosiaCurrent: Version {
        Version(AppInfo.ecosiaAppVersion)!
    }
}
