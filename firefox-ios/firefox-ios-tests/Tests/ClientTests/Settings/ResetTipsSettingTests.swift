// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest
@testable import Client

@MainActor
@available(iOS 17.0, *)
class ResetTipsSettingTests: XCTestCase {
    private var prefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() {
        prefs = nil
        super.tearDown()
    }

    func test_resetDatastoreIfNeeded_whenResetIsNotScheduled_thenLeavesPrefUnset() {
        ResetTipsSetting.resetDatastoreIfNeeded(prefs: prefs)

        XCTAssertNil(prefs.boolForKey(PrefsKeys.Tips.shouldResetDatastore))
    }

    func test_resetDatastoreIfNeeded_whenResetIsScheduled_thenClearsPref() {
        prefs.setBool(true, forKey: PrefsKeys.Tips.shouldResetDatastore)

        ResetTipsSetting.resetDatastoreIfNeeded(prefs: prefs)

        XCTAssertNil(prefs.boolForKey(PrefsKeys.Tips.shouldResetDatastore))
    }
}
