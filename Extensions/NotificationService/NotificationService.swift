/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Shared
import Storage
import Sync
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var display: SyncDataDisplay?
    var profile: ExtensionProfile?

    // This is run when an APNS notification with `mutable-content` is received.
    // If the app is backgrounded, then the alert notification is displayed.
    // If the app is foregrounded, then the notification.userInfo is passed straight to
    // AppDelegate.application(_:didReceiveRemoteNotification:completionHandler:)
    // Once the notification is tapped, then the same userInfo is passed to the same method in the AppDelegate.
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        let userInfo = request.content.userInfo

        let content = request.content.mutableCopy() as! UNMutableNotificationContent

        if self.profile == nil {
            self.profile = ExtensionProfile(localName: "profile")
        }

        guard let profile = self.profile else {
            self.didFinish(with: .noProfile)
            return
        }

        let queue = profile.queue
        let display = SyncDataDisplay(content: content, contentHandler: contentHandler, tabQueue: queue)
        self.display = display
        profile.syncDelegate = display

        let handler = FxAPushMessageHandler(with: profile)

        handler.handle(userInfo: userInfo).upon { res in
            self.didFinish(res.successValue, with: res.failureValue as? PushMessageError)
        }
    }

    func didFinish(_ what: PushMessage? = nil, with error: PushMessageError? = nil) {
        defer {
            // We cannot use tabqueue after the profile has shutdown;
            // however, we can't use weak references, because TabQueue isn't a class.
            // Rather than changing tabQueue, we manually nil it out here.
            self.display?.tabQueue = nil

            profile?._shutdown()
        }

        guard let display = self.display else {
            return
        }

        display.messageDelivered = false
        display.displayNotification(what, profile: profile, with: error)
        if !display.messageDelivered {
            display.displayUnknownMessageNotification(debugInfo: "Not delivered")
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        didFinish(with: .timeout)
    }
}

class SyncDataDisplay {
    var contentHandler: ((UNNotificationContent) -> Void)
    var notificationContent: UNMutableNotificationContent
    var sentTabs: [SentTab]

    var tabQueue: TabQueue?
    var messageDelivered: Bool = false

    init(content: UNMutableNotificationContent, contentHandler: @escaping (UNNotificationContent) -> Void, tabQueue: TabQueue) {
        self.contentHandler = contentHandler
        self.notificationContent = content
        self.sentTabs = []
        self.tabQueue = tabQueue
        Sentry.shared.setup(sendUsageData: true)
    }

    func displayNotification(_ message: PushMessage? = nil, profile: ExtensionProfile?, with error: PushMessageError? = nil) {
        guard let message = message, error == nil else {
            return displayUnknownMessageNotification(debugInfo: "Error \(error?.description ?? "")")
        }

        switch message {
        case .commandReceived(let tab):
            displayNewSentTabNotification(tab: tab)
        case .deviceConnected(let deviceName):
            displayDeviceConnectedNotification(deviceName)
        case .deviceDisconnected(let deviceName):
            displayDeviceDisconnectedNotification(deviceName)
        case .thisDeviceDisconnected:
            displayThisDeviceDisconnectedNotification()
        default:
            displayUnknownMessageNotification(debugInfo: "Unknown: \(message)")
            break
        }
    }
}

extension SyncDataDisplay {
    func displayDeviceConnectedNotification(_ deviceName: String) {
        presentNotification(title: Strings.FxAPush_DeviceConnected_title,
                            body: Strings.FxAPush_DeviceConnected_body,
                            bodyArg: deviceName)
    }

    func displayDeviceDisconnectedNotification(_ deviceName: String?) {
        if let deviceName = deviceName {
            presentNotification(title: Strings.FxAPush_DeviceDisconnected_title,
                                body: Strings.FxAPush_DeviceDisconnected_body,
                                bodyArg: deviceName)
        } else {
            // We should never see this branch
            presentNotification(title: Strings.FxAPush_DeviceDisconnected_title,
                                body: Strings.FxAPush_DeviceDisconnected_UnknownDevice_body)
        }
    }

    func displayThisDeviceDisconnectedNotification() {
        presentNotification(title: Strings.FxAPush_DeviceDisconnected_ThisDevice_title,
                            body: Strings.FxAPush_DeviceDisconnected_ThisDevice_body)
    }

