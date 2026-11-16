// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

@MainActor
final class MockVPNManager: VPNRunnable {
    var isRunning = false
    var startCalled = 0
    var stopCalled = 0
    var onStop: (() -> Void)?
    var onStart: (() -> Void)?
    var startError: Error?
    let eventsStream = AsyncStream<VPNEvent>.makeStream()

    var events: AsyncStream<VPNEvent> {
        eventsStream.stream
    }

    func start() async throws {
        startCalled += 1
        onStart?()
        if let startError { throw startError }
        isRunning = true
    }

    func stop() async {
        stopCalled += 1
        isRunning = false
        onStop?()
    }
}
