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

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   device: MockUIDevice(isIpad: false))
    }

    override func tearDown() {
        super.tearDown()

        profile.shutdown()
        profile = nil
        subject = nil
    }

    // MARK: - Test should Present cases

    func test_shouldPresentInactiveTabsHint() {
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
}
