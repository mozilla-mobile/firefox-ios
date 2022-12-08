// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

class ContextualHintViewModelTests: XCTestCase {
    typealias CFRPrefsKeys = PrefsKeys.ContextualHints

    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    // MARK: Mark Contextual Hint Configuration

    func testJumpBackInSyncTabConfiguredTrue() {
        let subject = ContextualHintViewModel(forHintType: .jumpBackInSyncedTab, with: profile)
        subject.markContextualHintConfiguration(configured: true)
        XCTAssertTrue(profile.prefs.boolForKey(CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue)!)
    }

    func testJumpBackInSyncTabConfiguredFalse() {
        let subject = ContextualHintViewModel(forHintType: .jumpBackInSyncedTab, with: profile)
        subject.markContextualHintConfiguration(configured: false)
        XCTAssertFalse(profile.prefs.boolForKey(CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue)!)
    }

    func testJumpBackInConfiguredTrue() {
        let subject = ContextualHintViewModel(forHintType: .jumpBackIn, with: profile)
        subject.markContextualHintConfiguration(configured: true)
        XCTAssertTrue(profile.prefs.boolForKey(CFRPrefsKeys.jumpBackInConfiguredKey.rawValue)!)
    }

    func testJumpBackInConfiguredFalse() {
        let subject = ContextualHintViewModel(forHintType: .jumpBackIn, with: profile)
        subject.markContextualHintConfiguration(configured: false)
        XCTAssertFalse(profile.prefs.boolForKey(CFRPrefsKeys.jumpBackInConfiguredKey.rawValue)!)
    }
}
