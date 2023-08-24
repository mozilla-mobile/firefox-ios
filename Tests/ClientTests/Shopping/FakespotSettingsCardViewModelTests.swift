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
        mockProfile = MockProfile()
        viewModel = FakespotSettingsCardViewModel(
            profile: mockProfile,
            cardA11yId: "testCardId",
            showProductsLabelTitle: "Show Products",
            showProductsLabelTitleA11yId: "showProductsLabelId",
            turnOffButtonTitle: "Turn Off",
            turnOffButtonTitleA11yId: "turnOffButtonId",
            recommendedProductsSwitchA11yId: "recommendedProductsSwitchId"
        )
    }

    override func tearDown() {
        super.tearDown()
        viewModel = nil
        mockProfile = nil
    }

    func testInitialViewModelValues() {
        XCTAssertEqual(viewModel.areAdsEnabled, true)
        XCTAssertEqual(viewModel.isReviewQualityCheckOn, true)
    }

    func testGetUserPrefsAfterSettingPrefs() {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Shopping2023EnableAds)
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Shopping2023OptIn)

        XCTAssertEqual(viewModel.areAdsEnabled, true)
        XCTAssertEqual(viewModel.isReviewQualityCheckOn, false)
    }

    func testSetUserPrefs() {
        viewModel.areAdsEnabled = false
        viewModel.isReviewQualityCheckOn = true

        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023EnableAds), false)
        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn), true)
    }

    func testSwitchValueChangedUpdatesPrefs() {
        viewModel.areAdsEnabled = false

        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023EnableAds), false)
    }

    func testTurnOffButtonTappedUpdatesPrefs() {
        viewModel.isReviewQualityCheckOn = false

        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn), false)
    }
}
