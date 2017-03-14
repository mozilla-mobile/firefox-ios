/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import XCTest

class HomePageTests: XCTestCase {
    let prefs = NSUserDefaultsPrefs(prefix: "PrefsTests")

    func testHomePageSettingForInternalURLs() {
        let helper = HomePageHelper(prefs: prefs)
        helper.currentURL = URL(string: "http://localhost:6571")
        XCTAssertNil(prefs.stringForKey(HomePageConstants.HomePageURLPrefKey))
    }
}
