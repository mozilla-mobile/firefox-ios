// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
        prefs = nil
        super.tearDown()
    }

    func testInstallTypeIsUpgrade() {
        setTestData(installType: .upgrade, sessionCount: 3, didShowOnboarding: false)
        verify(expectedShouldShow: false)
    }

    func testInstallTypeIsUnknown() {
        setTestData(installType: .unknown, sessionCount: 3, didShowOnboarding: false)
        verify(expectedShouldShow: false)
    }
    
    func testInstallTypeFresh_alreadyShownOnboarding() {
        setTestData(installType: .fresh, sessionCount: 3, didShowOnboarding: true)
        verify(expectedShouldShow: false)
    }

    func testInstallTypeFresh_sessionCountIsLessThan3() {
        setTestData(installType: .fresh, sessionCount: 0, didShowOnboarding: false)
        verify(expectedShouldShow: false)
    }

    func testInstallTypeFresh_sessionCountIs3() {
        setTestData(installType: .fresh, sessionCount: 3, didShowOnboarding: false)
        verify(expectedShouldShow: true)
    }

    func testInstallTypeFresh_sessionCountIsMoreThan3() {
        setTestData(installType: .fresh, sessionCount: 5, didShowOnboarding: false)
        verify(expectedShouldShow: false)
    }

    func testViewModelChangePrefsOrNotAsExpected() {
        let expectedSessionCount: Int32 = 3
        let expectedDidShow = true

        setTestData(installType: .fresh, sessionCount: expectedSessionCount, didShowOnboarding: false)
        verify(expectedShouldShow: true)

        let didShowPref = UserDefaults.standard.bool(forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
        XCTAssertEqual(didShowPref, expectedDidShow)

        let sessionCount = prefs.intForKey(PrefsKeys.SessionCount)
        XCTAssertEqual(sessionCount, expectedSessionCount)
    }
}

private extension DefaultBrowserOnboardingTests {

    func setTestData(installType: InstallType, sessionCount: Int32, didShowOnboarding: Bool) {
        InstallType.set(type: installType)
        prefs.setInt(sessionCount, forKey: PrefsKeys.SessionCount)
        UserDefaults.standard.set(didShowOnboarding, forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
    }

    func verify(expectedShouldShow: Bool, file: StaticString = #file, line: UInt = #line) {
        let shouldShow = DefaultBrowserOnboardingViewModel.shouldShowDefaultBrowserOnboarding(userPrefs: prefs)
        XCTAssertEqual(shouldShow, expectedShouldShow, file: file, line: line)
    }
}
