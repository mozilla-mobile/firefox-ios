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

    func testInitialCallbacksAreNil() {
        XCTAssertNil(viewModel.onSwitchValueChanged)
        XCTAssertNil(viewModel.onTurnOffButtonTapped)
    }

    func testGetUserPrefsAfterSettingCallbacks() {
        viewModel.setUserPrefs()
        viewModel.onSwitchValueChanged?(true)
        viewModel.onTurnOffButtonTapped?(false)

        viewModel.getUserPrefs()

        XCTAssertEqual(viewModel.areAdsEnabled, true)
        XCTAssertEqual(viewModel.isReviewQualityCheckOn, false)
    }

    func testSetUserPrefsAndVerifyCallbacks() {
        viewModel.setUserPrefs()
        viewModel.onSwitchValueChanged?(false)
        viewModel.onTurnOffButtonTapped?(true)

        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023EnableAds), false)
        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn), true)
    }

    func testSwitchValueChangedUpdatesPrefs() {
        viewModel.setUserPrefs()
        viewModel.onSwitchValueChanged?(false)

        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023EnableAds), false)
    }

    func testTurnOffButtonTappedUpdatesPrefs() {
        viewModel.setUserPrefs()
        viewModel.onTurnOffButtonTapped?(true)

        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn), true)
    }

    func testSetUserPrefsWithoutCallbacks() {
        viewModel.setUserPrefs()

        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023EnableAds), nil)
        XCTAssertEqual(mockProfile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn), nil)
    }
}
