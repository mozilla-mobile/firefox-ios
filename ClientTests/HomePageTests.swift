// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import XCTest
import Shared

class HomePageTests: XCTestCase {
    let prefs = NSUserDefaultsPrefs(prefix: "PrefsTests")

    func testHomePageSettingForInternalURLs() {
        let helper = HomePageHelper(prefs: prefs)
        helper.currentURL = URL(string: "\(InternalURL.baseUrl)")
        XCTAssertNil(prefs.stringForKey(HomePageConstants.NewTabCustomUrlPrefKey))
    }
}
