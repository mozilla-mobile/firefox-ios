// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation
import Glean
import XCTest

extension XCTestCase {
    func wait(_ timeout: TimeInterval) {
        let expectation = XCTestExpectation(description: "Waiting for \(timeout) seconds")
        XCTWaiter().wait(for: [expectation], timeout: timeout)
    }

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated, potential memory leak.",
                file: file,
                line: line
            )
        }
    }

    /// Unwraps un async method return value.
    ///
    /// It is a wrapper of XCTUnwrap. Since is not possible to do ```XCTUnwrap(await asyncMethod())```
    ///
    /// it has to be done always in two steps, this method make it one line for users.
    func unwrapAsync<T>(asyncMethod: () async throws -> T?,
                        file: StaticString = #filePath,
                        line: UInt = #line) async throws -> T {
        let returnValue = try await asyncMethod()
        return try XCTUnwrap(returnValue, file: file, line: line)
    }

    /// Helper function to cast a value to `AnyHashable`.
    func asAnyHashable<T>(_ value: T) -> AnyHashable? {
        return value as? AnyHashable
    }

    /// Helper function to ensure Glean telemetry is setup for unit tests
    /// This should not be called in new code:
    /// - We should us GleanWrapper or mock objects instead of concrete type testing for Glean
    func setupTelemetry(with profile: Profile) {
        TelemetryWrapper.hasTelemetryOverride = true

        DependencyHelperMock().bootstrapDependencies()
        TelemetryWrapper().initGlean(profile, sendUsageData: false)

        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    /// Helper function to ensure Glean telemetry is properly teardown for unit tests
    func tearDownTelemetry() {
        TelemetryWrapper.hasTelemetryOverride = false
        DependencyHelperMock().reset()
    }
}
