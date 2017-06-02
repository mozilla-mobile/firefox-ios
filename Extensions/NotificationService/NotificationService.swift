/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Sync
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var display: SyncDataDisplay!
    var profile: Profile!

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            return
        }

        let userInfo = request.content.userInfo
        NSLog("NotificationService APNS NOTIFICATION \(userInfo)")

        self.display = SyncDataDisplay(content: content, contentHandler: contentHandler)
        self.profile = ExtensionProfile(localName: "profile", delegate: display)

        let handler = FxAPushMessageHandler(with: profile)

        handler.handle(userInfo: userInfo).upon {_ in
            self.display.displayNotification(true)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        display?.displayNotification(false)
    }
}

class SyncDataDisplay {
    var contentHandler: ((UNNotificationContent) -> Void)
    var notificationContent: UNMutableNotificationContent
    var sentTabs: [ShareItem]

    init(content: UNMutableNotificationContent, contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.notificationContent = content
        self.sentTabs = []
    }

    func displayNotification(_ didFinish: Bool) {
        var userInfo = notificationContent.userInfo

        // Add the tabs we've found to userInfo, so that the AppDelegate 
        // doesn't have to do it again.
        let serializedTabs = sentTabs.flatMap { shareItem in
            return [
                "title": shareItem.title,
                "url": shareItem.url,
            ]
        }

        userInfo["sentTabs"] = serializedTabs

        userInfo["didFinish"] = didFinish

        // Increment the badges. This may cause us to find bugs with multiple 
        // notifications in the future.
        let badge = (notificationContent.badge?.intValue ?? 0) + sentTabs.count
        notificationContent.badge = NSNumber(value: badge)

        notificationContent.userInfo = userInfo

        switch sentTabs.count {
        case 0:
            notificationContent.title = "Firefox Accounts"
            notificationContent.body = "Tap to begin"
        case 1:
            let tab = sentTabs[0]
            let title = tab.title ?? "a tab"
            notificationContent.title = "Tap to open \(title)"
            notificationContent.body = "\(tab.url)"
        default:
            notificationContent.title = "Received \(sentTabs.count) tabs"
            notificationContent.body = "Tap to open"
        }

        contentHandler(notificationContent)
    }
}

extension SyncDataDisplay: SyncDelegate {
    func displaySentTabForURL(_ URL: URL, title: String) {
        if URL.isWebPage() {
            sentTabs.append(ShareItem(url: URL.absoluteString, title: title, favicon: nil))
        }
    }
}
