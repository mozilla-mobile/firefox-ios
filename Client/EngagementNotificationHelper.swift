// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class EngagementNotificationHelper: FeatureFlaggable {
    struct Constant {
        #if MOZ_CHANNEL_FENNEC
        // shorter time interval for development
        static let timeUntilNotification: UInt64 = UInt64(60 * 2 * 1000) // 2 minutes in milliseconds
        static let twentyFourHours: UInt64 = timeUntilNotification / 2 // 1 minutes in milliseconds
        #else
        static let timeUntilNotification: UInt64 = UInt64(60 * 60 * 48 * 1000) // 48 hours in milliseconds
        static let twentyFourHours: UInt64 = UInt64(60 * 60 * 24 * 1000) // 24 hours in milliseconds
        #endif
        static let notificationId: String = "org.mozilla.ios.engagementNotification"
    }

    private var notificationManager: NotificationManagerProtocol
    private var prefs: Prefs?
    private var firstAppUse: Timestamp? {
        return prefs?.timestampForKey(PrefsKeys.KeyFirstAppUse)
    }
    private lazy var featureEnabled: Bool = featureFlags.isFeatureEnabled(.engagementNotificationStatus,
                                                                          checking: .buildOnly)
    private var allowedTipsNotifications: Bool {
        let featureEnabled = featureFlags.isFeatureEnabled(.notificationSettings, checking: .buildOnly)
        let userPreference = prefs?.boolForKey(PrefsKeys.Notifications.TipsAndFeaturesNotifications) ?? true
        return featureEnabled && userPreference
    }

    init(prefs: Prefs?, notificationManager: NotificationManagerProtocol = NotificationManager()) {
        self.prefs = prefs
        self.notificationManager = notificationManager
    }

    func schedule() {
        guard featureEnabled else { return }

        // schedule notifications only if notification permission was granted and the tips notifications are allowed
        notificationManager.hasPermission { [weak self] hasPermission in
            guard let self = self, hasPermission, self.allowedTipsNotifications
            else { return }
            self.scheduleNotification()
        }
    }

    func cancelAll() {
        notificationManager.removePendingNotificationsWithId(ids: [Constant.notificationId])
    }

    // MARK: - Private
    private func scheduleNotification() {
        // existing users don't have firstAppUse set so we skip them, only new users get engagement notification
        guard let firstAppUse = firstAppUse else { return }

        let now = Date()
        let notificationDate = Date.fromTimestamp(firstAppUse + Constant.timeUntilNotification)

        // check that we are not past the time the notification was supposed to be send
        guard now < notificationDate else { return }

        // We don't care how often the user is active in the first 24 hours after first use.
        // If they are not active in the second 24 hours after first use we send them a notification.
        if now > Date.fromTimestamp(firstAppUse + Constant.twentyFourHours) {
            // cancel as user used app between firstAppUse + 24h and firstAppUse + 48h
            cancelAll()
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .cancel,
                                         object: .engagementNotification)
        } else {
            // schedule or update notification
            notificationManager.schedule(title: .EngagementNotification.Title,
                                         body: .EngagementNotification.Body,
                                         id: Constant.notificationId,
                                         date: notificationDate,
                                         repeats: false)
        }
    }
}
