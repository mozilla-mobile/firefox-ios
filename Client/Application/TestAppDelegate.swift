/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class TestAppDelegate: AppDelegate {
    override func getProfile(_ application: UIApplication) -> Profile {
        if let profile = self.profile {
            return profile
        }

        // Use a clean profile for each test session.
        let profile = BrowserProfile(localName: "testProfile", app: application)
        _ = try? profile.files.removeFilesInDirectory()
        profile.prefs.clearAll()

        // Don't show the What's New page.
        profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

        // Skip the first run UI except when we are running Fastlane Snapshot tests
        if !AppConstants.IsRunningFastlaneSnapshot {
            profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
        }

        self.profile = profile
        return profile
    }
}
