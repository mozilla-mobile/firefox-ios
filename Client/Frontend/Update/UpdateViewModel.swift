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
    
    static func isCleanInstall(userPrefs: Prefs) -> Bool {
        if userPrefs.stringForKey(LatestAppVersionProfileKey)?.components(separatedBy: ".").first == nil {
            return true 
        }
        return false
    }
    
    static func shouldShow(userPrefs: Prefs, currentAppVersion: String = VersionSetting.appVersion, isCleanInstall: Bool) -> Bool {
        if isCleanInstall {
            // We don't show it but save the currentVersion number
            userPrefs.setString(currentAppVersion, forKey: PrefsKeys.KeyLastVersionNumber)
            return false
        } else {
            // Its not a new install so first we check if there is a version number already saved
            if let savedVersion = userPrefs.stringForKey(PrefsKeys.KeyLastVersionNumber) {
               // Version number saved in user prefs is not the same as current version, return true
               if savedVersion != currentAppVersion {
                   userPrefs.setString(currentAppVersion, forKey: PrefsKeys.KeyLastVersionNumber)
                   return true
                 // Version number saved in user prefs matches the current version, return false
               } else if savedVersion == currentAppVersion {
                   return false
               }
            } else {
                // Only way the version is not saved if the user is coming from an app that didn't have this feature
                // as its not a clean install. Hence we should still show the update screen but save the version
                userPrefs.setString(currentAppVersion, forKey: PrefsKeys.KeyLastVersionNumber)
                return true
            }
        }
        return false
    }
}
