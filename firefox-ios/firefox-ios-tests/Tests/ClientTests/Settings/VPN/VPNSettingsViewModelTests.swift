// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@available(iOS 17.0, *)
@MainActor
final class VPNSettingsViewModelTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private var vpnManager: MockVPNRunnable!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        prefs = MockProfilePrefs()
        vpnManager = MockVPNRunnable()
    }

    override func tearDown() async throws {
        prefs = nil
        vpnManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_init_readsVPNRunningState() {
        vpnManager.isRunning = true

        let subject = createSubject()

        XCTAssertTrue(subject.isVPNEnabled)
    }

    func test_toggleVPN_off_disablesAndStopsVPN() async {
        vpnManager.isRunning = true
        let stopped = expectation(description: "VPN stopped")
        vpnManager.onStop = { stopped.fulfill() }
        let subject = createSubject()

        subject.toggleVPN(false)
        await fulfillment(of: [stopped], timeout: 1)

        XCTAssertFalse(subject.isVPNEnabled)
        XCTAssertEqual(vpnManager.stopCalled, 1)
    }

    func test_toggleVPN_on_startsConnectingAndStartsVPN() async {
        let started = expectation(description: "VPN started")
        vpnManager.onStart = { started.fulfill() }
        let subject = createSubject()

        subject.toggleVPN(true)

        XCTAssertTrue(subject.isVPNConnecting)
        await fulfillment(of: [started], timeout: 1)
        XCTAssertEqual(vpnManager.startCalled, 1)
    }

    func test_selectLocation_updatesAndSavesSelection() {
        let subject = createSubject()

        subject.selectLocation("DE")

        XCTAssertEqual(subject.selectedCountryCode, "DE")
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.VPNSettings.selectedCountryCode), "DE")
    }

    func test_selectLocation_whenVPNRunning_reconnects() async {
        vpnManager.isRunning = true
        let reconnected = expectation(description: "VPN reconnected")
        vpnManager.onStart = { reconnected.fulfill() }
        let subject = createSubject()

        subject.selectLocation("DE")
        await fulfillment(of: [reconnected], timeout: 1)

        XCTAssertEqual(vpnManager.startCalled, 1)
    }

    func test_selectLocation_whenVPNNotRunning_doesNotConnect() {
        let subject = createSubject()

        subject.selectLocation("DE")

        XCTAssertEqual(vpnManager.startCalled, 0)
    }

    func test_sortedByName_sortsByLocalizedCountryName() {
        let subject = createSubject()

        let sorted = subject.sortedByName(["CH", "ES", "DE"])

        XCTAssertEqual(sorted, ["DE", "ES", "CH"])
    }

    // MARK: - Helpers
    private func createSubject() -> VPNSettingsViewModel {
        let subject = VPNSettingsViewModel(prefs: prefs, vpnManager: vpnManager, localeProvider: MockLocaleProvider())
        trackForMemoryLeaks(subject)
        return subject
    }
}
