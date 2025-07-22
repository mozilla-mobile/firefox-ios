// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
@testable import Client

final class TermsOfUseManagerTests: XCTestCase {
    private let userDefaults = UserDefaults.standard
    private var manager = TermsOfUseManager()

    override func setUp() {
        super.setUp()
        clearTermsOfUseKeys()
    }

    override func tearDown() {
        clearTermsOfUseKeys()
        super.tearDown()
    }

    private func clearTermsOfUseKeys() {
        userDefaults.removeObject(forKey: "termsOfUseAccepted")
        userDefaults.removeObject(forKey: "termsOfUseDismissed")
        userDefaults.removeObject(forKey: "termsOfUseLastShownDate")
        manager.didShowThisLaunch = false
    }

    func test_initialState_hasAcceptedFalse_wasDismissedFalse() {
        XCTAssertFalse(manager.hasAccepted)
        XCTAssertFalse(manager.wasDismissed)
    }

    func test_markAccepted_setsAcceptedTrue_andDismissedFalse() {
        manager.markAccepted()
        XCTAssertTrue(manager.hasAccepted)
        XCTAssertFalse(manager.wasDismissed)
    }

    func test_markDismissed_setsDismissedTrue_andUpdatesLastShownDate() {
        manager.markDismissed()
        XCTAssertTrue(manager.wasDismissed)
        XCTAssertNotNil(userDefaults.object(forKey: "termsOfUseLastShownDate") as? Date)
    }

    func test_shouldShow_returnsFalse_ifAlreadyAccepted() {
        manager.markAccepted()
        XCTAssertFalse(manager.shouldShow())
    }

    func test_shouldShow_returnsFalse_ifDidShowThisLaunch() {
        manager.didShowThisLaunch = true
        XCTAssertFalse(manager.shouldShow())
    }
}
