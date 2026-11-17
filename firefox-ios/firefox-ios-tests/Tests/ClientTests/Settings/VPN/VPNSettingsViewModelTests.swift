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
    private var userPreferences: MockUserFeaturePreferences!

    override func setUp() async throws {
        try await super.setUp()
        prefs = MockProfilePrefs()
        userPreferences = MockUserFeaturePreferences()
    }

    override func tearDown() async throws {
        prefs = nil
        userPreferences = nil
        try await super.tearDown()
    }

    func test_init_readsVPNFeaturePreference() {
        userPreferences.setPreferenceFor(.vpnFeature, to: true)

        let subject = createSubject()

        XCTAssertTrue(subject.isVPNEnabled)
    }

    func test_toggleVPN_off_disablesAndSavesPreference() {
        userPreferences.setPreferenceFor(.vpnFeature, to: true)
        let subject = createSubject()

        subject.toggleVPN(false)

        XCTAssertFalse(subject.isVPNEnabled)
        XCTAssertFalse(userPreferences.getPreferenceFor(.vpnFeature))
    }

    func test_toggleVPN_on_startsConnecting() {
        let subject = createSubject()

        subject.toggleVPN(true)

        XCTAssertTrue(subject.isVPNConnecting)
        XCTAssertFalse(subject.isVPNEnabled)
    }

    func test_selectLocation_updatesAndSavesSelection() {
        let subject = createSubject()

        subject.selectLocation("DE")

        XCTAssertEqual(subject.selectedCountryCode, "DE")
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.VPNSettings.selectedCountryCode), "DE")
    }

    func test_sortedByName_sortsByLocalizedCountryName() {
        let subject = createSubject()

        let sorted = subject.sortedByName(["CH", "ES", "DE"])

        XCTAssertEqual(sorted, ["DE", "ES", "CH"])
    }

    // MARK: - Helpers
    private func createSubject() -> VPNSettingsViewModel {
        let subject = VPNSettingsViewModel(
            prefs: prefs,
            userPreferences: userPreferences,
            localeProvider: MockLocaleProvider()
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
