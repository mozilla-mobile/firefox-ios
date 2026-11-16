// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Consumes browser data transfer activities before generic scene routing. Activities for a direction
/// that is not available are dropped without any UI or transfer work.
@MainActor
struct BrowserDataTransferActivityHandler {
    private let availability: BrowserDataTransferAvailability
    private let logger: Logger

    init(
        availability: BrowserDataTransferAvailability = BrowserDataTransferAvailability(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.availability = availability
        self.logger = logger
    }

    /// Returns `true` when the activity is a browser data transfer activity, whether or not it was acted on.
    func handle(_ userActivity: NSUserActivity) -> Bool {
        guard let direction = BrowserDataTransferDirection(activityType: userActivity.activityType) else {
            return false
        }

        guard availability.isAvailable(direction) else {
            logger.log("Ignoring unavailable browser data transfer activity", level: .info, category: .lifecycle)
            return true
        }

        return true
    }

    /// Handles every transfer activity in a cold-launch set and returns the activities left for generic routing.
    func routableActivities(from userActivities: Set<NSUserActivity>) -> Set<NSUserActivity> {
        return userActivities.filter { !handle($0) }
    }
}
