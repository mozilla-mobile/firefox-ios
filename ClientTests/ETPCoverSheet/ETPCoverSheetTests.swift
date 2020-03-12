/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client
import XCTest
import Shared

class ETPCoverSheetTests: XCTestCase {
    var prefs: NSUserDefaultsPrefs!

    override func setUp() {
        super.setUp()
        prefs = NSUserDefaultsPrefs(prefix: "UpdateViewModelPrefs")
    }

    override func tearDown() {
        prefs.clearAll()
        super.tearDown()
    }
    
    func testShouldNotShowCoverSheetCleanInstallSessionLessThan3() {
        let currentTestAppVersion = "18"
        let supportedVersion = ["18"]
        var sessionValue:Int32 = 0
        let shouldShow = ETPViewModel.shouldShowETPCoverSheet(userPrefs: prefs, currentAppVersion: currentTestAppVersion, isCleanInstall: true, supportedAppVersions: supportedVersion)
        // The session value should increase
        sessionValue = prefs.intForKey(PrefsKeys.KeyInstallSession) ?? 0
        XCTAssert(sessionValue == 1)
        // We also check that ETP Cover Sheet show type is clean install and it shouldn't show
        XCTAssert(prefs.stringForKey(PrefsKeys.KeyETPCoverSheetShowType) == ETPCoverSheetShowType.CleanInstall.rawValue)
        XCTAssert(!shouldShow)
    }
    
    func testShouldShowCoverSheetCleanInstallSessionEqualTo3() {
        let currentTestAppVersion = "18"
        let supportedVersion = ["18"]
        var sessionValue:Int32 = 0
        var shouldShow = false
        var isCleanInstall = true // Only for the first time
        for session in 0...2 {
           shouldShow = ETPViewModel.shouldShowETPCoverSheet(userPrefs: prefs, currentAppVersion: currentTestAppVersion, isCleanInstall: isCleanInstall, supportedAppVersions: supportedVersion)
            // False after the 1st run
            isCleanInstall = false
        }
        // The session value should increase to 2 as we aim to show when its the 3rd session (0,1,2)
        sessionValue = prefs.intForKey(PrefsKeys.KeyInstallSession) ?? 0
        XCTAssert(sessionValue == 2)
        // Should show should be true as we have reached the 3rd session
        XCTAssert(shouldShow)
        // We also check that ETP Cover Sheet show type is do not show as shouldShow is true and next time we don't want to show
        XCTAssert(prefs.stringForKey(PrefsKeys.KeyETPCoverSheetShowType) == ETPCoverSheetShowType.DoNotShow.rawValue)
    }
    
    func testShouldShowCoverSheetUpgradeFlow() {
        let currentTestAppVersion = "18"
        let supportedVersion = ["18"]
        var shouldShow = false
        let isCleanInstall = false // For upgrade flow its not a clean install
        shouldShow = ETPViewModel.shouldShowETPCoverSheet(userPrefs: prefs, currentAppVersion: currentTestAppVersion, isCleanInstall: isCleanInstall, supportedAppVersions: supportedVersion)
        // Should show should be true as we have just come from an upgrade flow
        XCTAssert(shouldShow)
        // We also check that ETP Cover Sheet show type is do not show as shouldShow is true and next time we don't want to show
        XCTAssert(prefs.stringForKey(PrefsKeys.KeyETPCoverSheetShowType) == ETPCoverSheetShowType.DoNotShow.rawValue)
    }
}
