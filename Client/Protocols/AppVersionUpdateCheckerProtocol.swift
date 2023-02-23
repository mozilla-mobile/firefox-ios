// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol AppVersionUpdateCheckerProtocol {
    func isMajorVersionUpdate(using profile: Profile,
                              and currentAppVersion: String) -> Bool
}

extension AppVersionUpdateCheckerProtocol {
    /// If we do not have the PrefsKeys.AppVersion.Latest in the profile, that means that
    /// this is a fresh install. If we do have that value, we compare it to the major
    /// version of the running app. If it is different then this is an upgrade.
    /// Downgrades are not possible.
    ///
    /// - Parameter profile:
    /// - Parameters:
    ///   - profile: The profile used to check for the latest version
    ///   - currentAppVersion: A provided app version for testing purposes, or the current app version, by default
    /// - Returns: Whether or not this is a major update.
    func isMajorVersionUpdate(
        using profile: Profile,
        and currentAppVersion: String = AppInfo.appVersion
    ) -> Bool {
        guard let latestMajorAppVersion = profile.prefs
            .stringForKey(PrefsKeys.AppVersion.Latest)?
            .components(separatedBy: ".")
            .first
        else { return false }

        return !currentAppVersion.contains(latestMajorAppVersion)
    }
}
