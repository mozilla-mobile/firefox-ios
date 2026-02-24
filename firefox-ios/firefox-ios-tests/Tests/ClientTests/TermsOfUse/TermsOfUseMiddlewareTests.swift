// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
@testable import Client
import Common
import Shared

@MainActor
final class TermsOfUseMiddlewareTests: XCTestCase {
    private var profile: MockProfile!
    private var mockGleanWrapper: MockGleanWrapper!
    private var middleware: TermsOfUseMiddleware!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        mockGleanWrapper = MockGleanWrapper()
        middleware = TermsOfUseMiddleware(profile: profile, telemetry: TermsOfUseTelemetry(gleanWrapper: mockGleanWrapper))
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        mockGleanWrapper = nil
        middleware = nil
        try await super.tearDown()
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

    func testMiddleware_firstDismissal_doesNotIncrementRemindersCount() {
        let shownAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction)

        let dismissAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.gestureDismiss)
        middleware.termsOfUseProvider(AppState(), dismissAction)

        let remindersCount = profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0
        XCTAssertEqual(remindersCount, 0, "First gesture dismissal should not increment reminders count")
        XCTAssertNotNil(profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate))
    }

    func testMiddleware_secondDismissal_incrementsRemindersCount() {
        let shownAction1 = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction1)

        let dismissAction1 = TermsOfUseAction(windowUUID: .XCTestDefaultUUID,
                                              actionType: TermsOfUseActionType.gestureDismiss)
        middleware.termsOfUseProvider(AppState(), dismissAction1)

        let dismissAction2 = TermsOfUseAction(windowUUID: .XCTestDefaultUUID,
                                              actionType: TermsOfUseActionType.gestureDismiss)
        middleware.termsOfUseProvider(AppState(), dismissAction2)

        let remindersCount = profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0
        XCTAssertEqual(remindersCount, 1, "Second gesture dismissal should increment reminders count to 1")
    }

    func testMiddleware_remindMeLaterTapped_firstDismissal_doesNotIncrementCount() {
        let shownAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction)

        let remindAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID,
                                            actionType: TermsOfUseActionType.remindMeLaterTapped)
        middleware.termsOfUseProvider(AppState(), remindAction)

        let remindersCount = profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0
        XCTAssertEqual(remindersCount, 0, "First 'Remind Me Later' should not increment reminders count")
    }

    func testMiddleware_remindMeLaterTapped_secondDismissal_incrementsCount() {
        let shownAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction)

        let remindAction1 = TermsOfUseAction(windowUUID: .XCTestDefaultUUID,
                                             actionType: TermsOfUseActionType.remindMeLaterTapped)
        middleware.termsOfUseProvider(AppState(), remindAction1)

        let remindAction2 = TermsOfUseAction(windowUUID: .XCTestDefaultUUID,
                                             actionType: TermsOfUseActionType.remindMeLaterTapped)
        middleware.termsOfUseProvider(AppState(), remindAction2)

        let remindersCount = profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0
        XCTAssertEqual(remindersCount, 1, "Second 'Remind Me Later' should increment reminders count to 1")
    }

    func testMiddleware_mixedDismissalTypes_incrementsCorrectly() {
        let shownAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction)

        let gestureAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.gestureDismiss)
        middleware.termsOfUseProvider(AppState(), gestureAction)
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0, 0)

        let remindAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID,
                                            actionType: TermsOfUseActionType.remindMeLaterTapped)
        middleware.termsOfUseProvider(AppState(), remindAction)
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0, 1)

        let gestureAction2 = TermsOfUseAction(windowUUID: .XCTestDefaultUUID,
                                              actionType: TermsOfUseActionType.gestureDismiss)
        middleware.termsOfUseProvider(AppState(), gestureAction2)
        XCTAssertEqual(profile.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0, 2)
    }

    func testMiddleware_termsShown_firstAppearance_incrementsShownCountOnce() {
        let shownAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 1)
    }

    func testMiddleware_termsShown_whenReminderIsShown_incrementsShownCountAgain() {
        let dismissAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.gestureDismiss)
        middleware.termsOfUseProvider(AppState(), dismissAction)

        let shownAction = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction)
        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 2)
    }

    func testMiddleware_termsShown_onResumeFromBackgroundOrLinks_doesNotIncrementShownCount() {
        let shownAction1 = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction1)

        let shownAction2 = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.termsShown)
        middleware.termsOfUseProvider(AppState(), shownAction2)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 1)
    }
}
