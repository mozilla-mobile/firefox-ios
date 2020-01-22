/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class UpdateViewModel {
    //  Internal vars
    var updateCoverSheetModel: UpdateCoverSheetModel?
    var shouldStartBrowsing: (() -> Void)?
    
    // Constants
    let updates: [Update] = [Update(updateImage: #imageLiteral(resourceName: "darkModeUpdate"), updateText: "\(Strings.CoverSheetV22DarkModeTitle)\n\n\(Strings.CoverSheetV22DarkModeDescription)")]
    
    init() {
        setupUpdateModel()
    }

    private func setupUpdateModel() {
        updateCoverSheetModel = UpdateCoverSheetModel(titleImage: #imageLiteral(resourceName: "splash"), titleText: Strings.WhatsNewString, updates: updates)
    }
    
    static func shouldShow(userPrefs: Prefs) -> Bool {
        let currentVersion = "\(VersionSetting.appVersion) \(VersionSetting.appBuildNumber)"
        // Version number exist
        if let lastVersion = userPrefs.stringForKey(PrefsKeys.KeyLastVersionNumber) {
            // Version number saved in user prefs is not the same as current version, return true
            if lastVersion != currentVersion {
                userPrefs.setString(currentVersion, forKey: PrefsKeys.KeyLastVersionNumber)
                return true
              // Version number saved in user prefs matches the current version, return false
            } else if lastVersion == currentVersion {
                return false
            }
        } else {
            // Version number doesn't exist, its the 1st launch. Set the current version and return false
            userPrefs.setString(currentVersion, forKey: PrefsKeys.KeyLastVersionNumber)
            return false
        }

        return false
    }
}
