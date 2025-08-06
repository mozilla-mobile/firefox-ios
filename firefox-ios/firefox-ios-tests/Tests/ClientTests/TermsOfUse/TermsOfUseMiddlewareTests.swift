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
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseAccepted), 1)
    }
    func testMiddleware_markDismissed_updatesPrefsWithDate() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markDismissed)
        middleware.termsOfUseProvider(AppState(), action)
        let dismissedDate: Date? = profile.prefs.objectForKey(PrefsKeys.TermsOfUseDismissedDate)
        XCTAssertNotNil(dismissedDate)

        if let date = dismissedDate {
            let todaysDate = Calendar.current.startOfDay(for: Date())
            XCTAssertEqual(date, todaysDate)
        }
    }
    func testMiddleware_markShownThisLaunch_doesNotWriteToPrefs() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markShownThisLaunch)
        middleware.termsOfUseProvider(AppState(), action)

        XCTAssertNil(profile.prefs.intForKey(PrefsKeys.TermsOfUseAccepted))
        let dismissedDate: Date? = profile.prefs.objectForKey(PrefsKeys.TermsOfUseDismissedDate)
        XCTAssertNil(dismissedDate)
    }
}
