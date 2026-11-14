// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import TestKit
import VPNKit
import XCTest
@testable import Client

@MainActor
final class VPNMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!
    private var mockProfile: MockProfile!
    private var mockVPNManager: MockVPNManager!
    private var mockUserPreferences: MockUserFeaturePreferences!
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
        mockUserPreferences = MockUserFeaturePreferences()
        windowManager = WindowManagerImplementation(tabDataStore: MockTabDataStore())
        firstTabManager = MockTabManager(windowUUID: firstWindowUUID)
        secondTabManager = MockTabManager(windowUUID: secondWindowUUID)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: firstTabManager), uuid: firstWindowUUID)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: secondTabManager), uuid: secondWindowUUID)
        setupStore()
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockVPNManager = nil
        mockUserPreferences = nil
        windowManager = nil
        firstTabManager = nil
        secondTabManager = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    // MARK: - Start / stop

    func testStart_startsVPNAndSetsPreference() async {
        let subject = createSubject()

        await dispatchAndWaitForPreference(.start, to: subject)

        XCTAssertEqual(mockVPNManager.startCalled, 1)
        XCTAssertEqual(mockUserPreferences.boolPreferences[.vpnFeature], true)
    }

    func testStart_passesSavedCountryCode() async {
        mockProfile.prefs.setString("DE", forKey: PrefsKeys.VPNSettings.selectedCountryCode)
        let subject = createSubject()

        await dispatchAndWaitForPreference(.start, to: subject)

        XCTAssertEqual(mockVPNManager.startCountryCodes, ["DE"])
    }

    func testStart_whenStartFails_doesNotSetPreference() async {
        mockVPNManager.startError = URLError(.notConnectedToInternet)
        let started = expectation(description: "VPN start attempted")
        mockVPNManager.onStart = { started.fulfill() }
        let preferenceSet = expectation(description: "Preference set")
        preferenceSet.isInverted = true
        mockUserPreferences.onSetPreference = { preferenceSet.fulfill() }
        let subject = createSubject()

        subject.vpnProvider.modernMiddleware(AppState(), VPNModernAction.start, firstWindowUUID)
        await fulfillment(of: [started, preferenceSet], timeout: 0.2)

        XCTAssertNil(mockUserPreferences.boolPreferences[.vpnFeature])
    }

    func testStop_stopsVPNAndClearsPreference() async {
        mockUserPreferences.boolPreferences[.vpnFeature] = true
        let subject = createSubject()

        await dispatchAndWaitForPreference(.stop, to: subject)

        XCTAssertEqual(mockVPNManager.stopCalled, 1)
        XCTAssertEqual(mockUserPreferences.boolPreferences[.vpnFeature], false)
        XCTAssertTrue(firstTabManager.removeTabCalledWith.isEmpty)
        XCTAssertTrue(firstTabManager.removeAllTabsCalledWith.isEmpty)
    }

    func testChangeLocation_whenRunning_startsWithSavedCountryCodeWithoutTouchingPreference() async {
        mockVPNManager.isRunning = true
        mockProfile.prefs.setString("DE", forKey: PrefsKeys.VPNSettings.selectedCountryCode)

        await dispatchChangeLocationAndWait(expectStart: true)

        XCTAssertEqual(mockVPNManager.startCountryCodes, ["DE"])
        XCTAssertEqual(mockVPNManager.stopCalled, 0)
        XCTAssertNil(mockUserPreferences.boolPreferences[.vpnFeature])
    }

    func testChangeLocation_whenStopped_doesNotStart() async {
        await dispatchChangeLocationAndWait(expectStart: false)

        XCTAssertEqual(mockVPNManager.startCalled, 0)
        XCTAssertNil(mockUserPreferences.boolPreferences[.vpnFeature])
    }

    func testChangeLocation_whenStartFails_doesNotTouchPreference() async {
        mockVPNManager.isRunning = true
        mockVPNManager.startError = URLError(.notConnectedToInternet)

        await dispatchChangeLocationAndWait(expectStart: true)

        XCTAssertEqual(mockVPNManager.startCalled, 1)
        XCTAssertNil(mockUserPreferences.boolPreferences[.vpnFeature])
    }

    // MARK: - Alert choices

    func testAlertChoice_clearsPreference() async {
        mockUserPreferences.boolPreferences[.vpnFeature] = true
        let subject = createSubject()

        await dispatchAndWaitForPreference(.continueWithoutVPN, to: subject)

        XCTAssertEqual(mockUserPreferences.boolPreferences[.vpnFeature], false)
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

    // MARK: - VPN events

    func testPassUpdated_withNoDataRemaining_dispatchesDataLimitAlert() async throws {
        let subject = createSubject()

        try await yieldAndWaitForDispatch(.passUpdated(makePass(remaining: 0, unlimited: false)), subject: subject)

        let action = try XCTUnwrap(mockStore.dispatchedModernActions.first as? VPNAlertModernAction)
        guard case .showDataLimitAlert(let dataLimitBytes) = action else {
            return XCTFail("Expected showDataLimitAlert, got \(action)")
        }
        XCTAssertEqual(dataLimitBytes, 1_000)
    }

    func testPassUpdated_withDataRemaining_doesNotDispatch() async {
        let subject = createSubject()

        await yieldAndWaitForNoDispatch(.passUpdated(makePass(remaining: 500, unlimited: false)), subject: subject)
    }

    func testPassUpdated_withUnlimitedUsage_doesNotDispatch() async {
        let subject = createSubject()

        await yieldAndWaitForNoDispatch(.passUpdated(makePass(remaining: 0, unlimited: true)), subject: subject)
    }

    func testPassUpdated_withNoUsage_doesNotDispatch() async {
        let subject = createSubject()

        await yieldAndWaitForNoDispatch(.passUpdated(makePass(usage: nil)), subject: subject)
    }

    func testRotationFailed_dispatchesFailureAlert() async throws {
        let subject = createSubject()

        try await yieldAndWaitForDispatch(.rotationFailed, subject: subject)

        let action = try XCTUnwrap(mockStore.dispatchedModernActions.first as? VPNAlertModernAction)
        guard case .showFailureAlert = action else {
            return XCTFail("Expected showFailureAlert, got \(action)")
        }
    }

    // MARK: - Helpers

    func setupAppState() -> AppState {
        return AppState()
    }

    private func createSubject() -> VPNMiddleware {
        let subject = VPNMiddleware(
            windowManager: windowManager,
            profile: mockProfile,
            logger: MockLogger(),
            userPreferences: mockUserPreferences,
            vpnManager: mockVPNManager
        )

        return subject
    }

    private func dispatchChangeLocationAndWait(expectStart: Bool) async {
        let started = expectation(description: "VPN start attempted")
        started.isInverted = !expectStart
        mockVPNManager.onStart = { started.fulfill() }
        let preferenceSet = expectation(description: "Preference set")
        preferenceSet.isInverted = true
        mockUserPreferences.onSetPreference = { preferenceSet.fulfill() }
        let subject = createSubject()

        subject.vpnProvider.modernMiddleware(AppState(), VPNModernAction.changeLocation, firstWindowUUID)
        await fulfillment(of: [started, preferenceSet], timeout: 0.2)
    }

    private func yieldAndWaitForDispatch(_ event: VPNEvent, subject: VPNMiddleware) async throws {
        let dispatched = expectation(description: "Alert dispatched")
        mockStore.dispatchCalled = { dispatched.fulfill() }
        mockVPNManager.eventsStream.continuation.yield(event)
        await fulfillment(of: [dispatched], timeout: 1)
        XCTAssertEqual(mockStore.dispatchedModernActions.count, 1)
    }

    private func yieldAndWaitForNoDispatch(_ event: VPNEvent, subject: VPNMiddleware) async {
        let dispatched = expectation(description: "Alert dispatched")
        dispatched.isInverted = true
        mockStore.dispatchCalled = { dispatched.fulfill() }
        mockVPNManager.eventsStream.continuation.yield(event)
        await fulfillment(of: [dispatched], timeout: 0.2)
        XCTAssertTrue(mockStore.dispatchedModernActions.isEmpty)
    }

    private func makePass(remaining: Int64, unlimited: Bool) -> VPNProxyPass {
        return makePass(usage: VPNProxyUsage(max: 1_000, remaining: remaining, reset: Date(), unlimited: unlimited))
    }

    private func makePass(usage: VPNProxyUsage?) -> VPNProxyPass {
        return VPNProxyPass(
            bearerToken: "token",
            notBefore: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            usage: usage
        )
    }

    /// Waits for the preference write, the last step of starting or stopping.
    private func dispatchAndWaitForPreference(_ action: VPNModernAction, to subject: VPNMiddleware) async {
        let preferenceSet = expectation(description: "Preference set")
        mockUserPreferences.onSetPreference = { preferenceSet.fulfill() }
        subject.vpnProvider.modernMiddleware(AppState(), action, firstWindowUUID)
        await fulfillment(of: [preferenceSet], timeout: 1)
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
