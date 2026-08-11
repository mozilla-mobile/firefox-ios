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

    override func setUp() async throws {
        try await super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() async throws {
        prefs = nil
        try await super.tearDown()
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
