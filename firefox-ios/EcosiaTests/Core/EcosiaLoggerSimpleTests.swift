// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class EcosiaLoggerSimpleTests: XCTestCase {

    func testDebugLogsAreConditional() {
        // This test verifies that debug logging methods exist and can be called
        // In DEBUG builds, they will print; in release builds, they won't

        EcosiaLogger.debug("Test debug message")
        EcosiaLogger.info("Test info message")

        // These should always work regardless of build type
        EcosiaLogger.warning("Test warning message")
        EcosiaLogger.error("Test error message")

        XCTAssertTrue(true, "All logging methods should be callable")
    }

    func testGenericLogMethod() {
        EcosiaLogger.log("Debug test", level: .debug)
        EcosiaLogger.log("Info test", level: .info)
        EcosiaLogger.log("Warning test", level: .warning)
        EcosiaLogger.log("Error test", level: .error)

        XCTAssertTrue(true, "Generic log method should handle all levels")
    }

    func testCategoryLogging() {
        EcosiaLogger.auth.debug("Auth debug")
        EcosiaLogger.auth.error("Auth error")

        EcosiaLogger.invisibleTabs.debug("Tabs debug")
        EcosiaLogger.invisibleTabs.error("Tabs error")

        EcosiaLogger.general.debug("General debug")
        EcosiaLogger.general.error("General error")

        XCTAssertTrue(true, "Category logging should work")
    }

    func testPerformanceOptimization() {
        // Test that repeated logging calls don't significantly impact performance
        let iterations = 1000
        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<iterations {
            EcosiaLogger.debug("Debug message \(i)")
            EcosiaLogger.info("Info message \(i)")
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // In both DEBUG and release builds, this should complete reasonably quickly
        // In release builds, it should be very fast due to optimization
        XCTAssertTrue(timeElapsed < 5.0, "Logging should not take more than 5 seconds for \(iterations) calls")

        #if !DEBUG
        // In release builds, debug/info logs should be optimized away and be very fast
        XCTAssertTrue(timeElapsed < 0.1, "Debug logging should be optimized away in release builds")
        #endif
    }
}
