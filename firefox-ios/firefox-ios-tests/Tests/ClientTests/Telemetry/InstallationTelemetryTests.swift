// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

@MainActor
final class InstallationTelemetryTests: XCTestCase {
    private var mockGleanWrapper: MockGleanWrapper!

    override func setUp() async throws {
        try await super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() async throws {
        mockGleanWrapper = nil
        try await super.tearDown()
    }

    func testRecordAcquisition_recordsPurchaseDateAndVersion() throws {
        let subject = InstallationTelemetry(gleanWrapper: mockGleanWrapper)
        let date = Date(timeIntervalSince1970: 1_760_000_000)

        subject.recordAcquisition(appAcquisition: AppAcquisition(originalPurchaseDate: date, originalAppVersion: "42"))

        let dateMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? DatetimeMetricType)
        let versionMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.last as? StringMetricType)
        XCTAssert(dateMetric === GleanMetrics.Installation.originalPurchaseDate)
        XCTAssert(versionMetric === GleanMetrics.Installation.originalAppVersion)
        XCTAssertEqual(mockGleanWrapper.savedValues.first as? Date, date)
        XCTAssertEqual(mockGleanWrapper.savedValues.last as? String, "42")
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
    }

    func testRecordInstallationHistory_recordsCountAndLastSeenDate() throws {
        let subject = InstallationTelemetry(gleanWrapper: mockGleanWrapper)
        let lastSeenDate = Date(timeIntervalSince1970: 45_296)

        subject.recordInstallationHistory(count: 4, lastSeenDate: lastSeenDate)

        let counterMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? QuantityMetricType)
        let dateMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.last as? DatetimeMetricType)
        XCTAssert(counterMetric === GleanMetrics.Installation.installCounter)
        XCTAssert(dateMetric === GleanMetrics.Installation.lastSeenDate)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [4])
        XCTAssertEqual(mockGleanWrapper.savedValues.first as? Date, lastSeenDate)
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
    }

    func testRecordInstallationHistory_withoutLastSeenDate_omitsLastSeenDate() {
        let subject = InstallationTelemetry(gleanWrapper: mockGleanWrapper)

        subject.recordInstallationHistory(count: 1, lastSeenDate: nil)

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedValues.isEmpty)
    }

    func testSubmit_submitsInstallationPing() {
        let subject = InstallationTelemetry(gleanWrapper: mockGleanWrapper)

        subject.submit()

        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
        XCTAssertTrue(mockGleanWrapper.savedPing as? Ping<NoReasonCodes> === GleanMetrics.Pings.shared.installation)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
    }
}
