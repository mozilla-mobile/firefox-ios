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
        notificationManager = NotificationManager(center: center)
    }

    func testRequestAuthorization() {
        let expectation = self.expectation(description: "notification manager")
        notificationManager.requestAuthorization { (granted, error) in
            XCTAssertTrue(granted)
            XCTAssertTrue(self.center.requestAuthorizationWasCalled)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testGetNotificationSettings() {
        let expectation = self.expectation(description: "notification manager")
        notificationManager.getNotificationSettings { settings in
            XCTAssertTrue(self.center.getSettingsWasCalled)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testScheduleDate() {
        notificationManager.schedule(title: "Title",
                                     body: "Body",
                                     id: "test-id",
                                     date: Date.tomorrow)
        XCTAssertTrue(center.addWasCalled)
    }

    func testScheduleInterval() {
        notificationManager.schedule(title: "Title",
                                     body: "Body",
                                     id: "test-id",
                                     interval: 50)
        XCTAssertTrue(center.addWasCalled)
    }

    func testFindDeliveredNotifications() {
        let expectation = self.expectation(description: "notification manager")
        notificationManager.findDeliveredNotifications { notifications in
            XCTAssertTrue(self.center.getDeliveredWasCalled)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testFindDeliveredNotificationForId() {
        let expectation = self.expectation(description: "notification manager")
        notificationManager.findDeliveredNotificationForId(id: "id1") { notifications in
            XCTAssertTrue(self.center.getDeliveredWasCalled)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testRemoveAllPendingNotifications() {
        let notification1 = buildRequest(title: "title", body: "body", id: "id1")
        let notification2 = buildRequest(title: "title", body: "body", id: "id2")
        center.pendingRequests = [notification1, notification2]

        notificationManager.removeAllPendingNotifications()
        XCTAssertTrue(self.center.removeAllPendingRequestsWasCalled)
        XCTAssertEqual(self.center.pendingRequests.count, 0)
    }

    func testRemovePendingNotificationsWithId() {
        let notification1 = buildRequest(title: "title", body: "body", id: "id1")
        let notification2 = buildRequest(title: "title", body: "body", id: "id2")
        center.pendingRequests = [notification1, notification2]

        notificationManager.removePendingNotificationsWithId(ids: ["id1"])
        XCTAssertTrue(self.center.getPendingRequestsWithIdWasCalled)
        XCTAssertEqual(self.center.pendingRequests.count, 1)
    }

    // MARK: - Helpers

    private func buildRequest(title: String, body: String, id: String) -> UNNotificationRequest {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.sound = UNNotificationSound.default
        let request = UNNotificationRequest(identifier: id,
                                            content: notificationContent,
                                            trigger: nil)
        return request
    }
}
