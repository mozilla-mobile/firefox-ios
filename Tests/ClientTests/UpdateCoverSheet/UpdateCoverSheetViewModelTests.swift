// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
@testable import Client
import XCTest
import Shared

class UpdateCoverSheetViewModelTests: XCTestCase {
    var profile: MockProfile!
    var viewModel: UpdateViewModel!

    override func setUp() {
        super.setUp()
        profile = MockProfile(databasePrefix: "UpdateViewModel_tests")
        profile._reopen()
        viewModel = UpdateViewModel(profile: profile)
        UserDefaults.standard.removeObject(forKey: UpdateViewModel.prefsKey)
    }

    override func tearDown() {
        super.tearDown()
        profile._shutdown()
        profile = nil
        viewModel = nil
        UserDefaults.standard.removeObject(forKey: UpdateViewModel.prefsKey)
    }

    func testShouldNotShowCoverSheetCleanInstall() {
        let currentTestAppVersion = "22.0"
        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(UpdateViewModel.prefsKey), currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowCoverSheetForSameVersion() {
        let currentTestAppVersion = "22.0"

        // Setting clean install to false and currentAppVersion
        profile.prefs.setString(currentTestAppVersion, forKey: LatestAppVersionProfileKey)
        profile.prefs.setString(currentTestAppVersion, forKey: UpdateViewModel.prefsKey)

        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowCoverSheetForUnsupportedVersion() {
        let currentTestAppVersion = "18.0"

        // Setting clean install to false and currentAppVersion
        profile.prefs.setString(currentTestAppVersion, forKey: LatestAppVersionProfileKey)
        profile.prefs.setString(currentTestAppVersion, forKey: UpdateViewModel.prefsKey)

        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldShowCoverSheetFromUpdateVersion() {
        let olderTestAppVersion = "21.0"
        let updatedTestAppVersion = "22.0"

        profile.prefs.setString(updatedTestAppVersion, forKey: LatestAppVersionProfileKey)
        profile.prefs.setString(olderTestAppVersion, forKey: UpdateViewModel.prefsKey)

        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: updatedTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(UpdateViewModel.prefsKey), updatedTestAppVersion)
        XCTAssertTrue(shouldShow)
    }

    func testShouldShowCoverSheetForVersionNil() {
        let currentTestAppVersion = "22.0"
        profile.prefs.setString(currentTestAppVersion, forKey: LatestAppVersionProfileKey)

        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertTrue(shouldShow)
    }
}
