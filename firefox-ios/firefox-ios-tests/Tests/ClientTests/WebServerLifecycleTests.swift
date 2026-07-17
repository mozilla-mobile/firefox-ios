// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class WebServerLifecycleTests: XCTestCase {
    /// `stop` does its blocking work off the main thread but must hand control back on the
    /// main thread, since callers (AppDelegate) end a `UIBackgroundTask`/touch UIKit there.
    func test_stop_invokesCompletionOnTheMainThread() {
        let subject = WebServer()
        let completionRun = expectation(description: "stop completion runs")

        subject.stop {
            XCTAssertTrue(Thread.isMainThread)
            completionRun.fulfill()
        }

        wait(for: [completionRun], timeout: 5)
    }

    /// Stopping a server that was never started is a no-op and must not crash.
    func test_stop_withoutCompletion_doesNotCrash() {
        let subject = WebServer()
        subject.stop(completion: nil)

        // Enqueue a second stop with a completion: because the lifecycle queue is serial,
        // this only runs once the first stop has finished, proving it completed cleanly.
        let drained = expectation(description: "lifecycle queue drains")
        subject.stop { drained.fulfill() }
        wait(for: [drained], timeout: 5)
    }
}
