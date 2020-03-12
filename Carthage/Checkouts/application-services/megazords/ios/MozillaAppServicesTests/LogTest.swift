import Foundation
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import XCTest

@testable import MozillaAppServices

class LogTests: XCTestCase {
    func writeTestLog(_ message: String) {
        RustLog.shared.logTestMessage(message: message)
        // Wait for the log to come in. Cludgey but good enough.
        Thread.sleep(forTimeInterval: 0.1)
        // Force us to synchronize on the queue.
        _ = RustLog.shared.isEnabled
    }

    func testLogging() {
        var logs: [(LogLevel, String?, String)] = []

        assert(!RustLog.shared.isEnabled)

        try! RustLog.shared.enable { level, tag, msg in
            let info = "Rust | Level: \(level) | tag: \(String(describing: tag)) | message: \(msg)"
            print(info)
            logs.append((level, tag, msg))
            return true
        }

        // We log an informational message after initializing (but it's processed asynchronously).
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssert(RustLog.shared.isEnabled)
        XCTAssertEqual(logs.count, 1)
        writeTestLog("Test1")
        XCTAssertEqual(logs.count, 2)
        do {
            try RustLog.shared.enable { _, _, _ in true }
            XCTFail("Enable should fail")
        } catch let error as RustLogError {
            switch error {
            case .alreadyEnabled:
                print("enable failed as it should")
            default:
                XCTFail("Wrong RustLogError: \(error)")
            }
        } catch {
            XCTFail("Wrong error: \(error)")
        }
        // tryEnable should return false
        XCTAssert(!RustLog.shared.tryEnable { _, _, _ in true })

        // Adjust the max level so that the test log (which is logged at info level)
        // will not be present.
        try! RustLog.shared.setLevelFilter(filter: .warn)
        writeTestLog("Test2")
        // Should not increase
        XCTAssertEqual(logs.count, 2)
        try! RustLog.shared.setLevelFilter(filter: .info)
        writeTestLog("Test3")
        XCTAssertEqual(logs.count, 3)

        RustLog.shared.disable()
        XCTAssert(!RustLog.shared.isEnabled)

        // Shouldn't do anything, we disabled the log.
        writeTestLog("Test4")

        XCTAssertEqual(logs.count, 3)
        var counter = 0
        let didEnable = RustLog.shared.tryEnable { level, tag, msg in
            let info = "Rust | Level: \(level) | tag: \(String(describing: tag)) | message: \(msg)"
            print(info)
            logs.append((level, tag, msg))
            counter += 1
            if counter == 3 {
                // Test disabling from inside log callback
                print("Disabling log from inside callback")
                return false
            } else {
                return true
            }
        }
        XCTAssert(didEnable)
        // Wait for the 'we enabled logging' log to come in asynchronously
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssert(RustLog.shared.isEnabled)
        XCTAssertEqual(logs.count, 4)

        writeTestLog("Test5")
        XCTAssertEqual(logs.count, 5)

        writeTestLog("Test6")
        XCTAssertEqual(logs.count, 6)
        // Should be disabled now,
        XCTAssert(!RustLog.shared.isEnabled)
    }
}
