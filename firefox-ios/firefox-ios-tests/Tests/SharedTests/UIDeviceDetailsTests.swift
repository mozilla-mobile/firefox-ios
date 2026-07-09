// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Shared

final class UIDeviceDetailsTests: XCTestCase {
    static func getSystemInfo() -> String {
        let device = UIDeviceDetails.model
        let system = device == "iPad" ? "CPU" : "CPU iPhone"
        return "(\(device); \(system) OS 18_7 like Mac OS X)"
    }

    // MARK: Test calling a function that uses UIDeviceDetails from the main thread
    func testUIDeviceDetails_onMainThreadGCDAsync_callsUIDeviceDetails_getMainThreadDataSynchronously() {
        let exp = expectation(description: "Main thread work completed")

        // Test dispatch to main thread with GCD
        DispatchQueue.main.async {
            _ = Self.getSystemInfo()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 3)
    }

    func testUIDeviceDetails_onMainThreadSyncGCD_callsUIDeviceDetails_getMainThreadDataSynchronously() {
        let exp = expectation(description: "Main thread work completed")

        // This test may run on the MT. It is an error to dispatch .sync when already on the MT.
        // So offload this to a background thread first.
        DispatchQueue.global().async {
            // Test dispatch to main thread with GCD
            DispatchQueue.main.sync {
                _ = Self.getSystemInfo()
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 3)
    }

    @MainActor
    func testUIDeviceDetails_onMainActor_callsUIDeviceDetails_getMainThreadDataSynchronously() {
        let exp = expectation(description: "Main thread work completed")

        // Test dispatch to main thread with GCD
        DispatchQueue.main.async {
            _ = Self.getSystemInfo()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 3)
    }

    func testUIDeviceDetails_onMainThreadTask_callsUIDeviceDetails_getMainThreadDataSynchronously() {
        let exp = expectation(description: "Main thread work completed")

        // Test dispatch to main thread with GCD
        Task { @MainActor in
            _ = Self.getSystemInfo()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 3)
    }
}
