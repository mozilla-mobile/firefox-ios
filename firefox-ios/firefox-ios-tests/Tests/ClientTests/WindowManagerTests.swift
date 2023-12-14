// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared
import Common
import Storage
@testable import Client

class WindowManagerTests: XCTestCase {
    let tabManager = MockTabManager()
    let secondTabManager = MockTabManager()

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManager)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
    }

    func testConfiguringAndConnectingSingleAppWindow() {
        let subject = createSubject()

        // Connect TabManager and browser to app window
        let uuid = tabManager.windowUUID
        subject.tabManagerDidConnectToBrowserWindow(tabManager)

        // Expect 1 app window is now configured
        XCTAssertEqual(1, subject.windows.count)
        // Expect that window is now active window
        XCTAssertEqual(uuid, subject.activeWindow)
        // Expect our previous tab manager is associated with that window
        XCTAssert(tabManager === subject.tabManager(for: uuid))
        XCTAssertEqual(tabManager.windowUUID, uuid)
    }

    func testConfiguringAndConnectingMultipleAppWindows() {
        let subject = createSubject()

        // Connect first TabManager and browser to app window
        let firstWindowUUID = tabManager.windowUUID
        subject.tabManagerDidConnectToBrowserWindow(tabManager)
        // Expect 1 app window is now configured
        XCTAssertEqual(1, subject.windows.count)

        // Connect second TabManager and browser to another window
        let secondWindowUUID = secondTabManager.windowUUID
        subject.tabManagerDidConnectToBrowserWindow(secondTabManager)

        // Expect 2 app windows are now configured
        XCTAssertEqual(2, subject.windows.count)
        // Expect that our first window is still the active window
        XCTAssertEqual(firstWindowUUID, subject.activeWindow)

        // Check for expected tab manager references for each window
        XCTAssert(tabManager === subject.tabManager(for: firstWindowUUID))
        XCTAssertEqual(tabManager.windowUUID, firstWindowUUID)
        XCTAssert(secondTabManager === subject.tabManager(for: secondWindowUUID))
        XCTAssertEqual(secondTabManager.windowUUID, secondWindowUUID)
    }

    func testChangingActiveWindow() {
        var subject = createSubject()

        // Configure two app windows
        let firstWindowUUID = tabManager.windowUUID
        let secondWindowUUID = secondTabManager.windowUUID
        subject.tabManagerDidConnectToBrowserWindow(tabManager)
        subject.tabManagerDidConnectToBrowserWindow(secondTabManager)

        XCTAssertEqual(subject.activeWindow, firstWindowUUID)
        subject.activeWindow = secondWindowUUID
        XCTAssertEqual(subject.activeWindow, secondWindowUUID)
    }

    func testOpeningMultipleWindowsAndClosingTheFirstWindow() {
        let subject = createSubject()

        // Configure two app windows
        let firstWindowUUID = tabManager.windowUUID
        let secondWindowUUID = secondTabManager.windowUUID
        subject.tabManagerDidConnectToBrowserWindow(tabManager)
        subject.tabManagerDidConnectToBrowserWindow(secondTabManager)

        // Check that first window is the active window
        XCTAssertEqual(2, subject.windows.count)
        XCTAssertEqual(firstWindowUUID, subject.activeWindow)

        // Close the first window
        subject.windowDidClose(uuid: firstWindowUUID)

        // Check that the second window is now the only window
        XCTAssertEqual(1, subject.windows.count)
        XCTAssertEqual(secondWindowUUID, subject.windows.keys.first!)
        // Check that the second window is now automatically our "active" window
        XCTAssertEqual(secondWindowUUID, subject.activeWindow)
    }

    // MARK: - Test Subject

    private func createSubject() -> WindowManager {
        let manager: WindowManager = AppContainer.shared.resolve()
        return manager
    }
}
