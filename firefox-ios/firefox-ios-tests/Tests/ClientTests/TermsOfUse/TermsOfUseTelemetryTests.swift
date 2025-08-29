// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean
@testable import Client
import Common
import Shared

@MainActor
final class TermsOfUseTelemetryTests: XCTestCase {
    private var telemetry: TermsOfUseTelemetry!

    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        telemetry = TermsOfUseTelemetry()
    }

    override func tearDown() {
        super.tearDown()
        telemetry = nil
    }

    func testTermsOfUseBottomSheetDisplayed() throws {
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.impression.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))

        // Test impression counter
        let impressionCount = try XCTUnwrap(GleanMetrics.Termsofuse.impressionCount.testGetValue())
        XCTAssertEqual(impressionCount, 1)
    }

    func testTermsOfUseAcceptButtonTapped() throws {
        telemetry.termsOfUseAcceptButtonTapped(surface: .bottomSheet, acceptedDate: Date())

        // Test accepted event
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.accepted.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))
        // Test version metric
        let version = try XCTUnwrap(GleanMetrics.Termsofuse.version.testGetValue())
        XCTAssertEqual(version, telemetry.termsOfUseVersion)
        // Test date metric
        let dateMetric = try XCTUnwrap(GleanMetrics.Termsofuse.date.testGetValue())
        let now = Date()
        let timeDifference = abs(now.timeIntervalSince(dateMetric))
        XCTAssertLessThan(timeDifference, 60)
    }

    func testTermsOfUseBottomSheetDisplayed_doesNotRecordAcceptanceMetrics() {
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)

        // Impression should not record acceptance metrics
        XCTAssertNil(GleanMetrics.Termsofuse.version.testGetValue())
        XCTAssertNil(GleanMetrics.Termsofuse.date.testGetValue())
        // But impression event should be recorded
        XCTAssertNotNil(GleanMetrics.Termsofuse.impression.testGetValue())
    }

    func testTermsOfUseRemindMeLaterButtonTapped() throws {
        telemetry.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)

        // Test remind me later event
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.remindMeLaterClick.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))

        // Test remind me later counter
        let remindMeLaterCount = try XCTUnwrap(GleanMetrics.Termsofuse.remindMeLaterCount.testGetValue())
        XCTAssertEqual(remindMeLaterCount, 1)
    }

    func testTermsOfUseLearnMoreButtonTapped() throws {
        telemetry.termsOfUseLearnMoreButtonTapped(surface: .bottomSheet)

        // Test learn more event
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.learnMoreClick.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))
    }

    func testTermsOfUsePrivacyNoticeLinkTapped() throws {
        telemetry.termsOfUsePrivacyNoticeLinkTapped(surface: .bottomSheet)

        // Test privacy notice event
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.privacyNoticeClick.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))
    }

    func testTermsOfUseTermsOfUseLinkTapped() throws {
        telemetry.termsOfUseTermsOfUseLinkTapped(surface: .bottomSheet)

        // Test terms of use link event
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.termsOfUseClick.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))
    }

    func testTermsOfUseDismissed() throws {
        telemetry.termsOfUseDismissed(surface: .bottomSheet)

        // Test dismiss event
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.dismiss.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))

        // Test dismiss counter
        let dismissCount = try XCTUnwrap(GleanMetrics.Termsofuse.dismissCount.testGetValue())
        XCTAssertEqual(dismissCount, 1)
    }

    func testMultipleImpressions_incrementsCounter() throws {
        // Test that multiple impressions increment the counter correctly
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)

        let impressionCount = try XCTUnwrap(GleanMetrics.Termsofuse.impressionCount.testGetValue())
        XCTAssertEqual(impressionCount, 3)

        let events = try XCTUnwrap(GleanMetrics.Termsofuse.impression.testGetValue())
        XCTAssertEqual(events.count, 3)
    }

    func testMultipleRemindMeLater_incrementsCounter() throws {
        // Test that multiple remind me later clicks increment the counter correctly
        telemetry.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)
        telemetry.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)

        let remindMeLaterCount = try XCTUnwrap(GleanMetrics.Termsofuse.remindMeLaterCount.testGetValue())
        XCTAssertEqual(remindMeLaterCount, 2)

        let events = try XCTUnwrap(GleanMetrics.Termsofuse.remindMeLaterClick.testGetValue())
        XCTAssertEqual(events.count, 2)
    }

    func testMultipleDismisses_incrementsCounter() throws {
        // Test that multiple dismisses increment the counter correctly
        telemetry.termsOfUseDismissed(surface: .bottomSheet)
        telemetry.termsOfUseDismissed(surface: .bottomSheet)

        let dismissCount = try XCTUnwrap(GleanMetrics.Termsofuse.dismissCount.testGetValue())
        XCTAssertEqual(dismissCount, 2)

        let events = try XCTUnwrap(GleanMetrics.Termsofuse.dismiss.testGetValue())
        XCTAssertEqual(events.count, 2)
    }

    func testSetUsageMetrics() throws {
        let mockProfile = MockProfile()
        let mockGleanWrapper = MockGleanWrapper()

        mockProfile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        mockProfile.prefs.setString("1", forKey: PrefsKeys.TermsOfUseAcceptedVersion)
        let acceptedDate = Date()
        mockProfile.prefs.setTimestamp(acceptedDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseAcceptedDate)
        TermsOfUseTelemetry.setUsageMetrics(gleanWrapper: mockGleanWrapper, profile: mockProfile)

        XCTAssertEqual(mockGleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)
    }
}
