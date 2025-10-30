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
        case StoriesFeedActionType.storiesImpression:
            testTelemetryCase()
        default:
            break
        }
    }

    private func testTelemetryCase() {
        print("adudenamedruby - I AM HERE!")
    }
}
