// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
@testable import Client
// TODO: FXIOS-12947 - Add tests for TermsOfUseState and Coordinator

@MainActor
final class TermsOfUseMiddlewareTests: XCTestCase {
    private var userDefaults: MockUserDefaults!
    private var middleware: TermsOfUseMiddleware!

    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
        middleware = TermsOfUseMiddleware(userDefaults: userDefaults)
    }

    override func tearDown() {
        middleware = nil
        userDefaults = nil
        super.tearDown()
    }

     func testMiddleware_markAccepted_updatesUserDefaults() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markAccepted)
        middleware.termsOfUseProvider(AppState(), action)
        XCTAssertTrue(userDefaults.bool(forKey: TermsOfUseMiddleware.DefaultKeys.acceptedKey))
        XCTAssertFalse(userDefaults.bool(forKey: TermsOfUseMiddleware.DefaultKeys.dismissedKey))
    }
    func testMiddleware_markDismissed_updatesUserDefaultsWithDate() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markDismissed)
        middleware.termsOfUseProvider(AppState(), action)
        XCTAssertTrue(userDefaults.bool(forKey: TermsOfUseMiddleware.DefaultKeys.dismissedKey))
        XCTAssertNotNil(userDefaults.object(forKey: TermsOfUseMiddleware.DefaultKeys.lastShownKey))
    }
    func testMiddleware_markShownThisLaunch_doesNotWriteToUserDefaults() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markShownThisLaunch)
        middleware.termsOfUseProvider(AppState(), action)
        XCTAssertNil(userDefaults.object(forKey: TermsOfUseMiddleware.DefaultKeys.acceptedKey))
        XCTAssertNil(userDefaults.object(forKey: TermsOfUseMiddleware.DefaultKeys.dismissedKey))
        XCTAssertNil(userDefaults.object(forKey: TermsOfUseMiddleware.DefaultKeys.lastShownKey))
    }
}
