// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Shared
import XCTest

final class RustFirefoxAccountsProfileCacheTests: XCTestCase {
    func testClearUserProfileCache_removesPersistedProfile() {
        let prefs = MockProfilePrefs()
        let cachedProfileJSON = """
        {"uid":"abc123","email":"test@example.com","avatarUrl":null,"displayName":"Test User"}
        """
        prefs.setObject(Data(cachedProfileJSON.utf8), forKey: RustFirefoxAccounts.prefKeyCachedUserProfile)

        RustFirefoxAccounts.shared.clearUserProfileCache(prefs: prefs)

        let remaining: Data? = prefs.objectForKey(RustFirefoxAccounts.prefKeyCachedUserProfile)
        XCTAssertNil(remaining)
    }

    func testClearUserProfileCache_isSafeWhenNothingIsCached() {
        let prefs = MockProfilePrefs()

        RustFirefoxAccounts.shared.clearUserProfileCache(prefs: prefs)

        let remaining: Data? = prefs.objectForKey(RustFirefoxAccounts.prefKeyCachedUserProfile)
        XCTAssertNil(remaining)
    }
}
