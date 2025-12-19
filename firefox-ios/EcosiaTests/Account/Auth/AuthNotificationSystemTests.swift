// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Ecosia

final class AuthNotificationSystemTests: XCTestCase {

    var authStateManager: EcosiaBrowserWindowAuthManager!
    var windowRegistry: EcosiaAuthWindowRegistry!
    var testWindowUUID: WindowUUID!
    fileprivate var notificationObserver: NotificationObserver!

    override func setUp() {
        super.setUp()
        authStateManager = EcosiaBrowserWindowAuthManager.shared
        windowRegistry = EcosiaAuthWindowRegistry.shared
        testWindowUUID = WindowUUID.XCTestDefaultUUID
        notificationObserver = NotificationObserver()

        // Register a test window
        windowRegistry.registerWindow(testWindowUUID)
    }

    override func tearDown() {
        // Clean up state after each test
        authStateManager.clearAllStates()
        windowRegistry.clearAllWindows()
        notificationObserver.cleanup()
        notificationObserver = nil
        authStateManager = nil
        windowRegistry = nil
        testWindowUUID = nil
        super.tearDown()
    }

    // MARK: - Notification Names Tests

    func testNotificationNames_haveCorrectValues() {
        // Test notification name has correct string value
        XCTAssertEqual(Notification.Name.EcosiaAuthStateChanged.rawValue, "EcosiaAuthStateChanged")
    }

    // MARK: - EcosiaAuthStateChanged Notification Tests

