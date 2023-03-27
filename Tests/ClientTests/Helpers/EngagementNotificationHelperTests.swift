// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Common
@testable import Client

class EngagementNotificationHelperTests: XCTestCase {
    private var engagementNotificationHelper: EngagementNotificationHelper!
    private var notificationManager: MockNotificationManager!
    private var profile: MockProfile!
    private var userDefaults: UserDefaultsInterface!

    override func setUp() {
        super.setUp()
        notificationManager = MockNotificationManager()
        profile = MockProfile(databasePrefix: "EngagementNotificationHelper_tests")
        userDefaults = MockUserDefaults()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        engagementNotificationHelper = EngagementNotificationHelper(notificationManager: notificationManager,
                                                                    userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()
        engagementNotificationHelper = nil
        profile = nil
        notificationManager = nil
    }

    func testSchedule_noPermission() {
        notificationManager.hasPermission = false
        engagementNotificationHelper.schedule()
        XCTAssertFalse(notificationManager.scheduleWithDateWasCalled)
        XCTAssertFalse(notificationManager.removePendingNotificationsWithIdWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, 0)
    }

    func testSchedule_noFirstAppUse() {
        engagementNotificationHelper.schedule()
        XCTAssertFalse(notificationManager.scheduleWithDateWasCalled)
        XCTAssertFalse(notificationManager.removePendingNotificationsWithIdWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, 0)
    }

    func testSchedule_pastNotificationTime() {
        let timestamp = Date.now() - EngagementNotificationHelper.Constant.timeUntilNotification * 2
        userDefaults.set(timestamp, forKey: PrefsKeys.KeyFirstAppUse)
        engagementNotificationHelper.schedule()
        XCTAssertFalse(notificationManager.scheduleWithDateWasCalled)
        XCTAssertFalse(notificationManager.removePendingNotificationsWithIdWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, 0)
    }

    func testSchedule_notUsedInSecond24Hours() {
        let timestamp = Date.now() - EngagementNotificationHelper.Constant.twentyFourHours * UInt64(0.5)
        userDefaults.set(timestamp, forKey: PrefsKeys.KeyFirstAppUse)
        userDefaults.set(true, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
        engagementNotificationHelper.schedule()
        XCTAssertTrue(notificationManager.scheduleWithDateWasCalled)
        XCTAssertFalse(notificationManager.removePendingNotificationsWithIdWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, 1)
    }

    func testSchedule_usedInSecond24Hours() {
        let timestamp = Date.now() - EngagementNotificationHelper.Constant.twentyFourHours * UInt64(1.5)
        userDefaults.set(timestamp, forKey: PrefsKeys.KeyFirstAppUse)
        userDefaults.set(true, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
        engagementNotificationHelper.schedule()
        XCTAssertFalse(notificationManager.scheduleWithDateWasCalled)
        XCTAssertTrue(notificationManager.removePendingNotificationsWithIdWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, -1)
    }

    func testSchedule_userPrefOff() {
        let timestamp = Date.now() - EngagementNotificationHelper.Constant.twentyFourHours * UInt64(0.5)
        userDefaults.set(timestamp, forKey: PrefsKeys.KeyFirstAppUse)
        userDefaults.set(false, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
        engagementNotificationHelper.schedule()
        XCTAssertFalse(notificationManager.scheduleWithDateWasCalled)
        XCTAssertFalse(notificationManager.removePendingNotificationsWithIdWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, 0)
    }

    func testSchedule_userPrefOn() {
        let timestamp = Date.now() - EngagementNotificationHelper.Constant.twentyFourHours * UInt64(0.5)
        userDefaults.set(timestamp, forKey: PrefsKeys.KeyFirstAppUse)
        userDefaults.set(true, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
        engagementNotificationHelper.schedule()
        XCTAssertTrue(notificationManager.scheduleWithDateWasCalled)
        XCTAssertFalse(notificationManager.removePendingNotificationsWithIdWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, 1)
    }
}
