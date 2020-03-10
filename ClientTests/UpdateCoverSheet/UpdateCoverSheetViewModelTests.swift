/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client
import XCTest
import Shared

class UpdateCoverSheetViewModelTests: XCTestCase {
    var prefs: NSUserDefaultsPrefs!

    override func setUp() {
        super.setUp()
        prefs = NSUserDefaultsPrefs(prefix: "UpdateViewModelPrefs")
    }

    override func tearDown() {
        prefs.clearAll()
        super.tearDown()
    }
    
    func testShouldNotShowCoverSheetCleanInstall() {
        let currentTestAppVersion = "18"
        let shouldShow = UpdateViewModel.shouldShowUpdateSheet(userPrefs: prefs, currentAppVersion: currentTestAppVersion, isCleanInstall: true, supportedAppVersions: ["18"])
        // Since its a clean install the current app version should be saved as currentTestAppVersion
        // Also, the shouldShow flag should be false
        XCTAssert(prefs.stringForKey(PrefsKeys.KeyLastVersionNumber) == currentTestAppVersion)
        XCTAssert(!shouldShow)
    }
    
    func testShouldNotShowCoverSheetForSameVersion() {
        let currentTestAppVersion = "18"
        // First we save the current app version to the prefs. This way we are making same condition as
        // the app is not a new install but is just opening again
        prefs.setString(currentTestAppVersion, forKey: PrefsKeys.KeyLastVersionNumber)
        // We also set the isCleanInstall to false as we are mimicking its not a new install condition
        let shouldShow = UpdateViewModel.shouldShowUpdateSheet(userPrefs: prefs, currentAppVersion: currentTestAppVersion, isCleanInstall: false, supportedAppVersions: ["18"])
        
        // Since its not clean install and the current app version is same as before. We should get a false
        // for showing the update cover sheet
        XCTAssert(!shouldShow)
    }
    
    func testShouldShowCoverSheetFromNoFeatureToUpdate() {
        let olderTestAppVersion = "18"
        let updatedTestAppVersion = "19"
        // This is the case where user comes from a version which has this feature of cover sheet
        // Its not a new install but an update. There is saved KeyLastVersionNumber in the prefs
        // as the feature still existed
        prefs.setString(olderTestAppVersion, forKey: PrefsKeys.KeyLastVersionNumber)
        let shouldShow = UpdateViewModel.shouldShowUpdateSheet(userPrefs: prefs, currentAppVersion: updatedTestAppVersion, isCleanInstall: false, supportedAppVersions: ["18"])
        // Since its not clean install but we are still updating the app from a previous version that
        // already had this feature. We will save the updatedTestAppVersion to prefs and not show the cover sheet as its not a part of supportedAppVersion
        XCTAssert(prefs.stringForKey(PrefsKeys.KeyLastVersionNumber) == updatedTestAppVersion)
        XCTAssert(!shouldShow)
    }
    
    func testShouldShowCoverSheetFromFeatureToUpdate() {
        let updatedTestAppVersion = "19"
        // This is the case where user comes from a version which did not have this feature of cover sheet
        // Its not a new install, there is no saved KeyLastVersionNumber in the prefs
        let shouldShow = UpdateViewModel.shouldShowUpdateSheet(userPrefs: prefs, currentAppVersion: updatedTestAppVersion, isCleanInstall: false, supportedAppVersions: ["19"])
        // Since its not clean install but we are still updating the app from a previous version. We will
        // save the updatedTestAppVersion as it didn't exist before to prefs and
        // should show the update cover sheet
        XCTAssert(prefs.stringForKey(PrefsKeys.KeyLastVersionNumber) == updatedTestAppVersion)
        XCTAssert(shouldShow)
    }
}
