// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
@testable import Client
import Common
import Shared
// TODO: FXIOS-12947 - Add tests for TermsOfUseState and Coordinator

@MainActor
final class TermsOfUseMiddlewareTests: XCTestCase {
    private var profile: MockProfile!
    private var middleware: TermsOfUseMiddleware!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        middleware = TermsOfUseMiddleware(profile: profile)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        middleware = nil
        AppContainer.shared.reset()
    }

     func testMiddleware_markAccepted_updatesPrefs() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markAccepted)
        middleware.termsOfUseProvider(AppState(), action)
        XCTAssertTrue(profile.prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) == true)
    }
    func testMiddleware_markDismissed_updatesPrefsWithDate() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markDismissed)
        middleware.termsOfUseProvider(AppState(), action)
        let dismissedTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate)
        XCTAssertNotNil(dismissedTimestamp)

        if let timestamp = dismissedTimestamp {
            let dismissedDate = Date.fromTimestamp(timestamp)
            XCTAssertTrue(Calendar.current.isDate(dismissedDate, inSameDayAs: Date()))
        }
    }
    func testMiddleware_markFirstShown_setsFirstShownPref() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markFirstShown)
        middleware.termsOfUseProvider(AppState(), action)

        // Should set the first shown preference
        XCTAssertTrue(profile.prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) == true)
        
        // Should not affect other preferences
        XCTAssertFalse(profile.prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) == true)
        let dismissedTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate)
        XCTAssertNil(dismissedTimestamp)
    }
}
