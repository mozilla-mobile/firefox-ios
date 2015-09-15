/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TestAppDelegate: AppDelegate {
    override func getProfile(application: UIApplication) -> Profile {
        // Use a clean profile for each test session.
        let profile = BrowserProfile(localName: "testProfile", app: application)
        _ = try? profile.files.removeFilesInDirectory()
        profile.prefs.clearAll()

        // Skip the first run UI.
        profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)

        return profile
    }
}