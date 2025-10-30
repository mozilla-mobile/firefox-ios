// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

@MainActor
final class StoriesFeedTelemetryMiddleware {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    lazy var storiesFeedTelemetryProvider: Middleware<AppState> = { _, action in
        switch action.actionType {
        case StoriesFeedActionType.telemetry(let telemetryAction):
            self.handleTelemetry(action: telemetryAction)
        default:
            break
        }
    }

    private func handleTelemetry(action: StoriesFeedTelemetryAction) {
        switch action {
        case .storiesFeedClosed:
            storiesFeedClosed()
        case .storiesFeedViewed:
            storiesFeedViewed()
        case .storiesViewed(let index):
            sendImpressionTelemetryFor(storyIndex: index)
        case .tappedStory(let index):
            sendStoryTappedTelemetry(atIndex: index)
        }
    }

    private func sendImpressionTelemetryFor(storyIndex: Int) {
        print("RGB - impression at \(storyIndex)")
    }

    private func storiesFeedClosed() {
        print("RGB - Stories Feed Viewed")
    }

    private func storiesFeedViewed() {
        print("RGB - Stories Feed Viewed")
    }

    private func sendStoryTappedTelemetry(atIndex: Int) {
        print("RGB - story tapped at \(atIndex)")
    }
}
