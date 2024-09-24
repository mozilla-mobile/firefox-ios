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
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        userDefaults = MockUserDefaults()
        profile = MockProfile()
        contextProvider = GleanPlumbContextProvider(profile: profile)
        contextProvider.userDefaults = userDefaults
    }

    override func tearDown() {
        profile = nil
        userDefaults = nil
        contextProvider = nil
        super.tearDown()
    }

    func testNumberOfLaunches_withFirstLaunch() {
        profile.prefs.setInt(1, forKey: PrefsKeys.Session.Count)
        let context = contextProvider.createAdditionalDeviceContext()
        let numberOfAppLaunches = context["number_of_app_launches"] as? Int32
        XCTAssertEqual(numberOfAppLaunches, 1)
    }

    func testNumberOfLaunches_withSecondLaunch() {
        profile.prefs.setInt(2, forKey: PrefsKeys.Session.Count)
        let context = contextProvider.createAdditionalDeviceContext()
        let numberOfAppLaunches = context["number_of_app_launches"] as? Int32
        XCTAssertEqual(numberOfAppLaunches, 2)
    }

    func testCreateAdditionalDeviceContext_withNumberOfSyncedDevices() {
        profile.prefs.setInt(2, forKey: PrefsKeys.Sync.numberOfSyncedDevices)
        let context = contextProvider.createAdditionalDeviceContext()
        let numberOfSyncedDevices = context["number_of_sync_devices"] as? Int32
        XCTAssertEqual(numberOfSyncedDevices, 2)
    }

    func testCreateAdditionalDeviceContext_withSignedInCheck_returnTrue() {
        profile.prefs.setBool(true, forKey: PrefsKeys.Sync.signedInFxaAccount)
        let context = contextProvider.createAdditionalDeviceContext()
        let signedInFxaAccountStatus = context["is_fxa_signed_in"] as? Bool
        XCTAssertEqual(signedInFxaAccountStatus, true)
    }

    func testCreateAdditionalDeviceContext_withSignedInCheck_returnFalse() {
        profile.prefs.setBool(false, forKey: PrefsKeys.Sync.signedInFxaAccount)
        let context = contextProvider.createAdditionalDeviceContext()
        let signedInFxaAccountStatus = context["is_fxa_signed_in"] as? Bool
        XCTAssertEqual(signedInFxaAccountStatus, false)
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
        let firstAppUse = Date.now() - timestampMultiplied(
            GleanPlumbContextProvider.Constant.activityReferencePeriod,
            0.9
        )
        userDefaults.set(firstAppUse, forKey: PrefsKeys.Session.FirstAppUse)

        let lastSession = firstAppUse + timestampMultiplied(
            GleanPlumbContextProvider.Constant.inactivityPeriod,
            0.9
        )
        userDefaults.set(lastSession, forKey: PrefsKeys.Session.Last)
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_usedInFirst24Hours() {
        let firstAppUse = Date.now() - timestampMultiplied(
            GleanPlumbContextProvider.Constant.activityReferencePeriod,
            1.1
        )
        userDefaults.set(firstAppUse, forKey: PrefsKeys.Session.FirstAppUse)

        let lastSession = firstAppUse + timestampMultiplied(
            GleanPlumbContextProvider.Constant.inactivityPeriod,
            0.9
        )
        userDefaults.set(lastSession, forKey: PrefsKeys.Session.Last)
        XCTAssertTrue(contextProvider.isInactiveNewUser)
    }

    func testIsInactiveNewUser_usedInSecond24Hours() {
        let firstAppUse = Date.now() - timestampMultiplied(
            GleanPlumbContextProvider.Constant.activityReferencePeriod,
            1.1
        )
        userDefaults.set(firstAppUse, forKey: PrefsKeys.Session.FirstAppUse)

        let lastSession = firstAppUse + timestampMultiplied(
            GleanPlumbContextProvider.Constant.inactivityPeriod,
            1.1
        )
        userDefaults.set(lastSession, forKey: PrefsKeys.Session.Last)
        XCTAssertFalse(contextProvider.isInactiveNewUser)
    }

    // MARK: Helpers
    private func timestampMultiplied(_ timestamp: Timestamp, _ multiplier: CGFloat) -> Timestamp {
        let result = CGFloat(timestamp) * multiplier
        return UInt64(result)
    }
}
