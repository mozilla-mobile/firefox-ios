// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation

@MainActor
final class MockWorldCupFeed: WorldCupFeedProtocol {
    var onUpdate: ((WorldCupFeed.Snapshot) -> Void)?
    var latestSnapshot: WorldCupFeed.Snapshot = .empty

    private(set) var startCalled = 0
    private(set) var stopCalled = 0

    func start() {
        startCalled += 1
    }

    func stop() {
        stopCalled += 1
    }
}
