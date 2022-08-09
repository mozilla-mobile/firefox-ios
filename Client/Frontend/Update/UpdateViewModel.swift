/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class UpdateViewModel {
    //  Internal vars
    var updateCoverSheetModel: UpdateCoverSheetModel?
    var startBrowsing: (() -> Void)?
    let userPrefs: Prefs

    // Constants
    let updates: [Update] = [Update(updateImage: #imageLiteral(resourceName: "darkModeUpdate"), updateText: "\(String.CoverSheetV22DarkModeTitle)\n\n\(String.CoverSheetV22DarkModeDescription)")]

    // We only show coversheet for specific app updates and not all.
    // The list below is for the version(s) we would like to show the coversheet for.
    // TODO: Yoana update to v106 after
    let supportedAppVersion = ["22.0, 104.0"]

    var isCleanInstall: Bool {
        if userPrefs.stringForKey(LatestAppVersionProfileKey)?.components(separatedBy: ".").first == nil {
            return true
        }
        return false
    }

    init(userPrefs: Prefs) {
        self.userPrefs = userPrefs
        setupUpdateModel()
    }

    private func setupUpdateModel() {
        updateCoverSheetModel = UpdateCoverSheetModel(titleImage: #imageLiteral(resourceName: "splash"), titleText: .AppMenu.WhatsNewString, updates: updates)
    }

    func shouldShowUpdateSheet(appVersion: String = AppInfo.appVersion) -> Bool {
        guard !isCleanInstall, !supportedAppVersion.contains(appVersion) else {
            // We don't show it but save the currentVersion number
            userPrefs.setString(appVersion, forKey: PrefsKeys.KeyLastVersionNumber)
            return false
        }

        // Its not a new install so first we check if there is a version number already saved
        if let savedVersion = userPrefs.stringForKey(PrefsKeys.KeyLastVersionNumber) {
           // Version number saved in user prefs is not the same as current version, return true
           if savedVersion != appVersion {
               userPrefs.setString(appVersion, forKey: PrefsKeys.KeyLastVersionNumber)
               return true
             // Version number saved in user prefs matches the current version, return false
           } else {
               return false
           }
        } else {
            // Only way the version is not saved if the user is coming from an app that didn't have this feature
            // as its not a clean install. Hence we should still show the update screen but save the version
            userPrefs.setString(appVersion, forKey: PrefsKeys.KeyLastVersionNumber)
            return true
        }
    }
}
