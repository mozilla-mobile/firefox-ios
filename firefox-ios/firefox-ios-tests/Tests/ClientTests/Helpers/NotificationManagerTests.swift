// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class NotificationManagerTests: XCTestCase {
    private var center: MockUserNotificationCenter!
    private var notificationManager: NotificationManager!

    override func setUp() {
        super.setUp()
        center = MockUserNotificationCenter()
        let telemetry = NotificationManagerTelemetry(gleanWrapper: MockGleanWrapper())
        notificationManager = NotificationManager(center: center, telemetry: telemetry)
    }

    override func tearDown() {
        center = nil
        notificationManager = nil
        super.tearDown()
    }

    func testRequestAuthorization() {
        notificationManager.requestAuthorization { [center] (granted, error) in
            XCTAssertTrue(granted)
            XCTAssertTrue(center?.requestAuthorizationWasCalled ?? false)
        }
    }

    func testGetNotificationSettings() async {
        _ = await notificationManager.getNotificationSettings()
        XCTAssertTrue(self.center.getSettingsWasCalled)
    }

    func testScheduleInterval() {
        notificationManager.schedule(title: "Title",
                                     body: "Body",
                                     id: "test-id",
                                     interval: 50)
        XCTAssertTrue(center.addWasCalled)
    }

    func testFindDeliveredNotificationForId() async {
        _ = await notificationManager.findDeliveredNotificationForId(id: "id1")
        XCTAssertTrue(self.center.getDeliveredWasCalled)
    }

    func testCloseRemoteTabNotification() {
        notificationManager.schedule(title: "Title",
                                     body: "Body",
                                     id: "id1",
                                     categoryIdentifier: NotificationCloseTabs.notificationCategoryId,
                                     interval: 50)

        XCTAssertTrue(center.addWasCalled)
        XCTAssertEqual(center.addedRequest?.content.categoryIdentifier,
                       NotificationCloseTabs.notificationCategoryId)
    }
}
