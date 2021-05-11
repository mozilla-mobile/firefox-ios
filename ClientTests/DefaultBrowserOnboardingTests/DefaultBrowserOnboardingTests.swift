/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client
import XCTest
import Shared

class DefaultBrowserOnboardingTests: XCTestCase {
    var prefs: NSUserDefaultsPrefs!

    override func setUp() {
        super.setUp()
        prefs = NSUserDefaultsPrefs(prefix: "DefaultBrowserOnboardingTest")
    }

    override func tearDown() {
        prefs.clearAll()
        super.tearDown()
    }
    
    func testShouldNotShowCoverSheetFreshInstallSessionLessThan3() {
        var sessionValue: Int32 = 0
        let shouldShow = DefaultBrowserOnboardingViewModel.shouldShowDefaultBrowserOnboarding(userPrefs: prefs)
        // The session value should increase from 0 to 1
        sessionValue = prefs.intForKey(PrefsKeys.SessionCount) ?? 0
        XCTAssertEqual(sessionValue, 0)
        XCTAssert(!shouldShow)
    }
    
    func testShouldShowCoverSheetCleanInstallSessionEqualTo3() {
        var shouldShow: Bool = false
        var didShow: Bool = false
        prefs.setInt(3, forKey: PrefsKeys.SessionCount)
        UserDefaults.standard.set(false, forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
        shouldShow = DefaultBrowserOnboardingViewModel.shouldShowDefaultBrowserOnboarding(userPrefs: prefs)
        didShow = UserDefaults.standard.bool(forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
        XCTAssert(shouldShow)
        XCTAssert(didShow)
    }
}
