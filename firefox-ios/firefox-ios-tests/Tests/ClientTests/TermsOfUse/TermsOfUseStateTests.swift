// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import XCTest
@testable import Client

final class TermsOfUseStateTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    // MARK: - Variables
    private var userDefaults: MockUserDefaults!

    // MARK: - Test lifecycle
    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
    }

    override func tearDown() {
        super.tearDown()
        userDefaults = nil
    }

    // MARK: - Initialization tests
    func test_mockDefaultsInitializesEmpty() {
        XCTAssertTrue(userDefaults.savedData.isEmpty, "savedData should be empty when initializing object")
        XCTAssertTrue(userDefaults.registrationDictionary.isEmpty,
                      "registrationDictionary should be empty when initializing object")
    }

    func testDefaultInit_readsFromUserDefaults() {
        userDefaults.set(true, forKey: "termsOfUseAccepted")
        userDefaults.set(true, forKey: "termsOfUseDismissed")
        let date = Date(timeIntervalSinceNow: -1000)
        userDefaults.set(date, forKey: "termsOfUseLastShownDate")

        let state = TermsOfUseState(windowUUID: windowUUID)

        XCTAssertTrue(state.hasAccepted)
        XCTAssertTrue(state.wasDismissed)
        XCTAssertEqual(state.lastShownDate, date)
        XCTAssertFalse(state.didShowThisLaunch)
    }

    func testReducer_markAccepted_setsCorrectValuesAndPersists() {
        var state = TermsOfUseState(windowUUID: windowUUID)

        let action = TermsOfUseAction(windowUUID: windowUUID, actionType: .markAccepted)
        state = TermsOfUseState.reducer(state, action)

        XCTAssertTrue(state.hasAccepted)
        XCTAssertFalse(state.wasDismissed)
        XCTAssertTrue(userDefaults.bool(forKey: "termsOfUseAccepted"))
        XCTAssertFalse(userDefaults.bool(forKey: "termsOfUseDismissed"))
    }

    func testReducer_markDismissed_setsCorrectValuesAndPersists() {
        var state = TermsOfUseState(windowUUID: windowUUID)

        let action = TermsOfUseAction(windowUUID: windowUUID, actionType: .markDismissed)
        state = TermsOfUseState.reducer(state, action)

        XCTAssertTrue(state.wasDismissed)
        XCTAssertNotNil(state.lastShownDate)
        XCTAssertTrue(userDefaults.bool(forKey: "termsOfUseDismissed"))
        XCTAssertNotNil(userDefaults.object(forKey: "termsOfUseLastShownDate"))
    }

    func testReducer_markShownThisLaunch_setsFlag() {
        var state = TermsOfUseState(windowUUID: windowUUID)
        let action = TermsOfUseAction(windowUUID: windowUUID, actionType: .markShownThisLaunch)
        state = TermsOfUseState.reducer(state, action)
        XCTAssertTrue(state.didShowThisLaunch)
    }

    func testShouldShow_logic() {
        var state = TermsOfUseState(windowUUID: windowUUID)

        // Case: accepted
        state.hasAccepted = true
        XCTAssertFalse(state.shouldShow())

        // Case: not accepted and shown today
        state.hasAccepted = false
        state.didShowThisLaunch = true
        XCTAssertFalse(state.shouldShow())

        // Case: not accepted, last shown < 3 days ago
        state.lastShownDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        XCTAssertFalse(state.shouldShow())
    }
}
