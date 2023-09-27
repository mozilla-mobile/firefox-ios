// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared
@testable import Client

class ContextualHintEligibilityUtilityTests: XCTestCase {
    typealias CFRPrefsKeys = PrefsKeys.ContextualHints

    var profile: MockProfile!
    var subject: ContextualHintEligibilityUtility!
    var urlBar: MockURLBarView!
    var overlayState: MockOverlayModeManager!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        urlBar = MockURLBarView()
        overlayState = MockOverlayModeManager()
        overlayState.setURLBar(urlBarView: urlBar)
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: nil,
                                                   device: MockUIDevice(isIpad: false))
    }

    override func tearDown() {
        super.tearDown()

        profile.shutdown()
        profile = nil
        urlBar = nil
        overlayState = nil
        subject = nil
    }

    // MARK: - Test should Present cases

    func test_shouldPresentInactiveTabsHint() {
        let result = subject.canPresent(.inactiveTabs)
        XCTAssertTrue(result)
    }

    func test_shouldPresentInactiveTabsHint_WithNilOverlayMode() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: nil,
                                                   device: MockUIDevice(isIpad: true))
        let result = subject.canPresent(.inactiveTabs)
        XCTAssertTrue(result)
    }

    func test_shouldPresentJumpBackHint() {
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.toolbarOnboardingKey.rawValue)

        let result = subject.canPresent(.jumpBackIn)
        XCTAssertTrue(result)
    }

    func test_shouldPresentJumpBackHint_iPhoneWithoutToolbar() {
        let result = subject.canPresent(.jumpBackIn)
        XCTAssertFalse(result)
    }

    func test_shouldPresentJumpBackHint_iPadWithoutToolbar() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: overlayState,
                                                   device: MockUIDevice(isIpad: true))
        let result = subject.canPresent(.jumpBackIn)
        XCTAssertTrue(result)
    }

    func test_shouldPresentSyncedTabHint() {
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.toolbarOnboardingKey.rawValue)

        let result = subject.canPresent(.jumpBackInSyncedTab)
        XCTAssertTrue(result)
    }

    func test_shouldPresentSyncedHint_iPhoneWithoutToolbar() {
        let result = subject.canPresent(.jumpBackInSyncedTab)
        XCTAssertFalse(result)
    }

    func test_shouldPresentSyncedHint_iPadWithoutToolbar() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: overlayState,
                                                   device: MockUIDevice(isIpad: true))
        let result = subject.canPresent(.jumpBackInSyncedTab)
        XCTAssertTrue(result)
    }

    // MARK: - Test should NOT Present cases

    func test_shouldNotPresentInactiveTabsHint() {
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.inactiveTabsKey.rawValue)

        let result = subject.canPresent(.inactiveTabs)
        XCTAssertFalse(result)
    }

    func test_shouldNotPresentJumpBackInHint() {
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.jumpBackinKey.rawValue)

        let result = subject.canPresent(.jumpBackIn)
        XCTAssertFalse(result)
    }

    func test_shouldNotPresentJumpBackHint_WithOverlayMode() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: overlayState,
                                                   device: MockUIDevice(isIpad: true))
        overlayState.openNewTab(url: nil, newTabSettings: .topSites)
        let result = subject.canPresent(.jumpBackIn)
        XCTAssertFalse(result)
    }

    func test_shouldNotPresentJumpBackInWhenSyncedTabConfigured() {
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue)

        let result = subject.canPresent(.jumpBackIn)
        XCTAssertFalse(result)
    }

    func test_shouldNotPresentSyncedTabHint() {
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.jumpBackInSyncedTabKey.rawValue)

        let result = subject.canPresent(.jumpBackInSyncedTab)
        XCTAssertFalse(result)
    }

    func test_shouldNotPresentSyncedHint_WithOverlayMode() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: overlayState,
                                                   device: MockUIDevice(isIpad: true))
        overlayState.openNewTab(url: nil, newTabSettings: .topSites)
        let result = subject.canPresent(.jumpBackInSyncedTab)
        XCTAssertFalse(result)
    }

    // Test Shopping CFRs
    func test_canPresentShoppingCFR_FirstDisplay_UserHasNotOptedIn() {
        subject = ContextualHintEligibilityUtility(with: profile, overlayState: overlayState)
        let result = subject.canPresent(.shoppingExperience)
        XCTAssertTrue(result)
    }

    func test_canPresentShoppingCFR_SecondDisplay_UserHasNotOptedIn_TimeHasPassed() {
        let lastTimestamp: Timestamp = 1695719918000 // Date and time (GMT): Tuesday, 26 September 2023 09:18:38

        profile.prefs.setBool(true, forKey: CFRPrefsKeys.shoppingOnboardingKey.rawValue)
        profile.prefs.setTimestamp(lastTimestamp, forKey: PrefsKeys.FakespotLastCFRTimestamp)
        profile.prefs.setBool(false, forKey: PrefsKeys.Shopping2023OptIn)

        let result = subject.canPresent(.shoppingExperience)
        XCTAssertTrue(result)
    }

    func test_canPresentShoppingCFR_SecondDisplay_UserHasOptedIn_TimeHasPassed() {
        let lastTimestamp: Timestamp = 1695719918000 // Date and time (GMT): Tuesday, 26 September 2023 09:18:38

        profile.prefs.setBool(true, forKey: CFRPrefsKeys.shoppingOnboardingKey.rawValue)
        profile.prefs.setTimestamp(lastTimestamp, forKey: PrefsKeys.FakespotLastCFRTimestamp)
        profile.prefs.setBool(true, forKey: PrefsKeys.Shopping2023OptIn)

        let result = subject.canPresent(.shoppingExperience)
        XCTAssertTrue(result)
    }

    func test_canPresentShoppingCFR_SecondDisplay_UserHasNotOptedIn_TimeHasNotPassed() {
        let lastTimestamp: Timestamp = Date.now()

        profile.prefs.setBool(true, forKey: CFRPrefsKeys.shoppingOnboardingKey.rawValue)
        profile.prefs.setTimestamp(lastTimestamp, forKey: PrefsKeys.FakespotLastCFRTimestamp)
        profile.prefs.setBool(false, forKey: PrefsKeys.Shopping2023OptIn)

        let result = subject.canPresent(.shoppingExperience)
        XCTAssertFalse(result)
    }

    func test_canPresentShoppingCFR_SecondDisplay_UserHasOptedIn_TimeHasNotPassed() {
        let lastTimestamp: Timestamp = Date.now()

        profile.prefs.setBool(true, forKey: CFRPrefsKeys.shoppingOnboardingKey.rawValue)
        profile.prefs.setTimestamp(lastTimestamp, forKey: PrefsKeys.FakespotLastCFRTimestamp)
        profile.prefs.setBool(true, forKey: PrefsKeys.Shopping2023OptIn)

        let result = subject.canPresent(.shoppingExperience)
        XCTAssertFalse(result)
    }
}
