// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

final class MockStoriesFeedTelemetry: StoriesFeedTelemetryProtocol {
    var sendStoryViewedTelemetryForCalled = 0
    var storiesFeedClosedCalled = 0
    var storiesFeedViewedCalled = 0
    var sendStoryTappedTelemetryCalled = 0

    var lastStoryIndex: Int?
    var lastAtIndex: Int?

    func sendStoryViewedTelemetryFor(storyIndex: Int) {
        sendStoryViewedTelemetryForCalled += 1
        lastStoryIndex = storyIndex
    }

    func storiesFeedClosed() {
        storiesFeedClosedCalled += 1
    }

    func storiesFeedViewed() {
        storiesFeedViewedCalled += 1
    }

    func sendStoryTappedTelemetry(atIndex: Int) {
        sendStoryTappedTelemetryCalled += 1
        lastAtIndex = atIndex
    }
}
