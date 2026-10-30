// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Sentry
import XCTest
@testable import Common

/// Exercises the real `DefaultLogger` and `DefaultCrashManager` together, only stubbing the Sentry SDK boundary
final class CrashReportFeatureFlagsIntegrationTests: XCTestCase {
    private var sentryWrapper: MockSentryWrapper!

    override func setUp() {
        super.setUp()
        sentryWrapper = MockSentryWrapper()
        sentryWrapper.dsn = "12345"
    }

    override func tearDown() {
        sentryWrapper = nil
        super.tearDown()
    }

    func testFlagsSetBeforeCrashReportingStarts_areAttachedOnceStarted() {
        let subject = createSubject()

        subject.setFeatureFlags(["homepage": "control", "tab-tray": "treatment-a"])
        subject.setup(sendCrashReports: true)

        XCTAssertEqual(featureFlags(in: sentryWrapper.scope), ["homepage:control", "tab-tray:treatment-a"])
    }

    func testFlagsUpdatedAfterCrashReportingStarts_replaceAttachedFlags() {
        let subject = createSubject()
        subject.setup(sendCrashReports: true)

        subject.setFeatureFlags(["homepage": "control"])
        XCTAssertEqual(featureFlags(in: sentryWrapper.scope), ["homepage:control"])

        subject.setFeatureFlags(["homepage": "treatment-b", "tab-tray": "treatment-a"])
        XCTAssertEqual(featureFlags(in: sentryWrapper.scope), ["homepage:treatment-b", "tab-tray:treatment-a"])
    }

    func testFlagsClearedAfterCrashReportingStarts_removesAttachedFlags() {
        let subject = createSubject()
        subject.setup(sendCrashReports: true)
        subject.setFeatureFlags(["homepage": "control"])

        subject.setFeatureFlags([:])

        XCTAssertNil(featureFlags(in: sentryWrapper.scope))
    }

    private func createSubject() -> DefaultLogger {
        let crashManager = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                               isSimulator: false,
                                               skipReleaseNameCheck: true)
        return DefaultLogger(swiftyBeaverBuilder: MockSwiftyBeaverBuilder(), crashManager: crashManager)
    }
}
