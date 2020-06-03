/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import Sync
import XCGLogger
import UserNotifications
import Account

private let log = Logger.browserLogger

extension UIApplication {
    var syncDelegate: SyncDelegate {
        return AppSyncDelegate(app: self)
    }
}

/**
 Sent tabs can be displayed not only by receiving push notifications, but by sync.
 Sync will get the list of sent tabs, and try to display any in that list.
 Thus, push notifications are not needed to receive sent tabs, they can be handled
 when the app performs a sync.
 */
class AppSyncDelegate: SyncDelegate {
    let app: UIApplication

    init(app: UIApplication) {
        self.app = app
    }

    func displaySentTab(for url: URL, title: String, from deviceName: String?) {
        DispatchQueue.main.sync {
            if app.applicationState == .active {
                BrowserViewController.foregroundBVC().switchToTabForURLOrOpen(url)
                return
            }

            // check to see what the current notification settings are and only try and send a notification if
            // the user has agreed to them
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.alertSetting != .enabled {
                    return
                }
                if Logger.logPII {
                    log.info("Displaying notification for URL \(url.absoluteString)")
                }

                let notificationContent = UNMutableNotificationContent()
                let title: String
                if let deviceName = deviceName {
                    title = String(format: Strings.SentTab_TabArrivingNotification_WithDevice_title, deviceName)
                } else {
                    title = Strings.SentTab_TabArrivingNotification_NoDevice_title
                }
                notificationContent.title = title
                notificationContent.body = url.absoluteDisplayExternalString
                notificationContent.userInfo = [SentTabAction.TabSendURLKey: url.absoluteString, SentTabAction.TabSendTitleKey: title]
                notificationContent.categoryIdentifier = "org.mozilla.ios.SentTab.placeholder"

                // `timeInterval` must be greater than zero
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

                // The identifier for each notification request must be unique in order to be created
                let requestIdentifier = "\(SentTabAction.TabSendCategory).\(url.absoluteString)"
                let request = UNNotificationRequest(identifier: requestIdentifier, content: notificationContent, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        log.error(error.localizedDescription)
                    }
                }
            }
        }
    }
}
