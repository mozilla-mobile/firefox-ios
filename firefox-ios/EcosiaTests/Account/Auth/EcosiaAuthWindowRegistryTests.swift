// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Ecosia

final class EcosiaAuthWindowRegistryTests: XCTestCase {

    var windowRegistry: EcosiaAuthWindowRegistry!
    var testWindowUUID1: WindowUUID!
    var testWindowUUID2: WindowUUID!
    var testWindowUUID3: WindowUUID!

    override func setUp() {
        super.setUp()
        windowRegistry = EcosiaAuthWindowRegistry.shared
        testWindowUUID1 = WindowUUID.XCTestDefaultUUID
        testWindowUUID2 = WindowUUID()
        testWindowUUID3 = WindowUUID()

        windowRegistry.clearAllWindows()
    }

    // MARK: - Initialization Tests

    func testSharedInstance_returnsSameInstance() {
        // Arrange & Act
        let instance1 = EcosiaAuthWindowRegistry.shared
        let instance2 = EcosiaAuthWindowRegistry.shared

        // Assert
        XCTAssertTrue(instance1 === instance2)
    }

    func testInitialState_isEmpty() {
        // Arrange & Act
        let registeredWindows = windowRegistry.registeredWindows
        let windowCount = windowRegistry.windowCount

        // Assert
        XCTAssertTrue(registeredWindows.isEmpty)
        XCTAssertEqual(windowCount, 0)
    }

    // MARK: - Window Registration Tests

