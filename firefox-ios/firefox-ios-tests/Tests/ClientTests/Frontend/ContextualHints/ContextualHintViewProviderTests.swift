// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

class ContextualHintViewProviderTests: XCTestCase {
    typealias CFRPrefsKeys = PrefsKeys.ContextualHints

    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        profile = nil
        super.tearDown()
    }

    // MARK: Mark Contextual Hint Configuration

    func test_dataClearanceConfiguration() {
        let subject = ContextualHintViewProvider(forHintType: .dataClearance, with: profile)
        XCTAssertTrue(subject.shouldPresentContextualHint())
        XCTAssertFalse(subject.isActionType)
    }

    func test_markContextualHintPresented_setPrefsTrue() {
        let subject = ContextualHintViewProvider(forHintType: .dataClearance, with: profile)
        subject.markContextualHintPresented()
        XCTAssertTrue(profile.prefs.boolForKey(CFRPrefsKeys.dataClearanceKey.rawValue)!)
    }

    func test_markContextualHintConfiguration_withDataClearanceTrue_doesNotSetPrefs() {
        let subject = ContextualHintViewProvider(forHintType: .dataClearance, with: profile)
        subject.markContextualHintConfiguration(configured: true)
        XCTAssertNil(profile.prefs.boolForKey(CFRPrefsKeys.dataClearanceKey.rawValue))
    }

    func test_markContextualHintConfiguration_withDataClearanceFalse_doesNotSetPrefs() {
        let subject = ContextualHintViewProvider(forHintType: .dataClearance, with: profile)
        subject.markContextualHintConfiguration(configured: false)
        XCTAssertNil(profile.prefs.boolForKey(CFRPrefsKeys.dataClearanceKey.rawValue))
    }

    func testJumpBackInSyncTabConfiguredTrue() {
        let subject = ContextualHintViewProvider(forHintType: .jumpBackInSyncedTab, with: profile)
        subject.markContextualHintConfiguration(configured: true)
        XCTAssertTrue(profile.prefs.boolForKey(CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue)!)
    }

    func testJumpBackInSyncTabConfiguredFalse() {
        let subject = ContextualHintViewProvider(forHintType: .jumpBackInSyncedTab, with: profile)
        subject.markContextualHintConfiguration(configured: false)
        XCTAssertFalse(profile.prefs.boolForKey(CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue)!)
    }

    func testJumpBackInConfiguredTrue() {
        let subject = ContextualHintViewProvider(forHintType: .jumpBackIn, with: profile)
        subject.markContextualHintConfiguration(configured: true)
        XCTAssertTrue(profile.prefs.boolForKey(CFRPrefsKeys.jumpBackInConfiguredKey.rawValue)!)
    }

    func testJumpBackInConfiguredFalse() {
        let subject = ContextualHintViewProvider(forHintType: .jumpBackIn, with: profile)
        subject.markContextualHintConfiguration(configured: false)
        XCTAssertFalse(profile.prefs.boolForKey(CFRPrefsKeys.jumpBackInConfiguredKey.rawValue)!)
    }
}