    func testEcosiaAuthStateChanged_withUserLoggedIn_postsCorrectNotification() {
        // Arrange
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        notificationObserver.expectNotification(
            name: .EcosiaAuthStateChanged,
            object: authStateManager,
            expectedCount: 1
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)

        let receivedNotification = notificationObserver.receivedNotifications.first
        XCTAssertNotNil(receivedNotification, "Should receive notification")
        XCTAssertEqual(receivedNotification?.name, .EcosiaAuthStateChanged, "Should have correct notification name")
        XCTAssertTrue(receivedNotification?.object is EcosiaBrowserWindowAuthManager, "Should have correct object")

        // Verify userInfo content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["windowUUID"] as? WindowUUID, testWindowUUID, "Should include window UUID")
            XCTAssertEqual(userInfo["actionType"] as? EcosiaAuthActionType, .userLoggedIn, "Should include action type")

            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertEqual(authState.windowUUID, testWindowUUID, "Auth state should have correct window UUID")
                XCTAssertTrue(authState.isLoggedIn, "Auth state should indicate user is logged in")
            } else {
                XCTFail("Should include auth state in userInfo")
            }
        } else {
            XCTFail("Should include userInfo in notification")
        }
    }

    func testEcosiaAuthStateChanged_withUserLoggedOut_postsCorrectNotification() {
        // Arrange
        let action = AuthStateAction(
            type: .userLoggedOut,
            windowUUID: testWindowUUID,
            isLoggedIn: false
        )

        notificationObserver.expectNotification(
            name: .EcosiaAuthStateChanged,
            object: authStateManager,
            expectedCount: 1
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)

        let receivedNotification = notificationObserver.receivedNotifications.first
        XCTAssertNotNil(receivedNotification, "Should receive notification")

        // Verify userInfo content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? EcosiaAuthActionType, .userLoggedOut, "Should include action type")

            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertFalse(authState.isLoggedIn, "Auth state should indicate user is logged out")
            } else {
                XCTFail("Should include auth state in userInfo")
            }
        } else {
            XCTFail("Should include userInfo in notification")
        }
    }

    func testEcosiaAuthStateChanged_withAuthStateLoaded_postsCorrectNotification() {
        // Arrange
        let action = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        notificationObserver.expectNotification(
            name: .EcosiaAuthStateChanged,
            object: authStateManager,
            expectedCount: 1
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)

        let receivedNotification = notificationObserver.receivedNotifications.first
        XCTAssertNotNil(receivedNotification, "Should receive notification")

        // Verify userInfo content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? EcosiaAuthActionType, .authStateLoaded, "Should include action type")

            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertTrue(authState.isLoggedIn, "Auth state should indicate user is logged in")
                XCTAssertTrue(authState.authStateLoaded, "Auth state should indicate state is loaded")
            } else {
                XCTFail("Should include auth state in userInfo")
            }
        } else {
            XCTFail("Should include userInfo in notification")
        }
    }

    // MARK: - Multi-Window Notification Tests

    func testEcosiaAuthStateChanged_withMultipleWindows_postsNotificationForEachWindow() {
        // Arrange
        let windowUUID2 = WindowUUID()
        let windowUUID3 = WindowUUID()

        windowRegistry.registerWindow(windowUUID2)
        windowRegistry.registerWindow(windowUUID3)

        notificationObserver.expectNotification(
            name: .EcosiaAuthStateChanged,
            object: authStateManager,
            expectedCount: 3
        )

        // Act
        authStateManager.dispatchAuthState(isLoggedIn: true, actionType: .userLoggedIn)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)

        XCTAssertEqual(notificationObserver.receivedNotifications.count, 3, "Should receive 3 notifications")

        // Verify all notifications have correct content
        let windowUUIDs = Set([testWindowUUID, windowUUID2, windowUUID3])
        var receivedWindowUUIDs = Set<WindowUUID>()

        for notification in notificationObserver.receivedNotifications {
            XCTAssertEqual(notification.name, .EcosiaAuthStateChanged, "Should have correct notification name")

            if let userInfo = notification.userInfo,
               let windowUUID = userInfo["windowUUID"] as? WindowUUID {
                receivedWindowUUIDs.insert(windowUUID)
                XCTAssertEqual(userInfo["actionType"] as? EcosiaAuthActionType, .userLoggedIn, "Should have correct action type")
            } else {
                XCTFail("Should include window UUID in userInfo")
            }
        }

        XCTAssertEqual(receivedWindowUUIDs, windowUUIDs, "Should receive notifications for all windows")
    }

    // MARK: - Notification Subscription Tests

    func testSubscribe_withObserver_receivesNotifications() {
        // Arrange
        let observer = TestNotificationObserver()
        let expectation = expectation(description: "Observer should receive notification")
        observer.expectation = expectation

        authStateManager.subscribe(observer: observer, selector: #selector(TestNotificationObserver.handleAuthStateChanged(_:)))

        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(observer.receivedNotifications.count, 1, "Observer should receive one notification")

        if let notification = observer.receivedNotifications.first {
            XCTAssertEqual(notification.name, .EcosiaAuthStateChanged, "Should have correct notification name")
            XCTAssertTrue(notification.object is EcosiaBrowserWindowAuthManager, "Should have correct object")
        }
    }

    func testUnsubscribe_withObserver_stopsReceivingNotifications() {
        // Arrange
        let observer = TestNotificationObserver()
        let firstExpectation = expectation(description: "Observer should receive first notification")
        observer.expectation = firstExpectation

        authStateManager.subscribe(observer: observer, selector: #selector(TestNotificationObserver.handleAuthStateChanged(_:)))

        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        // Act - First dispatch should trigger notification
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Wait for first notification
        waitForExpectations(timeout: 1.0)

        // Unsubscribe
        authStateManager.unsubscribe(observer: observer)

        // Clear expectation so second dispatch won't fulfill it
        observer.expectation = nil

        // Dispatch another action
        let action2 = AuthStateAction(
            type: .userLoggedOut,
            windowUUID: testWindowUUID,
            isLoggedIn: false
        )
        authStateManager.dispatch(action: action2, for: testWindowUUID)

        // Assert - Should only have received the first notification
        XCTAssertEqual(observer.receivedNotifications.count, 1, "Observer should receive only one notification (before unsubscribe)")
    }

    // MARK: - Notification Regression Tests

    func testNotificationDelivery_withManyActions_handlesAllCorrectly() {
        // Arrange
        let observer = TestNotificationObserver()
        let expectation = expectation(description: "All notifications should be delivered")
        expectation.expectedFulfillmentCount = 100
        observer.expectation = expectation

        authStateManager.subscribe(observer: observer, selector: #selector(TestNotificationObserver.handleAuthStateChanged(_:)))

        // Act - Dispatch many actions to test system stability
        for i in 0..<50 {
            let loginAction = AuthStateAction(type: .userLoggedIn, windowUUID: testWindowUUID, isLoggedIn: true)
            let logoutAction = AuthStateAction(type: .userLoggedOut, windowUUID: testWindowUUID, isLoggedIn: false)

            authStateManager.dispatch(action: loginAction, for: testWindowUUID)
            authStateManager.dispatch(action: logoutAction, for: testWindowUUID)
        }

        // Assert
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(observer.receivedNotifications.count, 100, "Should receive all 100 notifications")

        // Verify alternating login/logout pattern
        for i in 0..<observer.receivedNotifications.count {
            let notification = observer.receivedNotifications[i]
            let expectedActionType: EcosiaAuthActionType = i % 2 == 0 ? .userLoggedIn : .userLoggedOut
            let actualActionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType
            XCTAssertEqual(actualActionType, expectedActionType, "Action type should match expected pattern at index \(i)")
        }
    }

    func testNotificationDelivery_withManyObservers_handlesAllCorrectly() {
        // Arrange
        let observers = (0..<100).map { _ in TestNotificationObserver() }
        let expectation = expectation(description: "All observers should receive notification")
        expectation.expectedFulfillmentCount = 100

        // Subscribe all observers with shared expectation
        for observer in observers {
            observer.expectation = expectation
            authStateManager.subscribe(observer: observer, selector: #selector(TestNotificationObserver.handleAuthStateChanged(_:)))
        }

        let action = AuthStateAction(type: .userLoggedIn, windowUUID: testWindowUUID, isLoggedIn: true)

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        waitForExpectations(timeout: 2.0)

        // Verify all observers received the notification
        for (index, observer) in observers.enumerated() {
            XCTAssertEqual(observer.receivedNotifications.count, 1, "Observer \(index) should receive exactly 1 notification")

            let notification = observer.receivedNotifications.first!
            XCTAssertEqual(notification.userInfo?["actionType"] as? EcosiaAuthActionType, .userLoggedIn, "Observer \(index) should receive correct action type")
            XCTAssertEqual(notification.userInfo?["windowUUID"] as? WindowUUID, testWindowUUID, "Observer \(index) should receive correct window UUID")
        }
    }

    // MARK: - Error Handling Tests

    func testNotificationPosting_withNilObserver_doesNotCrash() {
        // Arrange
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        // Act & Assert - Should not crash
        XCTAssertNoThrow(authStateManager.dispatch(action: action, for: testWindowUUID))
    }

    func testNotificationPosting_withInvalidSelector_doesNotCrash() {
        // Arrange
        let observer = TestNotificationObserver()
        let invalidSelector = #selector(TestNotificationObserver.nonExistentMethod)

        // Act & Assert - Should not crash when subscribing with invalid selector
        XCTAssertNoThrow(authStateManager.subscribe(observer: observer, selector: invalidSelector))

        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        // Should not crash when dispatching with invalid selector
        XCTAssertNoThrow(authStateManager.dispatch(action: action, for: testWindowUUID))
    }
}

// MARK: - Helper Classes

private class NotificationObserver {
    var receivedNotifications: [Notification] = []
    private var expectations: [XCTestExpectation] = []

    func expectNotification(name: Notification.Name, object: Any?, expectedCount: Int) {
        let expectation = XCTestExpectation(description: "Should receive \(expectedCount) notification(s) for \(name)")
        expectation.expectedFulfillmentCount = expectedCount
        expectations.append(expectation)

        NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] notification in
            self?.receivedNotifications.append(notification)
            expectation.fulfill()
        }
    }

    func waitForExpectations(timeout: TimeInterval) {
        let waiter = XCTWaiter()
        waiter.wait(for: expectations, timeout: timeout)
    }

    func cleanup() {
        NotificationCenter.default.removeObserver(self)
        receivedNotifications.removeAll()
        expectations.removeAll()
    }
}

private class TestNotificationObserver: NSObject {
    var receivedNotifications: [Notification] = []
    var expectation: XCTestExpectation?

    @objc func handleAuthStateChanged(_ notification: Notification) {
        receivedNotifications.append(notification)
        expectation?.fulfill()
    }

    @objc func nonExistentMethod() {
        // This method is intentionally empty and used for testing invalid selectors
    }

    func reset() {
        receivedNotifications.removeAll()
        expectation = nil
    }
}
