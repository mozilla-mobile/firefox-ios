/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest
@testable import Client

private class MockDataObserverDelegate: DataObserverDelegate {
    var didInvalidateCount = 0
    var willInvalidateCount = 0
    var highlightsRefreshCount = 0
    var topSitesRefreshCount = 0

    func didInvalidateDataSources(refresh forced: Bool, highlightsRefreshed: Bool, topSitesRefreshed: Bool) {
        didInvalidateCount += 1
        if highlightsRefreshed {
            highlightsRefreshCount += 1
        }
        
        if topSitesRefreshed {
            topSitesRefreshCount += 1
        }
    }

    func willInvalidateDataSources(forceHighlights highlights: Bool, forceTopSites topSites: Bool) {
        willInvalidateCount += 1
    }
}

class PanelDataObserversTests: XCTestCase {
    func testActivityStreamDelegates() {
        let profile = MockProfile()
        let observer = ActivityStreamDataObserver(profile: profile)
        let delegate = MockDataObserverDelegate()
        observer.delegate = delegate

        NotificationCenter.default.post(name: NotificationFirefoxAccountChanged,
                                        object: nil)
        NotificationCenter.default.post(name: NotificationProfileDidFinishSyncing,
                                        object: nil)
        NotificationCenter.default.post(name: NotificationPrivateDataClearedHistory,
                                        object: nil)

        waitForCondition(timeout: 5) { delegate.didInvalidateCount == 3 &&  delegate.willInvalidateCount == 3 }
    }
    
    func testHighlightsCacheInvalidation20Min() {
        let profile = MockProfile()
        let observer = ActivityStreamDataObserver(profile: profile)
        let delegate = MockDataObserverDelegate()
        observer.delegate = delegate
        
        // Set to 20min since refresh
        profile.prefs.setLong(Date.now() - (OneMinuteInMilliseconds * 20), forKey: PrefsKeys.ASLastInvalidation)
        observer.refreshIfNeeded(forceHighlights: false, forceTopSites: false)
        waitForCondition(timeout: 5) { delegate.highlightsRefreshCount == 1 }
    }
    
    func testHighlightEmptyCache() {
        let profile = MockProfile()
        let observer = ActivityStreamDataObserver(profile: profile)
        let delegate = MockDataObserverDelegate()
        observer.delegate = delegate
        
        // Set to no validation key
        profile.prefs.removeObjectForKey(PrefsKeys.ASLastInvalidation)
        observer.refreshIfNeeded(forceHighlights: false, forceTopSites: false)
        waitForCondition(timeout: 5) { delegate.highlightsRefreshCount == 1 }
    }
    
    func testHighlightActiveCache() {
        let profile = MockProfile()
        let observer = ActivityStreamDataObserver(profile: profile)
        let delegate = MockDataObserverDelegate()
        observer.delegate = delegate
        
        // Set to 10min since refresh
        profile.prefs.setLong(Date.now() - (OneMinuteInMilliseconds * 10), forKey: PrefsKeys.ASLastInvalidation)
        observer.refreshIfNeeded(forceHighlights: false, forceTopSites: false)
        waitForCondition(timeout: 5) { delegate.didInvalidateCount == 1 && delegate.highlightsRefreshCount == 0 }
    }
}
