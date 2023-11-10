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
        userDefaults.set(Date.now(), forKey: PrefsKeys.Session.Last)
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_noLastSession() {
        userDefaults.set(Date.now(), forKey: PrefsKeys.Session.FirstAppUse)
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_beforeNotificationTime() {
        let firstAppUse = Date.now() - timestampMultiplied(GleanPlumbContextProvider.Constant.activityReferencePeriod, 0.9)
        userDefaults.set(firstAppUse, forKey: PrefsKeys.Session.FirstAppUse)

        let lastSession = firstAppUse + timestampMultiplied(GleanPlumbContextProvider.Constant.inactivityPeriod, 0.9)
        userDefaults.set(lastSession, forKey: PrefsKeys.Session.Last)
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_usedInFirst24Hours() {
        let firstAppUse = Date.now() - timestampMultiplied(GleanPlumbContextProvider.Constant.activityReferencePeriod, 1.1)
        userDefaults.set(firstAppUse, forKey: PrefsKeys.Session.FirstAppUse)

        let lastSession = firstAppUse + timestampMultiplied(GleanPlumbContextProvider.Constant.inactivityPeriod, 0.9)
        userDefaults.set(lastSession, forKey: PrefsKeys.Session.Last)
        XCTAssertTrue(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_usedInSecond24Hours() {
        let firstAppUse = Date.now() - timestampMultiplied(GleanPlumbContextProvider.Constant.activityReferencePeriod, 1.1)
        userDefaults.set(firstAppUse, forKey: PrefsKeys.Session.FirstAppUse)

        let lastSession = firstAppUse + timestampMultiplied(GleanPlumbContextProvider.Constant.inactivityPeriod, 1.1)
        userDefaults.set(lastSession, forKey: PrefsKeys.Session.Last)
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }

    // MARK: Helpers
    private func timestampMultiplied(_ timestamp: Timestamp, _ multiplier: CGFloat) -> Timestamp {
        let result = CGFloat(timestamp) * multiplier
        return UInt64(result)
    }
}
