// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import XCTest

@testable import Client

@available(iOS 17.0, *)
@MainActor
final class VPNSettingsViewModelTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!
    private var prefs: MockProfilePrefs!
    private var vpnManager: MockVPNManager!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
        prefs = MockProfilePrefs()
        vpnManager = MockVPNManager()
    }

    override func tearDown() async throws {
        prefs = nil
        vpnManager = nil
        resetStore()
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_isVPNEnabled_reflectsVPNRunningState() {
        vpnManager.isRunning = true

        let subject = createSubject()

        XCTAssertTrue(subject.isVPNEnabled)
    }

    func test_toggleVPN_off_dispatchesStop() throws {
        let subject = createSubject()

        subject.toggleVPN(false)

        let action = try XCTUnwrap(mockStore.dispatchedModernActions.last as? VPNModernAction)
        XCTAssertEqual(action, .stop)
    }

    func test_toggleVPN_on_dispatchesStart() throws {
        let subject = createSubject()

        subject.toggleVPN(true)

        let action = try XCTUnwrap(mockStore.dispatchedModernActions.last as? VPNModernAction)
        XCTAssertEqual(action, .start)
    }

    func test_selectLocation_updatesAndSavesSelection() {
        let subject = createSubject()

        subject.selectLocation("DE")

        XCTAssertEqual(subject.selectedCountryCode, "DE")
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.VPNSettings.selectedCountryCode), "DE")
    }

    func test_selectLocation_whenVPNRunning_dispatchesStart() throws {
        vpnManager.isRunning = true
        let subject = createSubject()

        subject.selectLocation("DE")

        let action = try XCTUnwrap(mockStore.dispatchedModernActions.last as? VPNModernAction)
        XCTAssertEqual(action, .start)
    }

    func test_selectLocation_whenVPNNotRunning_doesNotDispatch() {
        let subject = createSubject()

        subject.selectLocation("DE")

        XCTAssertTrue(mockStore.dispatchedModernActions.isEmpty)
    }

    func test_sortedByName_sortsByLocalizedCountryName() {
        let subject = createSubject()

        let sorted = subject.sortedByName(["CH", "ES", "DE"])

        XCTAssertEqual(sorted, ["DE", "ES", "CH"])
    }

    // MARK: - Helpers
    func setupAppState() -> AppState {
        return AppState()
    }

    private func createSubject() -> VPNSettingsViewModel {
        let subject = VPNSettingsViewModel(
            prefs: prefs,
            vpnManager: vpnManager,
            windowUUID: .XCTestDefaultUUID,
            localeProvider: MockLocaleProvider()
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
