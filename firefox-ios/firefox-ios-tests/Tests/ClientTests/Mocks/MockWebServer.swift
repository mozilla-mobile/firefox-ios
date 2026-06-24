// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import GCDWebServers
@testable import Client

final class MockWebServer: WebServerProtocol, @unchecked Sendable {
    let server = GCDWebServer()

    private(set) var startCalled = 0
    private(set) var startIfNeededCalled = 0
    private(set) var stopCalled = 0

    @discardableResult
    func start() throws -> Bool {
        startCalled += 1
        return true
    }

    func startIfNeeded() {
        startIfNeededCalled += 1
    }

    func stop(completion: (@Sendable () -> Void)?) {
        stopCalled += 1
        completion?()
    }
}
