// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
import Glean
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
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
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
    func testMiddleware_markShown_setsFirstShownPref() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markShown)
        middleware.termsOfUseProvider(AppState(), action)

        // Should set the first shown preference
        XCTAssertTrue(profile.prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) == true)

        let dismissedTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate)
        XCTAssertNil(dismissedTimestamp)
    }

    // MARK: - Telemetry Tests

    func testMiddleware_markAccepted_recordsVersionAndDatePrefs() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markAccepted)
        middleware.termsOfUseProvider(AppState(), action)

        let versionString = profile.prefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion)
        XCTAssertEqual(versionString, String(middleware.termsOfUseVersion))
        let dateTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate)
        XCTAssertNotNil(dateTimestamp)
        if let timestamp = dateTimestamp {
            let acceptedDate = Date.fromTimestamp(timestamp)
            XCTAssertTrue(Calendar.current.isDate(acceptedDate, inSameDayAs: Date()))
            }
        }

    func testMiddleware_markAccepted_recordsAcceptedEvent() throws {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markAccepted)
        middleware.termsOfUseProvider(AppState(), action)

        let events = try XCTUnwrap(GleanMetrics.Termsofuse.accepted.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], middleware.termsOfUseSurface)
        XCTAssertEqual(event.extra?["tou_version"], String(middleware.termsOfUseVersion))
        }

    func testMiddleware_markAccepted_recordsVersionMetric() throws {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markAccepted)
        middleware.termsOfUseProvider(AppState(), action)

        let version = try XCTUnwrap(GleanMetrics.Termsofuse.version.testGetValue())
        XCTAssertEqual(version, middleware.termsOfUseVersion)
        }

    func testMiddleware_markAccepted_recordsDateMetric() throws {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markAccepted)
        middleware.termsOfUseProvider(AppState(), action)

        // Test that date metric was set
        let dateMetric = try XCTUnwrap(GleanMetrics.Termsofuse.date.testGetValue())
        // Verify the date is recent (within the last minute)
        let now = Date()
        let timeDifference = abs(now.timeIntervalSince(dateMetric))
        XCTAssertLessThan(timeDifference, 60)
        }

    func testMiddleware_markShown_recordsImpressionEvent() throws {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markShown)
        middleware.termsOfUseProvider(AppState(), action)

        let events = try XCTUnwrap(GleanMetrics.Termsofuse.impression.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], middleware.termsOfUseSurface)
        XCTAssertEqual(event.extra?["tou_version"], String(middleware.termsOfUseVersion))
        }

    func testMiddleware_markShown_doesNotRecordVersionOrDateMetrics() {
        let action = TermsOfUseAction(windowUUID: .XCTestDefaultUUID, actionType: TermsOfUseActionType.markShown)
        middleware.termsOfUseProvider(AppState(), action)

        // Version and date metrics should only be set on acceptance, not impression
        XCTAssertNil(GleanMetrics.Termsofuse.version.testGetValue())
        XCTAssertNil(GleanMetrics.Termsofuse.date.testGetValue())
        }
    }
