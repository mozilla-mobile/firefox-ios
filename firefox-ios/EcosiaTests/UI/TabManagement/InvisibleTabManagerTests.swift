// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import WebKit
@testable import Client

/// Test suite for InvisibleTabManager functionality
final class InvisibleTabManagerTests: XCTestCase {

    // MARK: - Properties

    private var manager: InvisibleTabManager!
    private var testTab: Tab!
    private var windowUUID: WindowUUID!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create a window UUID for testing
        windowUUID = WindowUUID()

        // Get the shared manager instance and clear any existing state
        manager = InvisibleTabManager.shared
        manager.clearAllInvisibleTabs()

        // Create a test tab
        testTab = createTestTab()
    }

    override func tearDown() {
        // Clean up state after each test
        manager.clearAllInvisibleTabs()
        testTab = nil
        windowUUID = nil
        manager = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestTab(url: URL? = URL(string: "https://example.com")) -> Tab {
        let profile = MockProfile()  // Use existing MockProfile from test suite
        return Tab(profile: profile, isPrivate: false, windowUUID: windowUUID)
    }

    // MARK: - Tab Visibility Management Tests

    func testMarkTabAsInvisible() {
        // Given
        XCTAssertFalse(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 0)

        // When
        manager.markTabAsInvisible(testTab)

        // Then
        XCTAssertTrue(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 1)
        XCTAssertTrue(manager.invisibleTabUUIDs.contains(testTab.tabUUID))
    }

    func testMarkTabAsVisible() {
        // Given
        manager.markTabAsInvisible(testTab)
        XCTAssertTrue(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 1)

        // When
        manager.markTabAsVisible(testTab)

        // Then
        XCTAssertFalse(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 0)
        XCTAssertFalse(manager.invisibleTabUUIDs.contains(testTab.tabUUID))
    }

    func testMarkSameTabMultipleTimes() {
        // Given
        manager.markTabAsInvisible(testTab)
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 1)

        // When
        manager.markTabAsInvisible(testTab)

        // Then
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 1, "Should only count the tab once")
        XCTAssertTrue(manager.isTabInvisible(testTab))
    }

    func testClearAllInvisibleTabs() {
        // Given
        manager.markTabAsInvisible(testTab)
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 1)

        // When
        manager.clearAllInvisibleTabs()

        // Then
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 0)
        XCTAssertFalse(manager.isTabInvisible(testTab))
    }

    func testMultipleTabsManagement() {
        // Given
        let tab1 = createTestTab(url: URL(string: "https://example1.com"))
        let tab2 = createTestTab(url: URL(string: "https://example2.com"))
        let tab3 = createTestTab(url: URL(string: "https://example3.com"))

        // When
        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab2)
        manager.markTabAsInvisible(tab3)

        // Then
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 3)
        XCTAssertTrue(manager.isTabInvisible(tab1))
        XCTAssertTrue(manager.isTabInvisible(tab2))
        XCTAssertTrue(manager.isTabInvisible(tab3))

        // When
        manager.markTabAsVisible(tab2)

        // Then
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 2)
        XCTAssertTrue(manager.isTabInvisible(tab1))
        XCTAssertFalse(manager.isTabInvisible(tab2))
        XCTAssertTrue(manager.isTabInvisible(tab3))
    }

    // MARK: - Filter Methods Tests

    func testGetVisibleTabs() {
        // Given
        let tab1 = createTestTab(url: URL(string: "https://visible1.com"))
        let tab2 = createTestTab(url: URL(string: "https://invisible.com"))
        let tab3 = createTestTab(url: URL(string: "https://visible2.com"))
        let allTabs = [tab1, tab2, tab3]

        manager.markTabAsInvisible(tab2)

        // When
        let visibleTabs = manager.getVisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, 2)
        XCTAssertTrue(visibleTabs.contains(tab1))
        XCTAssertFalse(visibleTabs.contains(tab2))
        XCTAssertTrue(visibleTabs.contains(tab3))
    }

    func testGetInvisibleTabs() {
        // Given
        let tab1 = createTestTab(url: URL(string: "https://visible.com"))
        let tab2 = createTestTab(url: URL(string: "https://invisible1.com"))
        let tab3 = createTestTab(url: URL(string: "https://invisible2.com"))
        let allTabs = [tab1, tab2, tab3]

        manager.markTabAsInvisible(tab2)
        manager.markTabAsInvisible(tab3)

        // When
        let invisibleTabs = manager.getInvisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisibleTabs.count, 2)
        XCTAssertFalse(invisibleTabs.contains(tab1))
        XCTAssertTrue(invisibleTabs.contains(tab2))
        XCTAssertTrue(invisibleTabs.contains(tab3))
    }

    // MARK: - Cleanup Tests

    func testCleanupRemovedTabs() {
        // Given
        let tab1 = createTestTab(url: URL(string: "https://tab1.com"))
        let tab2 = createTestTab(url: URL(string: "https://tab2.com"))
        let tab3 = createTestTab(url: URL(string: "https://tab3.com"))

        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab2)
        manager.markTabAsInvisible(tab3)
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 3)

        // When
        let existingTabUUIDs: Set<TabUUID> = [tab1.tabUUID, tab3.tabUUID]
        manager.cleanupRemovedTabs(existingTabUUIDs: existingTabUUIDs)

        // Then
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 2)
        XCTAssertTrue(manager.isTabInvisible(tab1))
        XCTAssertFalse(manager.isTabInvisible(tab2))
        XCTAssertTrue(manager.isTabInvisible(tab3))
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess() {
        let expectation = self.expectation(description: "Concurrent operations should complete")
        let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let group = DispatchGroup()

        // Create multiple tabs for testing
        var tabs: [Tab] = []
        for i in 0..<100 {
            tabs.append(createTestTab(url: URL(string: "https://test\(i).com")))
        }

        // Perform concurrent operations
        for tab in tabs {
            group.enter()
            concurrentQueue.async {
                self.manager.markTabAsInvisible(tab)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            XCTAssertEqual(self.manager.invisibleTabUUIDs.count, 100)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testLargeScaleOperations() {
        // Given
        var tabs: [Tab] = []
        for i in 0..<1000 {
            tabs.append(createTestTab(url: URL(string: "https://large\(i).com")))
        }

        // When
        for tab in tabs {
            manager.markTabAsInvisible(tab)
        }

        // Then
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 1000)

        // When
        manager.clearAllInvisibleTabs()

        // Then
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 0)
    }

    func testIsTabInvisibleWithNonExistentTab() {
        // Given
        let nonExistentTab = createTestTab(url: URL(string: "https://nonexistent.com"))

        // When/Then
        XCTAssertFalse(manager.isTabInvisible(nonExistentTab))
    }

    func testMarkingSameTabTwice() {
        // Given
        manager.markTabAsInvisible(testTab)
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 1)

        // When
        manager.markTabAsInvisible(testTab)

        // Then
        XCTAssertEqual(manager.invisibleTabUUIDs.count, 1, "Should only count once for same UUID")
        XCTAssertTrue(manager.isTabInvisible(testTab))
    }
}
