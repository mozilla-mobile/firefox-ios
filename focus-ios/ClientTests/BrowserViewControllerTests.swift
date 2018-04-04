/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import XCTest
@testable import Firefox_Focus

class BrowserViewControllerTests: XCTestCase {
    private let mockUserDefaults = MockUserDefaults()

    func testShareButtonPreviouslyInGroup() {
        let bvc = BrowserViewController()
        mockUserDefaults.clear()
        mockUserDefaults.set(10, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        mockUserDefaults.set(true, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyOLD)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertTrue(shouldShow)
        
    }
    
    func testShareButtonPreviouslyOutGroup() {
        let bvc = BrowserViewController()
        mockUserDefaults.clear()
        mockUserDefaults.set(10, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        mockUserDefaults.set(false, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyOLD)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertTrue(shouldShow)
    }
    
    func testShareButtonHasNotHitEnoughTrackers() {
        let bvc = BrowserViewController()
        mockUserDefaults.clear()
        mockUserDefaults.set(9, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertFalse(shouldShow)
    }
    
    func testShareButtonInGroup() {
        let bvc = BrowserViewController()
        mockUserDefaults.clear()
        mockUserDefaults.set(10, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
        mockUserDefaults.set(true, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW)
        
        let shouldShow = bvc.shouldShowTrackerStatsShareButton(percent: 100, userDefaults: mockUserDefaults)
        XCTAssertTrue(shouldShow)
    }
    
    func testShareButtonOutGroup() {
        let bvc = BrowserViewController()
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
    }
}
