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

    func testMiddleware_termsAccepted_updatesAcceptedPref() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsAccepted)
        middleware.termsOfUseProvider(AppState(), action)
        XCTAssertTrue(profile.prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) == true)
    }
    func testMiddleware_gestureDismiss_updatesPrefsWithDate() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.gestureDismiss)
        middleware.termsOfUseProvider(AppState(), action)
        let dismissedTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate)
        XCTAssertNotNil(dismissedTimestamp)

        if let timestamp = dismissedTimestamp {
            let dismissedDate = Date.fromTimestamp(timestamp)
            XCTAssertTrue(Calendar.current.isDate(dismissedDate, inSameDayAs: Date()))
        }
    }
    func testMiddleware_remindMeLaterTapped_updatesPrefsWithDate() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.remindMeLaterTapped)
        middleware.termsOfUseProvider(AppState(), action)
        let dismissedTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate)
        XCTAssertNotNil(dismissedTimestamp)

        if let timestamp = dismissedTimestamp {
            let dismissedDate = Date.fromTimestamp(timestamp)
            XCTAssertTrue(Calendar.current.isDate(dismissedDate, inSameDayAs: Date()))
        }
    }
    func testMiddleware_termsShown_setsShownPref() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), action)

        // Should set the first shown preference
        XCTAssertTrue(profile.prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) == true)

        let dismissedTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate)
        XCTAssertNil(dismissedTimestamp)
    }
    func testMiddleware_termsAccepted_recordsVersionAndDatePrefs() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsAccepted)
        middleware.termsOfUseProvider(AppState(), action)

        let versionString = profile.prefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion)
        XCTAssertEqual(versionString, String(middleware.telemetry.termsOfUseVersion))
        let dateTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate)
        XCTAssertNotNil(dateTimestamp)
        if let timestamp = dateTimestamp {
            let acceptedDate = Date.fromTimestamp(timestamp)
            XCTAssertTrue(Calendar.current.isDate(acceptedDate, inSameDayAs: Date()))
        }
    }
    func testMiddleware_remindMeLaterTapped_tracksTapTimestamp() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.remindMeLaterTapped)
        middleware.termsOfUseProvider(AppState(), action)

        let timestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseRemindMeLaterTapDate)
        XCTAssertNotNil(timestamp)
    }
    func testMiddleware_learnMoreLinkTapped_tracksTapTimestamp() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.learnMoreLinkTapped)
        middleware.termsOfUseProvider(AppState(), action)

        let timestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseLearnMoreTapDate)
        XCTAssertNotNil(timestamp)
    }
    func testMiddleware_privacyLinkTapped_tracksTapTimestamp() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.privacyLinkTapped)
        middleware.termsOfUseProvider(AppState(), action)

        let timestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUsePrivacyNoticeTapDate)
        XCTAssertNotNil(timestamp)
    }
    func testMiddleware_termsLinkTapped_tracksTapTimestamp() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsLinkTapped)
        middleware.termsOfUseProvider(AppState(), action)

        let timestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseTermsLinkTapDate)
        XCTAssertNotNil(timestamp)
    }
}
