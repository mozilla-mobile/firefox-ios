// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class EngagementNotificationHelper: FeatureFlaggable {
    private let timeUntilNotification = UInt64(60 * 60 * 48 * 1000) // 48 hours in milliseconds
    private let twentyFourHours = UInt64(60 * 60 * 24 * 1000) // 24 hours in milliseconds
    private var notificationManager: NotificationManagerProtocol
    private var firstAppUse: Timestamp?
    private let notificationId = "org.mozilla.ios.engagementNotification"

    private lazy var featureEnabled: Bool = featureFlags.isFeatureEnabled(.engagementNotificationStatus,
                                                                          checking: .buildOnly)

    init(profile: Profile?, notificationManager: NotificationManagerProtocol = NotificationManager()) {
        self.firstAppUse = profile?.prefs.timestampForKey(PrefsKeys.KeyFirstAppUse)
        self.notificationManager = notificationManager
    }

    func schedule() {
        guard featureEnabled else { return }

        notificationManager.hasPermission { [weak self] hasPermission in
            guard hasPermission else { return }
            self?.scheduleNotification()
        }
    }

    // MARK: - Private
    private func scheduleNotification() {
        // existing users don't have firstAppUse set so we skip them, only new users get engagement notification
        guard let firstAppUse = firstAppUse else { return }

        let now = Date()
        let notificationDate = Date.fromTimestamp(firstAppUse + timeUntilNotification)

        // check that we are not past the time the notification was supposed to be send
        guard now < notificationDate else { return }

        // We don't care how often the user is active in the first 24 hours after first use.
        // If they are not active in the second 24 hours after first use we send them a notification.
        if now > Date.fromTimestamp(firstAppUse + twentyFourHours) {
            // cancel as user used app between firstAppUse + 24h and firstAppUse + 48h
            notificationManager.removePendingNotificationsWithId(ids: [notificationId])
            // add telemetry
        } else {
            // schedule or update notification
            notificationManager.schedule(title: .EngagementNotification.Title,
                                         body: .EngagementNotification.Body,
                                         id: notificationId,
                                         date: notificationDate,
                                         repeats: false)
        }
    }
}
