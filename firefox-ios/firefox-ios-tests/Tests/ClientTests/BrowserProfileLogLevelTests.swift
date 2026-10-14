// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import XCTest

import enum MozillaAppServices.Level

final class BrowserProfileLogLevelTests: XCTestCase {
    func testDefaultsToInfoWhenArgumentIsAbsent() {
        XCTAssertEqual(BrowserProfile.appServicesLogLevel(from: []), .info)
        XCTAssertEqual(BrowserProfile.appServicesLogLevel(from: [LaunchArguments.Test]), .info)
    }

    func testReturnsDebugLevel() {
        let arguments = [LaunchArguments.Test, "\(LaunchArguments.SyncLogLevelPrefix)debug"]

        XCTAssertEqual(BrowserProfile.appServicesLogLevel(from: arguments), .debug)
    }

    func testReturnsTraceLevel() {
        let arguments = ["\(LaunchArguments.SyncLogLevelPrefix)trace", LaunchArguments.Test]

        XCTAssertEqual(BrowserProfile.appServicesLogLevel(from: arguments), .trace)
    }

    func testDefaultsToInfoForUnrecognizedValue() {
        XCTAssertEqual(BrowserProfile.appServicesLogLevel(from: ["\(LaunchArguments.SyncLogLevelPrefix)verbose"]), .info)
        XCTAssertEqual(BrowserProfile.appServicesLogLevel(from: ["\(LaunchArguments.SyncLogLevelPrefix)"]), .info)
        XCTAssertEqual(BrowserProfile.appServicesLogLevel(from: ["FIREFOX_SYNC_LOG_LEVEL"]), .info)
    }
}
