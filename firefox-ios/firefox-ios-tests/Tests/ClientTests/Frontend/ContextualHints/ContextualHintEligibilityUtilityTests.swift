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
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: nil)
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
                                                   overlayState: nil)
        let result = subject.canPresent(.inactiveTabs)
        XCTAssertTrue(result)
    }

    func test_shouldPresentDataClearanceHint() {
        let result = subject.canPresent(.dataClearance)
        XCTAssertTrue(result)
    }

    // MARK: Jump Back in and Synced tabs
    func test_shouldPresentJumpBackHint() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: overlayState,
                                                   isToolbarUpdateCFRFeatureEnabled: true)
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.toolbarUpdateKey.rawValue)
        let result = subject.canPresent(.jumpBackIn)
        XCTAssertTrue(result)
    }

    func test_shouldPresentJumpBackHint_withToolbarUpdateFeatureDisabled() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: overlayState,
                                                   isToolbarUpdateCFRFeatureEnabled: false)
        let result = subject.canPresent(.jumpBackIn)
        XCTAssertTrue(result)
    }

    func test_shouldPresentSyncedTabHint() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: overlayState,
                                                   isToolbarUpdateCFRFeatureEnabled: true)
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.toolbarUpdateKey.rawValue)
        let result = subject.canPresent(.jumpBackInSyncedTab)
        XCTAssertTrue(result)
    }

    func test_shouldPresentSyncedHint_withToolbarUpdateFeatureDisabled() {
        subject = ContextualHintEligibilityUtility(with: profile,
                                                   overlayState: overlayState,
                                                   isToolbarUpdateCFRFeatureEnabled: false)
        let result = subject.canPresent(.jumpBackInSyncedTab)
        XCTAssertTrue(result)
    }

    // MARK: - Test should NOT Present cases

    func test_shouldNotPresentInactiveTabsHint() {
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.inactiveTabsKey.rawValue)

        let result = subject.canPresent(.inactiveTabs)
        XCTAssertFalse(result)
    }

    func test_shouldNotPresentDataClearanceHint() {
        profile.prefs.setBool(true, forKey: CFRPrefsKeys.dataClearanceKey.rawValue)

        let result = subject.canPresent(.dataClearance)
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
                                                   isToolbarUpdateCFRFeatureEnabled: false)
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
                                                   isToolbarUpdateCFRFeatureEnabled: false)
        overlayState.openNewTab(url: nil, newTabSettings: .topSites)
        let result = subject.canPresent(.jumpBackInSyncedTab)
        XCTAssertFalse(result)
    }
}
