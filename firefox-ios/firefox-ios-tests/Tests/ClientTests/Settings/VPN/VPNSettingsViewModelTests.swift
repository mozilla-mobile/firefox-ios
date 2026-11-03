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

    override func setUp() async throws {
        try await super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() async throws {
        prefs = nil
        try await super.tearDown()
    }

    func test_init_readsEnabledPref() {
        prefs.setBool(true, forKey: PrefsKeys.VPNSettings.isEnabled)

        let subject = createSubject()

        XCTAssertTrue(subject.isVPNEnabled)
    }

    func test_toggleVPN_off_disablesAndSavesPref() {
        prefs.setBool(true, forKey: PrefsKeys.VPNSettings.isEnabled)
        let subject = createSubject()

        subject.toggleVPN(false)

        XCTAssertFalse(subject.isVPNEnabled)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.VPNSettings.isEnabled), false)
    }

    func test_toggleVPN_on_startsConnecting() {
        let subject = createSubject()

        subject.toggleVPN(true)

        XCTAssertTrue(subject.isVPNConnecting)
        XCTAssertFalse(subject.isVPNEnabled)
    }

    // MARK: - Helpers
    private func createSubject() -> VPNSettingsViewModel {
        let subject = VPNSettingsViewModel(prefs: prefs)
        trackForMemoryLeaks(subject)
        return subject
    }
}
