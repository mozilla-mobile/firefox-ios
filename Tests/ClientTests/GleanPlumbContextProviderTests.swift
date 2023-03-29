// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

class GleanPlumbContextProviderTests: XCTestCase {
    private var userDefaults: UserDefaultsInterface!
    private var contextProvider: GleanPlumbContextProvider!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        userDefaults = MockUserDefaults()
        contextProvider = GleanPlumbContextProvider()
        contextProvider.userDefaults = userDefaults
    }

    override func tearDown() {
        super.tearDown()
        userDefaults = nil
        contextProvider = nil
    }

    func testIsInactiveNewUser_noFirstAppUse() {
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_pastNotificationTime() {
        let timestamp = Date.now() - GleanPlumbContextProvider.Constant.activityReferencePeriod * 2
        userDefaults.set(timestamp, forKey: PrefsKeys.KeyFirstAppUse)
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_notUsedInSecond24Hours() {
        let timestamp = Date.now() - GleanPlumbContextProvider.Constant.inactivityPeriod * UInt64(0.5)
        userDefaults.set(timestamp, forKey: PrefsKeys.KeyFirstAppUse)
        userDefaults.set(true, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
        XCTAssertTrue(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_usedInSecond24Hours() {
        let timestamp = Date.now() - GleanPlumbContextProvider.Constant.inactivityPeriod * UInt64(1.5)
        userDefaults.set(timestamp, forKey: PrefsKeys.KeyFirstAppUse)
        userDefaults.set(true, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }
}
