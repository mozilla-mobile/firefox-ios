// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest
@testable import Client

final class FakespotSettingsCardViewModelTests: XCTestCase {
    private var viewModel: FakespotSettingsCardViewModel!
    private var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        viewModel = FakespotSettingsCardViewModel(profile: mockProfile, tabManager: MockTabManager())
    }

    override func tearDown() {
        viewModel = nil
        mockProfile = nil
        super.tearDown()
    }

    func testInitialViewModelValues() {
        XCTAssertEqual(viewModel.areAdsEnabled, true)
        XCTAssertEqual(viewModel.isReviewQualityCheckOn, false)
    }

    func testGetUserPrefsAfterSettingPrefs() {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Shopping2023EnableAds)
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Shopping2023OptIn)

        XCTAssertEqual(viewModel.areAdsEnabled, true)
        XCTAssertEqual(viewModel.isReviewQualityCheckOn, false)
    }

    func testGetUserPrefsAfterSettingWrongPrefsKey() {
        mockProfile.prefs.setBool(true, forKey: "")
        mockProfile.prefs.setBool(false, forKey: "")

        XCTAssertEqual(viewModel.areAdsEnabled, true)
        XCTAssertEqual(viewModel.isReviewQualityCheckOn, false)
    }

    func testTurnOffButtonTappedUpdatesPrefs() {
        viewModel.isReviewQualityCheckOn = false

        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn), false)
    }
}
