/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Leanplum

class ETPViewModel {
    //  Internal vars
    var etpCoverSheetmodel: ETPCoverSheetModel?
    var startBrowsing: (() -> Void)?
    var goToSettings: (() -> Void)?
    
    // We only show ETP coversheet for specific app updates and not all. The list below is for the version(s)
    // we would like to show the coversheet for.
    static let etpCoverSheetSupportedAppVersion = ["24.0"]
    
    init() {
        setupUpdateModel()
    }

    private func setupUpdateModel() {
        etpCoverSheetmodel = ETPCoverSheetModel(titleImage: #imageLiteral(resourceName: "shield"), titleText: Strings.CoverSheetETPTitle, descriptionText: Strings.CoverSheetETPDescription)
    }
    
    static func shouldShowETPCoverSheet(userPrefs: Prefs, currentAppVersion: String = VersionSetting.appVersion, isCleanInstall: Bool, supportedAppVersions: [String] = etpCoverSheetSupportedAppVersion) -> Bool {
        // 0,1,2 so we show on 3rd session as a requirement on Github #6012
        let maxSessionCount = 2
        var shouldShow = false
        // Default type is upgrade as in user is upgrading from a different version of the app
        var type: ETPCoverSheetShowType = isCleanInstall ? .CleanInstall : .Upgrade
        var sessionCount: Int32 = 0
        if let etpShowType = userPrefs.stringForKey(PrefsKeys.KeyETPCoverSheetShowType) {
            type = ETPCoverSheetShowType(rawValue: etpShowType) ?? .Unknown
        }
        // Get the session count from preferences
        if let currentSessionCount = userPrefs.intForKey(PrefsKeys.KeyInstallSession) {
            sessionCount = currentSessionCount
        }
        // Two flows: Coming from clean install or otherwise upgrade flow
        switch type {
        case .CleanInstall:
            // We don't show it but save the 1st clean install session number
            if sessionCount < maxSessionCount {
                // Increment the session number
                userPrefs.setInt(sessionCount + 1, forKey: PrefsKeys.KeyInstallSession)
                userPrefs.setString(ETPCoverSheetShowType.CleanInstall.rawValue, forKey: PrefsKeys.KeyETPCoverSheetShowType)
            } else if sessionCount == maxSessionCount {
                userPrefs.setString(ETPCoverSheetShowType.DoNotShow.rawValue, forKey: PrefsKeys.KeyETPCoverSheetShowType)
                shouldShow = true
            }
            break
        case .Upgrade:
            // This will happen if its not a clean install and we are upgrading from another version.
            // This is where we tag it as an upgrade flow and try to present it for specific version(s) Eg. v24.0
            userPrefs.setString(ETPCoverSheetShowType.Upgrade.rawValue, forKey: PrefsKeys.KeyETPCoverSheetShowType)
            if supportedAppVersions.contains(currentAppVersion) {
                userPrefs.setString(ETPCoverSheetShowType.DoNotShow.rawValue, forKey: PrefsKeys.KeyETPCoverSheetShowType)
                shouldShow = true
            }
            break
        case .DoNotShow:
            break
        case .Unknown:
            break
        }
        
        return shouldShow
    }
}
