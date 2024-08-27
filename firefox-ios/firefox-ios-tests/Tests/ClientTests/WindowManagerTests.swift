// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared
import Common
import Storage
import TabDataStore
@testable import Client

class WindowManagerTests: XCTestCase {
    let tabManager = MockTabManager(windowUUID: WindowUUID())
    let secondTabManager = MockTabManager(windowUUID: WindowUUID())
    let mockTabDataStore = MockTabDataStore()

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManager)
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testConfiguringAndConnectingSingleAppWindow() {
        let subject = createSubject()

        // Connect TabManager and browser to app window
        let uuid = tabManager.windowUUID
        subject.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager), uuid: uuid)

        // Expect 1 app window is now configured
        XCTAssertEqual(1, subject.windows.count)
        // Expect that window is now active window
        // XCTAssertEqual(uuid, subject.activeWindow)
        // Expect our previous tab manager is associated with that window
        XCTAssert(tabManager === subject.tabManager(for: uuid))
        XCTAssertEqual(tabManager.windowUUID, uuid)
    }

    func testConfiguringAndConnectingMultipleAppWindows() {
        let subject = createSubject()

        // Connect first TabManager and browser to app window
        let firstWindowUUID = tabManager.windowUUID
        subject.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager), uuid: firstWindowUUID)
        // Expect 1 app window is now configured
        XCTAssertEqual(1, subject.windows.count)

        // Connect second TabManager and browser to another window
        let secondWindowUUID = secondTabManager.windowUUID
        subject.newBrowserWindowConfigured(AppWindowInfo(tabManager: secondTabManager), uuid: secondWindowUUID)

        // Expect 2 app windows are now configured
        XCTAssertEqual(2, subject.windows.count)
        // Expect that our first window is still the active window
        // XCTAssertEqual(firstWindowUUID, subject.activeWindow)

        // Check for expected tab manager references for each window
        XCTAssert(tabManager === subject.tabManager(for: firstWindowUUID))
        XCTAssertEqual(tabManager.windowUUID, firstWindowUUID)
        XCTAssert(secondTabManager === subject.tabManager(for: secondWindowUUID))
        XCTAssertEqual(secondTabManager.windowUUID, secondWindowUUID)
    }

    func testOpeningMultipleWindowsAndClosingTheFirstWindow() {
        let subject = createSubject()

        // Configure two app windows
        let firstWindowUUID = tabManager.windowUUID
        let secondWindowUUID = secondTabManager.windowUUID
        subject.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager), uuid: firstWindowUUID)
        subject.newBrowserWindowConfigured(AppWindowInfo(tabManager: secondTabManager), uuid: secondWindowUUID)

        // Check that first window is the active window
        // XCTAssertEqual(2, subject.windows.count)
        // XCTAssertEqual(firstWindowUUID, subject.activeWindow)

        // Close the first window
        subject.windowWillClose(uuid: firstWindowUUID)

        // Check that the second window is now the only window
        XCTAssertEqual(1, subject.windows.count)
        XCTAssertEqual(secondWindowUUID, subject.windows.keys.first!)
        // Check that the second window is now automatically our "active" window
        // XCTAssertEqual(secondWindowUUID, subject.activeWindow)
    }

    func testNextAvailableUUIDWhenNoTabDataIsSaved() {
        let subject = createSubject()
        mockTabDataStore.resetMockTabWindowUUIDs()

        // Check that asking for two UUIDs results in two unique/random UUIDs
        // Note: there is a possibility of collision between any two randomly-
        // generated UUIDs but it is astronomically small (1 out of 2^122).
        let uuid1 = subject.reserveNextAvailableWindowUUID()
        let uuid2 = subject.reserveNextAvailableWindowUUID()
        XCTAssertNotEqual(uuid1.uuid, uuid2.uuid)
    }

    func testNextAvailableUUIDWhenOnlyOneWindowSaved() {
        let subject = createSubject()
        mockTabDataStore.resetMockTabWindowUUIDs()

        let savedUUID = UUID()
        mockTabDataStore.injectMockTabWindowUUID(savedUUID)

        // Check that asking for first UUID returns the expected UUID
        XCTAssertEqual(savedUUID, subject.reserveNextAvailableWindowUUID().uuid)
        // Open a window using this UUID
        subject.newBrowserWindowConfigured(AppWindowInfo(), uuid: savedUUID)
        // Check that asking for another UUID returns a new, random UUID
        XCTAssertNotEqual(savedUUID, subject.reserveNextAvailableWindowUUID().uuid)
    }

    func testNextAvailableUUIDWhenMultipleWindowsSaved() {
        let subject = createSubject()
        mockTabDataStore.resetMockTabWindowUUIDs()

        let uuid1 = UUID()
        let uuid2 = UUID()
        let expectedUUIDs = Set<UUID>([uuid1, uuid2])
        mockTabDataStore.injectMockTabWindowUUID(uuid1)
        mockTabDataStore.injectMockTabWindowUUID(uuid2)

        // Ask for UUIDs for two windows, which we open and configure
        let result1 = subject.reserveNextAvailableWindowUUID().uuid
        subject.newBrowserWindowConfigured(AppWindowInfo(), uuid: result1)
        let result2 = subject.reserveNextAvailableWindowUUID().uuid
        subject.newBrowserWindowConfigured(AppWindowInfo(), uuid: result2)

        // Check that our UUIDs are the ones we expected
        // (Note: currently the order is undefined, this may be changing soon)
        XCTAssert(expectedUUIDs.contains(result1))
        XCTAssert(expectedUUIDs.contains(result2))
        XCTAssertEqual(expectedUUIDs.count, 2)

        // Check that asking for a 3rd UUID returns a new, random UUID
        let result3 = subject.reserveNextAvailableWindowUUID().uuid
        XCTAssertFalse(expectedUUIDs.contains(result3))
        XCTAssertNotEqual(result1, result3)
        XCTAssertNotEqual(result2, result3)
    }

    func testAllWindowTabManagers() {
        let subject = createSubject()

        let tabManager1 = MockTabManager()
        let tabManager2 = MockTabManager()

        // Create two separate windows with associated Tab Managers
        let uuid1 = subject.reserveNextAvailableWindowUUID().uuid
        subject.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager1), uuid: uuid1)
        let uuid2 = subject.reserveNextAvailableWindowUUID().uuid
        subject.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager2), uuid: uuid2)

        // Check that allWindowTabManagers returns both expected instances
        var allTabManagers = subject.allWindowTabManagers()
        XCTAssertEqual(allTabManagers.count, 2)
        XCTAssert(allTabManagers.contains(where: { $0 === tabManager1 }))
        XCTAssert(allTabManagers.contains(where: { $0 === tabManager2 }))

        // Close first window and check that only the 2nd tab manager instance is returned
        subject.windowWillClose(uuid: uuid1)
        allTabManagers = subject.allWindowTabManagers()
        XCTAssertEqual(allTabManagers.count, 1)
        XCTAssert(tabManager2 === allTabManagers.first!)
    }

    func testReservedUUIDsAreUnavailableInSuccessiveCalls() {
        let subject = createSubject()
        mockTabDataStore.resetMockTabWindowUUIDs()

        let savedUUID = UUID()
        mockTabDataStore.injectMockTabWindowUUID(savedUUID)

        // Request a UUID. We expect it to be the first persisted WindowData
        // UUID, which will also be reserved for use.
        let requestedUUID1 = subject.reserveNextAvailableWindowUUID().uuid
        XCTAssertEqual(requestedUUID1, savedUUID)

        // Request a 2nd UUID. We expect it to be a different UUID.
        let requestedUUID2 = subject.reserveNextAvailableWindowUUID().uuid
        XCTAssertNotEqual(requestedUUID2, savedUUID)
    }

    func testClosingTwoWindowsInDifferentOrdersResultsInSensibleExpectedOrderWhenOpening() {
        let subject = createSubject()
        mockTabDataStore.resetMockTabWindowUUIDs()

        let uuid1 = UUID()
        mockTabDataStore.injectMockTabWindowUUID(uuid1)
        let uuid2 = UUID()
        mockTabDataStore.injectMockTabWindowUUID(uuid2)

        // Open a window using UUID 1
        subject.newBrowserWindowConfigured(AppWindowInfo(), uuid: uuid1)
        // Open a window using UUID 2
        subject.newBrowserWindowConfigured(AppWindowInfo(), uuid: uuid2)

        // Close window 2, then window 1
        subject.windowWillClose(uuid: uuid2)
        subject.windowWillClose(uuid: uuid1)

        // Now attempt to re-open two windows in order. We expect window
        // 1 to open, then window 2
        let result1 = subject.reserveNextAvailableWindowUUID().uuid
        let result2 = subject.reserveNextAvailableWindowUUID().uuid
        XCTAssertEqual(result1, uuid1)
        XCTAssertEqual(result2, uuid2)

        // Now re-open both windows in order...
        subject.newBrowserWindowConfigured(AppWindowInfo(), uuid: uuid1)
        subject.newBrowserWindowConfigured(AppWindowInfo(), uuid: uuid2)
        // ...but close them in the opposite order as before (close window 1, then 2)
        subject.windowWillClose(uuid: uuid1)
        subject.windowWillClose(uuid: uuid2)

        // Check that the next time we open the windows the order is now reversed
        let result2_1 = subject.reserveNextAvailableWindowUUID().uuid
        let result2_2 = subject.reserveNextAvailableWindowUUID().uuid
        XCTAssertEqual(result2_1, uuid2)
        XCTAssertEqual(result2_2, uuid1)
    }

    // MARK: - Test Subject

    private func createSubject() -> WindowManager {
        // For this test case, we create a new WindowManager that we can
        // modify and reset between each test case as needed, without
        // impacting other tests that may use the shared AppContainer.
        return WindowManagerImplementation(tabDataStore: mockTabDataStore)
    }
}
