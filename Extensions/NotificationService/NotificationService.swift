/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import Sync
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var display: SyncDataDisplay!
    lazy var profile: ExtensionProfile = {
        NSLog("APNS ExtensionProfile being created…")
        let profile = ExtensionProfile(localName: "profile")
        NSLog("APNS ExtensionProfile … now created")
        return profile
    }()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            return
        }

        let userInfo = request.content.userInfo
        NSLog("NotificationService APNS NOTIFICATION \(userInfo)")

        let queue = self.profile.queue
        self.display = SyncDataDisplay(content: content, contentHandler: contentHandler, tabQueue: queue)
        self.profile.syncDelegate = display

        let handler = FxAPushMessageHandler(with: profile)

        handler.handle(userInfo: userInfo).upon { res in
            self.finished(cleanly: res.isSuccess)
        }
    }

    func finished(cleanly: Bool) {
        profile.shutdown()
        // We cannot use tabqueue after the profile has shutdown;
        // however, we can't use weak references, because TabQueue isn't a class.
        // Rather than changing tabQueue, we manually nil it out here.
        display.tabQueue = nil
        display.displayNotification(cleanly)
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        finished(cleanly: false)
    }
}

class SyncDataDisplay {
    var contentHandler: ((UNNotificationContent) -> Void)
    var notificationContent: UNMutableNotificationContent
    var sentTabs: [SentTab]

    var tabQueue: TabQueue?

    init(content: UNMutableNotificationContent, contentHandler: @escaping (UNNotificationContent) -> Void, tabQueue: TabQueue) {
        self.contentHandler = contentHandler
        self.notificationContent = content
        self.sentTabs = []
        self.tabQueue = tabQueue
    }

    func displayNotification(_ didFinish: Bool) {
        var userInfo = notificationContent.userInfo

        // Add the tabs we've found to userInfo, so that the AppDelegate 
        // doesn't have to do it again.
        let serializedTabs = sentTabs.flatMap { t -> NSDictionary? in
            return [
                "title": t.title,
                "url": t.url.absoluteString,
                ] as NSDictionary
            } as NSArray
        userInfo["sentTabs"] = serializedTabs

        userInfo["didFinish"] = didFinish

        // Increment the badges. This may cause us to find bugs with multiple 
        // notifications in the future.
        let badge = (notificationContent.badge?.intValue ?? 0) + sentTabs.count
        notificationContent.badge = NSNumber(value: badge)

        notificationContent.userInfo = userInfo

        let title: String
        let body: String

        if sentTabs.isEmpty {
            title = Strings.SentTab_NoTabArrivingNotification_title
            body = Strings.SentTab_NoTabArrivingNotification_body
        } else {
            let deviceNames = Set(sentTabs.flatMap { $0.deviceName })
            if let deviceName = deviceNames.first, deviceNames.count == 1 {
                title = String(format: Strings.SentTab_TabArrivingNotification_WithDevice_title, deviceName)
            } else {
                title = Strings.SentTab_TabArrivingNotification_NoDevice_title
            }

            if sentTabs.count == 1 {
                body = sentTabs[0].url.absoluteDisplayString
            } else if deviceNames.count == 0 {
                body = Strings.SentTab_TabArrivingNotification_NoDevice_body
            } else {
                body = String(format: Strings.SentTab_TabArrivingNotification_WithDevice_body, DeviceInfo.appName())
            }
        }

        notificationContent.title = title
        notificationContent.body = body

        contentHandler(notificationContent)
    }
}

extension SyncDataDisplay: SyncDelegate {
    func displaySentTab(for url: URL, title: String, from deviceName: String?) {
        if url.isWebPage() {
            sentTabs.append(SentTab(url: url, title: title, deviceName: deviceName))

            let item = ShareItem(url: url.absoluteString, title: title, favicon: nil)
            _ = tabQueue?.addToQueue(item)
        }
    }
}

struct SentTab {
    let url: URL
    let title: String
    let deviceName: String?
}
