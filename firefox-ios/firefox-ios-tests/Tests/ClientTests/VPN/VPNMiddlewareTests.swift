// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import TestKit
import XCTest
@testable import Client

@MainActor
final class VPNMiddlewareTests: XCTestCase {
    private var mockProfile: MockProfile!
    private var mockVPNManager: MockVPNManager!
    private var windowManager: WindowManagerImplementation!
    // `AppWindowInfo.tabManager` is weak, so the tab managers are held here.
    private var firstTabManager: MockTabManager!
    private var secondTabManager: MockTabManager!
    private let firstWindowUUID = WindowUUID()
    private let secondWindowUUID = WindowUUID()

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = makeProfile()
        mockVPNManager = MockVPNManager()
        windowManager = WindowManagerImplementation(tabDataStore: MockTabDataStore())
        firstTabManager = MockTabManager(windowUUID: firstWindowUUID)
        secondTabManager = MockTabManager(windowUUID: secondWindowUUID)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: firstTabManager), uuid: firstWindowUUID)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: secondTabManager), uuid: secondWindowUUID)
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockVPNManager = nil
        windowManager = nil
        firstTabManager = nil
        secondTabManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testContinueWithoutVPN_stopsVPNWithoutClosingTabs() async {
        let subject = createSubject()

        await dispatch(.continueWithoutVPN, to: subject)

        XCTAssertEqual(mockVPNManager.stopCalled, 1)
        XCTAssertTrue(firstTabManager.removeTabCalledWith.isEmpty)
        XCTAssertTrue(firstTabManager.removeAllTabsCalledWith.isEmpty)
        XCTAssertTrue(secondTabManager.removeAllTabsCalledWith.isEmpty)
    }

    func testCloseThisTab_closesSelectedTabInActionWindowAndStopsVPN() async {
        let tab = MockTab(profile: mockProfile, windowUUID: firstWindowUUID)
        firstTabManager.selectedTab = tab
        secondTabManager.selectedTab = MockTab(profile: mockProfile, windowUUID: secondWindowUUID)
        let subject = createSubject()

        await dispatch(.closeThisTab, to: subject)

        XCTAssertEqual(firstTabManager.removeTabCalledWith, [tab.tabUUID])
        XCTAssertTrue(secondTabManager.removeTabCalledWith.isEmpty)
        XCTAssertEqual(mockVPNManager.stopCalled, 1)
    }

    func testCloseThisTab_withNoSelectedTab_stillStopsVPN() async {
        let subject = createSubject()

        await dispatch(.closeThisTab, to: subject)

        XCTAssertTrue(firstTabManager.removeTabCalledWith.isEmpty)
        XCTAssertEqual(mockVPNManager.stopCalled, 1)
    }

    func testCloseAllTabs_closesPrivateAndNormalTabsInAllWindowsAndStopsVPN() async {
        let subject = createSubject()

        await dispatch(.closeAllTabs, to: subject)

        XCTAssertEqual(firstTabManager.removeAllTabsCalledWith, [true, false])
        XCTAssertEqual(secondTabManager.removeAllTabsCalledWith, [true, false])
        XCTAssertEqual(mockVPNManager.stopCalled, 1)
    }

    func testCloseAllTabs_closesTabsBeforeStoppingVPN() async {
        var tabCountsClosedAtStop: [Int] = []
        mockVPNManager.onStop = { [unowned self] in
            tabCountsClosedAtStop = [
                firstTabManager.removeAllTabsCalledWith.count,
                secondTabManager.removeAllTabsCalledWith.count
            ]
        }
        let subject = createSubject()

        await dispatch(.closeAllTabs, to: subject)

        XCTAssertEqual(tabCountsClosedAtStop, [2, 2])
    }

    func testAlertAction_isIgnored() async {
        let subject = createSubject()

        subject.vpnProvider.modernMiddleware(AppState(), VPNAlertModernAction.showFailureAlert, firstWindowUUID)
        await Task.yield()

        XCTAssertEqual(mockVPNManager.stopCalled, 0)
    }

    // MARK: - Helpers

    private func createSubject() -> VPNMiddleware {
        return VPNMiddleware(windowManager: windowManager, logger: MockLogger(), vpnManager: mockVPNManager)
    }

    /// The middleware handles actions in a `Task`, so this waits for `stop()`, its last step.
    private func dispatch(_ action: VPNModernAction, to subject: VPNMiddleware) async {
        let stopped = expectation(description: "VPN stopped")
        let existingOnStop = mockVPNManager.onStop
        mockVPNManager.onStop = {
            existingOnStop?()
            stopped.fulfill()
        }
        subject.vpnProvider.modernMiddleware(AppState(), action, firstWindowUUID)
        await fulfillment(of: [stopped], timeout: 1)
    }
}