    func displayAccountVerifiedNotification() {
        #if MOZ_CHANNEL_BETA || DEBUG
            presentNotification(title: Strings.SentTab_NoTabArrivingNotification_title, body: "DEBUG: Account Verified")
            return
        #endif
        presentNotification(title: Strings.SentTab_NoTabArrivingNotification_title, body: Strings.SentTab_NoTabArrivingNotification_body)
    }

    func displayUnknownMessageNotification(debugInfo: String) {
        #if MOZ_CHANNEL_BETA || DEBUG
            presentNotification(title: Strings.SentTab_NoTabArrivingNotification_title, body: "DEBUG: " + debugInfo)
            Sentry.shared.send(message: "SentTab error: \(debugInfo)")
            return
        #endif

        presentNotification(title: Strings.SentTab_NoTabArrivingNotification_title, body: Strings.SentTab_NoTabArrivingNotification_body)
    }
}

extension SyncDataDisplay {
    func displayNewSentTabNotification(tab: [String: String]) {
        if let urlString = tab["url"], let url = URL(string: urlString), url.isWebPage(), let title = tab["title"] {
            let tab = [
                "title": title,
                "url": url.absoluteString,
                "displayURL": url.absoluteDisplayExternalString,
                "deviceName": nil
            ] as NSDictionary

            notificationContent.userInfo["sentTabs"] = [tab] as NSArray

            // Add tab to the queue.
            let item = ShareItem(url: urlString, title: title, favicon: nil)
            _ = tabQueue?.addToQueue(item).value // Force synchronous.

            presentNotification(title: Strings.SentTab_TabArrivingNotification_NoDevice_title, body: url.absoluteDisplayExternalString)
        }
    }
}

extension SyncDataDisplay {
    func presentSentTabsNotification(_ tabs: [NSDictionary]) {
        let title: String
        let body: String

        if tabs.count == 0 {
            title = Strings.SentTab_NoTabArrivingNotification_title
            #if MOZ_CHANNEL_BETA || DEBUG
                body = "DEBUG: Sent Tabs with no tab"
                Sentry.shared.send(message: "SentTab error: no tab")
            #else
                body = Strings.SentTab_NoTabArrivingNotification_body
            #endif
        } else {
            let deviceNames = Set(tabs.compactMap { $0["deviceName"] as? String })
            if let deviceName = deviceNames.first, deviceNames.count == 1 {
                title = String(format: Strings.SentTab_TabArrivingNotification_WithDevice_title, deviceName)
            } else {
                title = Strings.SentTab_TabArrivingNotification_NoDevice_title
            }

            if tabs.count == 1 {
                // We give the fallback string as the url,
                // because we have only just introduced "displayURL" as a key.
                body = (tabs[0]["displayURL"] as? String) ??
                    (tabs[0]["url"] as! String)
            } else if deviceNames.count == 0 {
                body = Strings.SentTab_TabArrivingNotification_NoDevice_body
            } else {
                body = String(format: Strings.SentTab_TabArrivingNotification_WithDevice_body, AppInfo.displayName)
            }
        }

        presentNotification(title: title, body: body)
    }

    func presentNotification(title: String, body: String, titleArg: String? = nil, bodyArg: String? = nil) {
        func stringWithOptionalArg(_ s: String, _ a: String?) -> String {
            if let a = a {
                return String(format: s, a)
            }
            return s
        }

        notificationContent.title = stringWithOptionalArg(title, titleArg)
        notificationContent.body = stringWithOptionalArg(body, bodyArg)

        // This is the only place we call the contentHandler.
        contentHandler(notificationContent)
        // This is the only place we change messageDelivered. We can check if contentHandler hasn't be called because of
        // our logic (rather than something funny with our environment, or iOS killing us).
        messageDelivered = true
    }
}

extension SyncDataDisplay: SyncDelegate {
    func displaySentTab(for url: URL, title: String, from deviceName: String?) {
        if url.isWebPage() {
            sentTabs.append(SentTab(url: url, title: title, deviceName: deviceName))

            let item = ShareItem(url: url.absoluteString, title: title, favicon: nil)
            _ = tabQueue?.addToQueue(item).value // Force synchronous.
        }
    }
}

struct SentTab {
    let url: URL
    let title: String
    let deviceName: String?
}
