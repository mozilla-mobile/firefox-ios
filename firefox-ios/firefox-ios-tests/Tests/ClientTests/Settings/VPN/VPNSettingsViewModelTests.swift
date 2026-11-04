// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@available(iOS 17.0, *)
@MainActor
final class VPNSettingsViewModelTests: XCTestCase {
    private var userPreferences: MockUserFeaturePreferences!

    override func setUp() async throws {
        try await super.setUp()
        userPreferences = MockUserFeaturePreferences()
    }

    override func tearDown() async throws {
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

    // MARK: - Helpers
    private func createSubject() -> VPNSettingsViewModel {
        let subject = VPNSettingsViewModel(userPreferences: userPreferences)
        trackForMemoryLeaks(subject)
        return subject
    }
}
