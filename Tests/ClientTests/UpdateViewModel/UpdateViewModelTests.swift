// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
@testable import Client
import XCTest
import Shared

class UpdateViewModelTests: XCTestCase {
    var profile: MockProfile!
    var viewModel: UpdateViewModel!

    override func setUp() {
        super.setUp()
        profile = MockProfile(databasePrefix: "UpdateViewModel_tests")
        profile.reopen()
        viewModel = UpdateViewModel(profile: profile)
        UserDefaults.standard.removeObject(forKey: UpdateViewModel.prefsKey)
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        profile.shutdown()
        profile = nil
        viewModel = nil
        UserDefaults.standard.removeObject(forKey: UpdateViewModel.prefsKey)
    }

    // MARK: Enable cards
    func testEnabledCards_ForHasSyncAccount() {
        profile.hasSyncableAccountMock = true
        let expectation = expectation(description: "The hasAccount var has value")

        viewModel.hasSyncableAccount {
            let enableCards = self.viewModel.enabledCards

            XCTAssertEqual(enableCards.count, 1)
            XCTAssertEqual(enableCards[0], .updateWelcome)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testEnabledCards_ForSyncAccountDisabled() {
        profile.hasSyncableAccountMock = false
        let expectation = expectation(description: "The hasAccount var has value")

        viewModel.hasSyncableAccount {
            let enableCards = self.viewModel.enabledCards

            XCTAssertEqual(enableCards.count, 2)
            XCTAssertEqual(enableCards[0], .updateWelcome)
            XCTAssertEqual(enableCards[1], .updateSignSync)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    // MARK: Has Single card
    func testHasSingleCard_ForHasSyncAccount() {
        profile.hasSyncableAccountMock = true
        let expectation = expectation(description: "The hasAccount var has value")

        viewModel.hasSyncableAccount {
            XCTAssertEqual(self.viewModel.shouldShowSingleCard, true)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testHasSingleCard_ForSyncAccountDisabled() {
        profile.hasSyncableAccountMock = false
        XCTAssertEqual(viewModel.shouldShowSingleCard, false)
    }

    // MARK: ShouldShowFeature
    func testShouldNotShowCoverSheetCleanInstall() {
        let currentTestAppVersion = "22.0"

        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(UpdateViewModel.prefsKey), currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowCoverSheetForSameVersion() {
        let currentTestAppVersion = "22.0"

        // Setting clean install to false
        profile.prefs.setString(currentTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setString(currentTestAppVersion, forKey: UpdateViewModel.prefsKey)
        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(UpdateViewModel.prefsKey), currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldNotShowCoverSheet_ForMinorVersionUpgrade() {
        let olderTestAppVersion = "21.0"
        let updatedTestAppVersion = "21.1"

        // Setting clean install to false
        profile.prefs.setString(olderTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setString(updatedTestAppVersion, forKey: UpdateViewModel.prefsKey)

        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: updatedTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(UpdateViewModel.prefsKey), updatedTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldShowCoverSheetFromUpdateVersion() {
        let olderTestAppVersion = "21.0"
        let updatedTestAppVersion = "22.0"

        // Setting clean install to false
        profile.prefs.setString(olderTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setString(olderTestAppVersion, forKey: UpdateViewModel.prefsKey)

        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: updatedTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(UpdateViewModel.prefsKey), updatedTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldShowCoverSheetForVersionNil() {
        let currentTestAppVersion = "22.0"

        let shouldShow = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertFalse(shouldShow)
    }

    func testShouldSaveVersion_CleanInstall() {
        let currentTestAppVersion = "22.0"

        profile.prefs.setString(currentTestAppVersion, forKey: PrefsKeys.AppVersion.Latest)
        _ = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(UpdateViewModel.prefsKey), currentTestAppVersion)
    }

    func testShouldSaveVersion_UnsavedVersion() {
        let currentTestAppVersion = "22.0"

        _ = viewModel.shouldShowUpdateSheet(appVersion: currentTestAppVersion)
        XCTAssertEqual(profile.prefs.stringForKey(UpdateViewModel.prefsKey), currentTestAppVersion)
    }

    func testGetViewModel_ForValidUpgradeCard() {
        profile.hasSyncableAccountMock = false
        XCTAssertNotNil(viewModel.getCardViewModel(cardType: .updateWelcome))
        XCTAssertNotNil(viewModel.getCardViewModel(cardType: .updateSignSync))
    }

    func testGetViewModel_ForInvalidUpgradeCard() {
        XCTAssertNil(viewModel.getCardViewModel(cardType: .welcome))
        XCTAssertNil(viewModel.getCardViewModel(cardType: .signSync))
    }
}