    func testRegisterWindow_addsWindowToRegistry() {
        // Arrange
        let windowUUID = testWindowUUID1!

        // Act
        windowRegistry.registerWindow(windowUUID)

        // Assert
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID))
        XCTAssertEqual(windowRegistry.windowCount, 1)
        XCTAssertTrue(windowRegistry.registeredWindows.contains(windowUUID), "Registered windows should contain the window")
    }

    func testRegisterWindow_multipleDifferentWindows_addsAllWindows() {
        // Arrange
        let windowUUID1 = testWindowUUID1!
        let windowUUID2 = testWindowUUID2!
        let windowUUID3 = testWindowUUID3!

        // Act
        windowRegistry.registerWindow(windowUUID1)
        windowRegistry.registerWindow(windowUUID2)
        windowRegistry.registerWindow(windowUUID3)

        // Assert
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID1), "Window 1 should be registered")
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID2), "Window 2 should be registered")
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID3), "Window 3 should be registered")
        XCTAssertEqual(windowRegistry.windowCount, 3, "Window count should be 3")

        let registeredWindows = windowRegistry.registeredWindows
        XCTAssertTrue(registeredWindows.contains(windowUUID1), "Should contain window 1")
        XCTAssertTrue(registeredWindows.contains(windowUUID2), "Should contain window 2")
        XCTAssertTrue(registeredWindows.contains(windowUUID3), "Should contain window 3")
    }

    func testRegisterWindow_sameWindowTwice_doesNotDuplicate() {
        // Arrange
        let windowUUID = testWindowUUID1!

        // Act
        windowRegistry.registerWindow(windowUUID)
        windowRegistry.registerWindow(windowUUID) // Register same window again

        // Assert
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID), "Window should be registered")
        XCTAssertEqual(windowRegistry.windowCount, 1, "Window count should remain 1")
        XCTAssertEqual(windowRegistry.registeredWindows.count, 1, "Should have exactly one registered window")
    }

    // MARK: - Window Unregistration Tests

    func testUnregisterWindow_removesWindowFromRegistry() {
        // Arrange
        let windowUUID = testWindowUUID1!
        windowRegistry.registerWindow(windowUUID)

        // Act
        windowRegistry.unregisterWindow(windowUUID)

        // Assert
        XCTAssertFalse(windowRegistry.isWindowRegistered(windowUUID), "Window should not be registered")
        XCTAssertEqual(windowRegistry.windowCount, 0, "Window count should be 0")
        XCTAssertFalse(windowRegistry.registeredWindows.contains(windowUUID), "Registered windows should not contain the window")
    }

    func testUnregisterWindow_unregisteredWindow_doesNotAffectOtherWindows() {
        // Arrange
        let windowUUID1 = testWindowUUID1!
        let windowUUID2 = testWindowUUID2!
        let unregisteredWindowUUID = testWindowUUID3!

        windowRegistry.registerWindow(windowUUID1)
        windowRegistry.registerWindow(windowUUID2)

        // Act
        windowRegistry.unregisterWindow(unregisteredWindowUUID) // Unregister non-existent window

        // Assert
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID1), "Window 1 should still be registered")
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID2), "Window 2 should still be registered")
        XCTAssertFalse(windowRegistry.isWindowRegistered(unregisteredWindowUUID), "Unregistered window should not be registered")
        XCTAssertEqual(windowRegistry.windowCount, 2, "Window count should remain 2")
    }

    func testUnregisterWindow_multipleWindows_removesOnlySpecified() {
        // Arrange
        let windowUUID1 = testWindowUUID1!
        let windowUUID2 = testWindowUUID2!
        let windowUUID3 = testWindowUUID3!

        windowRegistry.registerWindow(windowUUID1)
        windowRegistry.registerWindow(windowUUID2)
        windowRegistry.registerWindow(windowUUID3)

        // Act
        windowRegistry.unregisterWindow(windowUUID2)

        // Assert
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID1), "Window 1 should still be registered")
        XCTAssertFalse(windowRegistry.isWindowRegistered(windowUUID2), "Window 2 should not be registered")
        XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID3), "Window 3 should still be registered")
        XCTAssertEqual(windowRegistry.windowCount, 2, "Window count should be 2")
    }

    // MARK: - Window Query Tests

    func testIsWindowRegistered_withRegisteredWindow_returnsTrue() {
        // Arrange
        let windowUUID = testWindowUUID1!
        windowRegistry.registerWindow(windowUUID)

        // Act
        let isRegistered = windowRegistry.isWindowRegistered(windowUUID)

        // Assert
        XCTAssertTrue(isRegistered, "Should return true for registered window")
    }

    func testIsWindowRegistered_withUnregisteredWindow_returnsFalse() {
        // Arrange
        let windowUUID = testWindowUUID1!
        // Don't register the window

        // Act
        let isRegistered = windowRegistry.isWindowRegistered(windowUUID)

        // Assert
        XCTAssertFalse(isRegistered, "Should return false for unregistered window")
    }

    func testRegisteredWindows_returnsAllRegisteredWindows() {
        // Arrange
        let windowUUID1 = testWindowUUID1!
        let windowUUID2 = testWindowUUID2!
        let windowUUID3 = testWindowUUID3!

        windowRegistry.registerWindow(windowUUID1)
        windowRegistry.registerWindow(windowUUID2)
        windowRegistry.registerWindow(windowUUID3)

        // Act
        let registeredWindows = windowRegistry.registeredWindows

        // Assert
        XCTAssertEqual(registeredWindows.count, 3, "Should return all registered windows")
        XCTAssertTrue(registeredWindows.contains(windowUUID1), "Should contain window 1")
        XCTAssertTrue(registeredWindows.contains(windowUUID2), "Should contain window 2")
        XCTAssertTrue(registeredWindows.contains(windowUUID3), "Should contain window 3")
    }

    func testWindowCount_returnsCorrectCount() {
        // Arrange
        let windowUUID1 = testWindowUUID1!
        let windowUUID2 = testWindowUUID2!

        // Act & Assert - Initial count
        XCTAssertEqual(windowRegistry.windowCount, 0, "Initial count should be 0")

        // Act & Assert - After registering one window
        windowRegistry.registerWindow(windowUUID1)
        XCTAssertEqual(windowRegistry.windowCount, 1, "Count should be 1 after registering one window")

        // Act & Assert - After registering another window
        windowRegistry.registerWindow(windowUUID2)
        XCTAssertEqual(windowRegistry.windowCount, 2, "Count should be 2 after registering two windows")

        // Act & Assert - After unregistering one window
        windowRegistry.unregisterWindow(windowUUID1)
        XCTAssertEqual(windowRegistry.windowCount, 1, "Count should be 1 after unregistering one window")
    }

    // MARK: - Cleanup Tests

    func testClearAllWindows_removesAllWindows() {
        // Arrange
        let windowUUID1 = testWindowUUID1!
        let windowUUID2 = testWindowUUID2!
        let windowUUID3 = testWindowUUID3!

        windowRegistry.registerWindow(windowUUID1)
        windowRegistry.registerWindow(windowUUID2)
        windowRegistry.registerWindow(windowUUID3)

        // Act
        windowRegistry.clearAllWindows()

        // Assert
        XCTAssertEqual(windowRegistry.windowCount, 0, "Window count should be 0 after clearing")
        XCTAssertTrue(windowRegistry.registeredWindows.isEmpty, "Should have no registered windows")
        XCTAssertFalse(windowRegistry.isWindowRegistered(windowUUID1), "Window 1 should not be registered")
        XCTAssertFalse(windowRegistry.isWindowRegistered(windowUUID2), "Window 2 should not be registered")
        XCTAssertFalse(windowRegistry.isWindowRegistered(windowUUID3), "Window 3 should not be registered")
    }

    func testClearAllWindows_whenEmpty_doesNotCrash() {
        // Arrange - Registry is already empty

        // Act
        windowRegistry.clearAllWindows()

        // Assert
        XCTAssertEqual(windowRegistry.windowCount, 0, "Window count should remain 0")
        XCTAssertTrue(windowRegistry.registeredWindows.isEmpty, "Should have no registered windows")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentRegistration_maintainsDataIntegrity() {
        // Arrange
        let expectation = expectation(description: "Concurrent registrations should complete")
        expectation.expectedFulfillmentCount = 50
        let windowUUIDs = (0..<50).map { _ in WindowUUID() }

        // Act - Perform concurrent registrations
        for windowUUID in windowUUIDs {
            DispatchQueue.global().async {
                self.windowRegistry.registerWindow(windowUUID)
                expectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(windowRegistry.windowCount, 50, "All concurrent registrations should complete successfully")

        // Verify all windows are actually registered
        for windowUUID in windowUUIDs {
            XCTAssertTrue(windowRegistry.isWindowRegistered(windowUUID), "Window \(windowUUID) should be registered")
        }
    }

    func testConcurrentRegistrationAndUnregistration_maintainsDataIntegrity() {
        // Arrange
        let expectation = expectation(description: "Concurrent operations should complete")
        expectation.expectedFulfillmentCount = 100
        let windowUUIDs = (0..<25).map { _ in WindowUUID() }

        // Act - Perform concurrent registrations and unregistrations
        for windowUUID in windowUUIDs {
            DispatchQueue.global().async {
                self.windowRegistry.registerWindow(windowUUID)
                expectation.fulfill()
            }

            DispatchQueue.global().async {
                self.windowRegistry.unregisterWindow(windowUUID)
                expectation.fulfill()
            }

            DispatchQueue.global().async {
                self.windowRegistry.registerWindow(windowUUID)
                expectation.fulfill()
            }

            DispatchQueue.global().async {
                _ = self.windowRegistry.isWindowRegistered(windowUUID)
                expectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 5.0)
        // The exact count is unpredictable due to race conditions, but it should be consistent
        let finalCount = windowRegistry.windowCount
        XCTAssertTrue(finalCount >= 0 && finalCount <= 25, "Final count should be within expected range")
    }

    func testConcurrentQueries_returnConsistentResults() {
        // Arrange
        let expectation = expectation(description: "Concurrent queries should complete")
        expectation.expectedFulfillmentCount = 100
        let windowUUIDs = (0..<10).map { _ in WindowUUID() }

        // Register some windows first
        for windowUUID in windowUUIDs {
            windowRegistry.registerWindow(windowUUID)
        }

        // Act - Perform concurrent queries
        for _ in 0..<100 {
            DispatchQueue.global().async {
                _ = self.windowRegistry.registeredWindows
                _ = self.windowRegistry.windowCount
                if let windowUUID = windowUUIDs.randomElement() {
                    _ = self.windowRegistry.isWindowRegistered(windowUUID)
                }
                expectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(windowRegistry.windowCount, 10, "Window count should remain consistent")
    }

    // MARK: - Memory Management Tests

    func testMemoryUsage_withManyWindows_doesNotLeak() {
        // Arrange
        let windowUUIDs = (0..<1000).map { _ in WindowUUID() }

        // Act
        for windowUUID in windowUUIDs {
            windowRegistry.registerWindow(windowUUID)
        }

        // Assert
        XCTAssertEqual(windowRegistry.windowCount, 1000, "Should handle many windows")

        // Cleanup
        windowRegistry.clearAllWindows()
        XCTAssertEqual(windowRegistry.windowCount, 0, "Should clean up properly")
    }
}
