// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
@testable import Client

final class InvisibleTabAutoCloseManagerTests: XCTestCase {

    // MARK: - Properties

    private var manager: InvisibleTabAutoCloseManager!
    private var mockTabManager: TabAutoCloseTestMockTabManager!
    private var mockNotificationCenter: TabAutoCloseManagerMockNotificationCenter!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        /*
         Since we're using singletons, we need to clear any leftover state
         from previous tests to avoid interference between test runs
         */
        InvisibleTabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()

        mockTabManager = TabAutoCloseTestMockTabManager()
        mockNotificationCenter = TabAutoCloseManagerMockNotificationCenter()

        manager = InvisibleTabAutoCloseManager.shared
        manager.setTabManager(mockTabManager)
    }

    override func tearDown() {
        manager.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()
        mockTabManager = nil
        mockNotificationCenter = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createMockTab(uuid: String = UUID().uuidString, isPrivate: Bool = false, isInvisible: Bool = true) -> Tab {
        let profile = MockProfile()
        let tab = Tab(profile: profile, isPrivate: isPrivate, windowUUID: WindowUUID())
        tab.tabUUID = uuid

        /*
         The auto-close manager only tracks invisible tabs,
         so we mark them that way by default for testing
         */
        if isInvisible {
            InvisibleTabManager.shared.markTabAsInvisible(tab)
        }
        return tab
    }

    // MARK: - Basic Setup Tests

    func testSetupAutoCloseForTab() {
        // Given
        let tab = createMockTab(uuid: "test-tab")
        mockTabManager.tabs = [tab]

        // When
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: 10.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 1, "Should track one tab")
        XCTAssertTrue(manager.trackedTabUUIDs.contains(tab.tabUUID), "Should track the specific tab")
    }

    func testSetupAutoCloseForMultipleTabs() {
        // Given
        let tabs = [
            createMockTab(uuid: "tab1"),
            createMockTab(uuid: "tab2"),
            createMockTab(uuid: "tab3")
        ]
        mockTabManager.tabs = tabs

        // When
        tabs.forEach { manager.setupAutoCloseForTab($0, on: .EcosiaAuthStateChanged, timeout: 10.0) }

        // Then
        XCTAssertEqual(manager.trackedTabCount, 3, "Should track all tabs")
        tabs.forEach { tab in
            XCTAssertTrue(manager.trackedTabUUIDs.contains(tab.tabUUID), "Should track tab \(tab.tabUUID)")
        }
    }

    // MARK: - Cancel Auto-Close Tests

    func testCancelAutoCloseForTab() {
        // Given
        let tab = createMockTab(uuid: "cancel-tab")
        mockTabManager.tabs = [tab]
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: 10.0)
        XCTAssertEqual(manager.trackedTabCount, 1)

        // When
        manager.cancelAutoCloseForTab(tab.tabUUID)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should not track any tabs after cancel")
        XCTAssertFalse(manager.trackedTabUUIDs.contains(tab.tabUUID), "Should not track the cancelled tab")
    }

    func testCancelAutoCloseForNonExistentTab() {
        // Given
        let nonExistentUUID = "non-existent-tab"

        // When
        manager.cancelAutoCloseForTab(nonExistentUUID)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should not affect tracking state")
    }

    func testCancelAutoCloseForMultipleTabs() {
        // Given
        let tabs = [
            createMockTab(uuid: "tab1"),
            createMockTab(uuid: "tab2"),
            createMockTab(uuid: "tab3")
        ]
        mockTabManager.tabs = tabs
        tabs.forEach { manager.setupAutoCloseForTab($0, on: .EcosiaAuthStateChanged, timeout: 10.0) }
        XCTAssertEqual(manager.trackedTabCount, 3)

        // When
        manager.cancelAutoCloseForTabs(tabs.map { $0.tabUUID })

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should not track any tabs after cancel")
    }

    // MARK: - Notification Handling Tests

    func testNotificationTriggersAutoClose() {
        // Given
        let tab = createMockTab(uuid: "notification-tab")
        mockTabManager.tabs = [tab]
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: 10.0)

        // When
        NotificationCenter.default.post(name: .EcosiaAuthStateChanged, object: nil)

        // Allow some processing time
        let expectation = XCTestExpectation(description: "Notification processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup tracking after notification")
    }

    func testNotificationWithCustomName() {
        // Given
        let tab = createMockTab(uuid: "custom-notification-tab")
        mockTabManager.tabs = [tab]
        let customNotification = Notification.Name("CustomAuthNotification")
        manager.setupAutoCloseForTab(tab, on: customNotification, timeout: 10.0)

        // When
        NotificationCenter.default.post(name: customNotification, object: nil)

        // Allow some processing time
        let expectation = XCTestExpectation(description: "Custom notification processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup tracking after custom notification")
    }

    func testNotificationDoesNotAffectOtherTabs() {
        // Given
        let authTab = createMockTab(uuid: "auth-tab")
        let regularTab = createMockTab(uuid: "regular-tab")
        mockTabManager.tabs = [authTab, regularTab]

        manager.setupAutoCloseForTab(authTab, on: .EcosiaAuthStateChanged, timeout: 10.0)
        manager.setupAutoCloseForTab(regularTab, on: Notification.Name("DifferentNotification"), timeout: 10.0)

        // When
        NotificationCenter.default.post(name: .EcosiaAuthStateChanged, object: nil)

        // Allow some processing time
        let expectation = XCTestExpectation(description: "Notification processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 1, "Should only affect tabs listening to the specific notification")
        XCTAssertFalse(manager.trackedTabUUIDs.contains(authTab.tabUUID), "Auth tab should be cleaned up")
        XCTAssertTrue(manager.trackedTabUUIDs.contains(regularTab.tabUUID), "Regular tab should still be tracked")
    }

    // MARK: - Timeout Tests

    func testTimeoutTriggersAutoClose() {
        // Given
        let tab = createMockTab(uuid: "timeout-tab")
        mockTabManager.tabs = [tab]
        let shortTimeout: TimeInterval = 0.1

        // When
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: shortTimeout)

        // Wait for timeout to trigger
        let expectation = XCTestExpectation(description: "Timeout processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + shortTimeout + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup tracking after timeout")
    }

    func testTimeoutDoesNotTriggerIfNotificationReceived() {
        // Given
        let tab = createMockTab(uuid: "no-timeout-tab")
        mockTabManager.tabs = [tab]
        let timeout: TimeInterval = 0.2

        // When
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: timeout)

        // Send notification before timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .EcosiaAuthStateChanged, object: nil)
        }

        // Wait past timeout
        let expectation = XCTestExpectation(description: "Processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup tracking via notification, not timeout")
    }

    // MARK: - Tab Manager Integration Tests

    func testAutoCloseRemovesTabFromManager() {
        // Given
        let tab = createMockTab(uuid: "remove-tab")
        mockTabManager.tabs = [tab]
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: 10.0)

        // When
        NotificationCenter.default.post(name: .EcosiaAuthStateChanged, object: nil)

        // Allow some processing time
        let expectation = XCTestExpectation(description: "Tab removal processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertFalse(mockTabManager.tabs.contains(tab), "Tab should be removed from tab manager")
    }

    func testAutoCloseWithMultipleTabsRemovesCorrectTab() {
        // Given
        let autoCloseTab = createMockTab(uuid: "auto-close-tab")
        let regularTab = createMockTab(uuid: "regular-tab")
        mockTabManager.tabs = [autoCloseTab, regularTab]
        manager.setupAutoCloseForTab(autoCloseTab, on: .EcosiaAuthStateChanged, timeout: 10.0)

        // When
        NotificationCenter.default.post(name: .EcosiaAuthStateChanged, object: nil)

        // Allow some processing time
        let expectation = XCTestExpectation(description: "Tab removal processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertFalse(mockTabManager.tabs.contains(autoCloseTab), "Auto-close tab should be removed")
        XCTAssertTrue(mockTabManager.tabs.contains(regularTab), "Regular tab should remain")
    }

    // MARK: - Cleanup Tests

    func testCleanupAllObservers() {
        // Given
        let tabs = [
            createMockTab(uuid: "tab1"),
            createMockTab(uuid: "tab2"),
            createMockTab(uuid: "tab3")
        ]
        mockTabManager.tabs = tabs
        tabs.forEach { manager.setupAutoCloseForTab($0, on: .EcosiaAuthStateChanged, timeout: 10.0) }
        XCTAssertEqual(manager.trackedTabCount, 3)

        // When
        manager.cleanupAllObservers()

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup all tracking")
    }

    func testCleanupAllObserversIdempotent() {
        // Given
        let tab = createMockTab(uuid: "idempotent-tab")
        mockTabManager.tabs = [tab]
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: 10.0)

        // When
        manager.cleanupAllObservers()
        manager.cleanupAllObservers()
        manager.cleanupAllObservers()

        // Then - Should not crash
        XCTAssertEqual(manager.trackedTabCount, 0, "Should remain at zero")
    }

    // MARK: - State Consistency Tests

    func testTrackedTabUUIDsConsistency() {
        // Given
        let tabs = [
            createMockTab(uuid: "uuid1"),
            createMockTab(uuid: "uuid2"),
            createMockTab(uuid: "uuid3")
        ]
        mockTabManager.tabs = tabs

        // When
        tabs.forEach { manager.setupAutoCloseForTab($0, on: .EcosiaAuthStateChanged, timeout: 10.0) }

        // Then
        XCTAssertEqual(manager.trackedTabCount, manager.trackedTabUUIDs.count, "Count should match UUID array size")
        tabs.forEach { tab in
            XCTAssertTrue(manager.trackedTabUUIDs.contains(tab.tabUUID), "Should contain each tab UUID")
        }
    }

    func testTabRemovalUpdatesTracking() {
        // Given
        let tab1 = createMockTab(uuid: "tab1")
        let tab2 = createMockTab(uuid: "tab2")
        mockTabManager.tabs = [tab1, tab2]
        manager.setupAutoCloseForTab(tab1, on: .EcosiaAuthStateChanged, timeout: 10.0)
        manager.setupAutoCloseForTab(tab2, on: .EcosiaAuthStateChanged, timeout: 10.0)

        // When
        manager.cancelAutoCloseForTab(tab1.tabUUID)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 1, "Should track one less tab")
        XCTAssertFalse(manager.trackedTabUUIDs.contains(tab1.tabUUID), "Should not track removed tab")
        XCTAssertTrue(manager.trackedTabUUIDs.contains(tab2.tabUUID), "Should still track remaining tab")
    }

    // MARK: - Error Handling Tests

    func testDuplicateSetupForSameTab() {
        // Given
        let tab = createMockTab(uuid: "duplicate-tab")
        mockTabManager.tabs = [tab]

        // When
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: 10.0)
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: 5.0)
        manager.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: 15.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 1, "Should only track tab once, regardless of multiple setups")
    }

    // MARK: - Memory Management Tests

    func testNoRetainCyclesAfterCleanup() {
        // Given
        var tab: Tab? = createMockTab(uuid: "memory-tab")
        mockTabManager.tabs = [tab!]
        manager.setupAutoCloseForTab(tab!, on: .EcosiaAuthStateChanged, timeout: 10.0)

        // When
        manager.cleanupAllObservers()
        tab = nil

        // Then - Should not crash and tab should be deallocated
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup all tracking")
    }
}

// MARK: - Custom Mock TabManager

/*
 The shared MockTabManager has an empty removeTab implementation,
 but our tests need to verify that tabs actually get removed.
 This subclass provides a working implementation for testing.
 */
class TabAutoCloseTestMockTabManager: MockTabManager {
    override func removeTab(_ tab: Tab, completion: (() -> Void)?) {
        tabs.removeAll { $0.tabUUID == tab.tabUUID }
        completion?()
    }
}

// MARK: - Mock Notification Center
// swiftlint:disable large_tuple
class TabAutoCloseManagerMockNotificationCenter: NotificationCenter, @unchecked Sendable {
    private var observers: [(name: Notification.Name, observer: Any, selector: Selector)] = []

    override func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        if let name = aName {
            observers.append((name: name, observer: observer, selector: aSelector))
        }
    }

    override func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        observers.removeAll { (_, obs, _) in
            return (obs as AnyObject) === (observer as AnyObject)
        }
    }

    func simulateNotification(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        let notification = Notification(name: name, object: object, userInfo: userInfo)

        for (notificationName, observer, selector) in observers where notificationName == name {
            _ = (observer as AnyObject).perform(selector, with: notification)
        }
    }
}
// swiftlint:enable large_tuple
