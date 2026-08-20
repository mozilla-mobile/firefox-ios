// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

@MainActor
final class MockVPNManager: VPNManaging {
    var isRunning = false
    var startCalled = 0
    var stopCalled = 0

    /// When set, `start()` leaves `isRunning` false, mimicking a failed Guardian handshake.
    var shouldFailToStart = false

    func start() async {
        startCalled += 1
        isRunning = !shouldFailToStart
    }

    func stop() async {
        stopCalled += 1
        isRunning = false
    }
}
