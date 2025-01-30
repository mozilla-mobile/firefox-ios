/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import Onboarding
import AppShortcuts

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class BrowserViewControllerTests: XCTestCase {
    private let mockUserDefaults = MockUserDefaults()

    private lazy var onboardingEventsHandler = OnboardingEventsHandlerV1(
        getShownTips: {
            return []
        }, setShownTips: { _ in
        }
    )

    private lazy var themeManager = ThemeManager()

    func testRequestReviewThreshold() {
        let bvc = BrowserViewController(
            shortcutManager: ShortcutsManager(),
            authenticationManager: AuthenticationManager(),
            onboardingEventsHandler: onboardingEventsHandler,
            gleanUsageReportingMetricsService: GleanUsageReportingMetricsService(),
            themeManager: themeManager
        )
        mockUserDefaults.clear()

        // Ensure initial threshold is set
        mockUserDefaults.set(1, forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        bvc.requestReviewIfNecessary()
        XCTAssert(mockUserDefaults.integer(forKey: UIConstants.strings.userDefaultsLaunchThresholdKey) == 14)
        XCTAssert(mockUserDefaults.object(forKey: UIConstants.strings.userDefaultsLastReviewRequestDate) == nil)

        // Trigger first actual review request
        mockUserDefaults.set(15, forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        bvc.requestReviewIfNecessary()

        // Check second threshold and date are set
        XCTAssert(mockUserDefaults.integer(forKey: UIConstants.strings.userDefaultsLaunchThresholdKey) == 64)
        guard let prevDate = mockUserDefaults.object(forKey: UIConstants.strings.userDefaultsLastReviewRequestDate) as? Date else {
            XCTFail("userDefaultsLastReviewRequestDate not date")
            return
        }

        let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: prevDate, to: Date()).day ?? -1
        XCTAssert(daysSinceLastRequest == 0)

        // Trigger second review request with prevDate < 90 days (i.e. launch threshold should remain the same due to early return)
        mockUserDefaults.set(65, forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        bvc.requestReviewIfNecessary()
        XCTAssert(mockUserDefaults.integer(forKey: UIConstants.strings.userDefaultsLaunchThresholdKey) == 64)

        // Trigger actual second review
        mockUserDefaults.set(nil, forKey: UIConstants.strings.userDefaultsLastReviewRequestDate)
        bvc.requestReviewIfNecessary()
        XCTAssert(mockUserDefaults.integer(forKey: UIConstants.strings.userDefaultsLaunchThresholdKey) == 114)
    }
}

private class MockUserDefaults: UserDefaults {
    func clear() {
        removeObject(forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        removeObject(forKey: UIConstants.strings.userDefaultsLastReviewRequestDate)
        removeObject(forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        removeObject(forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)
    }
}
