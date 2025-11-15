// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

protocol StoriesFeedTelemetryProtocol {
    func sendStoryViewedTelemetryFor(storyIndex: Int)
    func storiesFeedClosed()
    func storiesFeedViewed()
    func sendStoryTappedTelemetry(atIndex: Int)
}

struct StoriesFeedTelemetry: StoriesFeedTelemetryProtocol {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func sendStoryViewedTelemetryFor(storyIndex: Int) {
        let extra = GleanMetrics.HomepageStoriesFeed.StoryViewedExtra(index: Int32(storyIndex + 1))
        gleanWrapper.recordEvent(for: GleanMetrics.HomepageStoriesFeed.storyViewed, extras: extra)
    }

    func storiesFeedClosed() {
        gleanWrapper.recordEvent(for: GleanMetrics.HomepageStoriesFeed.closed)
    }

    func storiesFeedViewed() {
        gleanWrapper.recordEvent(for: GleanMetrics.HomepageStoriesFeed.viewed)
    }

    func sendStoryTappedTelemetry(atIndex: Int) {
        let extra = GleanMetrics.HomepageStoriesFeed.StoryTappedExtra(index: Int32(atIndex + 1))
        gleanWrapper.recordEvent(for: GleanMetrics.HomepageStoriesFeed.storyTapped, extras: extra)
    }
}
