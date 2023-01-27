// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UserNotifications
@testable import Client

class MockUserNotificationCenter: UserNotificationCenterProtocol {
    var pendingRequests = [UNNotificationRequest]()

    var getSettingsWasCalled = false
    func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        getSettingsWasCalled = true

        // calling UNUserNotificationCenter as UNNotificationSettings can't be created otherwise
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: completionHandler)
    }

    var requestAuthorizationWasCalled = false
    var requestAuthorizationResult: (Bool, Error?) = (true, nil)
    func requestAuthorization(options: UNAuthorizationOptions,
                              completionHandler: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationWasCalled = true
        completionHandler(requestAuthorizationResult.0, requestAuthorizationResult.1)
    }

    var addWasCalled = false
    func add(_ request: UNNotificationRequest,
             withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        addWasCalled = true
    }

    var getPendingRequestsWasCalled = false
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        getPendingRequestsWasCalled = true
        completionHandler(pendingRequests)
    }

    var getPendingRequestsWithIdWasCalled = false
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        getPendingRequestsWithIdWasCalled = true
        pendingRequests.removeAll(where: { identifiers.contains($0.identifier) })
    }

    var removeAllPendingRequestsWasCalled = false
    func removeAllPendingNotificationRequests() {
        removeAllPendingRequestsWasCalled = true
        pendingRequests.removeAll()
    }

    var getDeliveredWasCalled = false
    func getDeliveredNotifications(completionHandler: @escaping ([UNNotification]) -> Void) {
        getDeliveredWasCalled = true
        completionHandler([UNNotification]())
    }

    var removeDeliveredWithIdsWasCalled = false
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredWithIdsWasCalled = true
    }

    var removeAllDeliveredWasCalled = false
    func removeAllDeliveredNotifications() {
        removeAllDeliveredWasCalled = true
    }
}
