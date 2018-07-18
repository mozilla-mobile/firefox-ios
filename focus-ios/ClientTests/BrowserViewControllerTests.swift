/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class BrowserViewControllerTests: XCTestCase {
    private let mockUserDefaults = MockUserDefaults()
    
    class TestAppSplashController: AppSplashController {
        var splashView = UIView()
        func toggleSplashView(hide: Bool) {}
    }
    
    func testRequestReviewThreshold() {
        let bvc = BrowserViewController(appSplashController: TestAppSplashController())
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
            XCTFail()
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

    func testShareButtonPreviouslyInGroup() {
        let bvc = BrowserViewController(appSplashController: TestAppSplashController())
        mockUserDefaults.clear()
        mockUserDefaults.set(10, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        mockUserDefaults.set(true, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyOLD)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertTrue(shouldShow)
        
    }
    
    func testShareButtonPreviouslyOutGroup() {
        let bvc = BrowserViewController(appSplashController: TestAppSplashController())
        mockUserDefaults.clear()
        mockUserDefaults.set(10, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        mockUserDefaults.set(false, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyOLD)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertTrue(shouldShow)
    }
    
    func testShareButtonHasNotHitEnoughTrackers() {
        let bvc = BrowserViewController(appSplashController: TestAppSplashController())
        mockUserDefaults.clear()
        mockUserDefaults.set(9, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertFalse(shouldShow)
    }
    
    func testShareButtonInGroup() {
        let bvc = BrowserViewController(appSplashController: TestAppSplashController())
        mockUserDefaults.clear()
        mockUserDefaults.set(10, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        mockUserDefaults.set(true, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertTrue(shouldShow)
    }
    
    func testShareButtonOutGroup() {
        let bvc = BrowserViewController(appSplashController: TestAppSplashController())
        mockUserDefaults.clear()
        mockUserDefaults.set(10, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        mockUserDefaults.set(false, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertFalse(shouldShow)
    }
}

fileprivate class MockUserDefaults: UserDefaults {
    func clear() {
        removeObject(forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW)
        removeObject(forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyOLD)
        removeObject(forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        removeObject(forKey: UIConstants.strings.userDefaultsLastReviewRequestDate)
        removeObject(forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        removeObject(forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)
    }
}
