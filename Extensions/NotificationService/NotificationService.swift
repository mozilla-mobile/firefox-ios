/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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

        guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            return self.didFinish(PushMessage.accountVerified)
        }

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
        profile?.shutdown()

        guard let display = self.display else {
            return
        }

        // We cannot use tabqueue after the profile has shutdown;
        // however, we can't use weak references, because TabQueue isn't a class.
        // Rather than changing tabQueue, we manually nil it out here.
        display.tabQueue = nil
        display.messageDelivered = false
        display.displayNotification(what, with: error)
        if !display.messageDelivered {
            display.displayUnknownMessageNotification()
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
    }

    func displayNotification(_ message: PushMessage? = nil, with error: PushMessageError? = nil) {
        guard let message = message, error == nil else {
            return displayUnknownMessageNotification()
        }

        switch message {
        case .accountVerified:
            displayAccountVerifiedNotification()
        case .deviceConnected(let deviceName):
            displayDeviceConnectedNotification(deviceName)
        case .deviceDisconnected(let deviceName):
            displayDeviceDisconnectedNotification(deviceName)
        case .thisDeviceDisconnected:
            displayThisDeviceDisconnectedNotification()
        case .collectionChanged(let collections):
            if collections.contains("clients") {
                displaySentTabNotification()
            } else {
                displayUnknownMessageNotification()
            }
        default:
            displayUnknownMessageNotification()
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
        presentNotification(title: Strings.SentTab_NoTabArrivingNotification_title, body: Strings.SentTab_NoTabArrivingNotification_body)
    }

    func displayUnknownMessageNotification() {
        // if, by any change we haven't dealt with the message, then perhaps we
        // can recycle it as a sent tab message.
        if sentTabs.count > 0 {
            displaySentTabNotification()
        } else {
            presentNotification(title: Strings.SentTab_NoTabArrivingNotification_title, body: Strings.SentTab_NoTabArrivingNotification_body)
        }
    }
}

extension SyncDataDisplay {
    func displaySentTabNotification() {
        // We will need to be more precise about calling these SentTab alerts
        // once we are a) detecting different types of notifications and b) adding actions.
        // For now, we need to add them so we can handle zero-tab sent-tab-notifications.
        notificationContent.categoryIdentifier = "org.mozilla.ios.SentTab.placeholder"

        var userInfo = notificationContent.userInfo

        // Add the tabs we've found to userInfo, so that the AppDelegate
        // doesn't have to do it again.
        let serializedTabs = sentTabs.flatMap { t -> NSDictionary? in
            return [
                "title": t.title,
                "url": t.url.absoluteString,
                "displayURL": t.url.absoluteDisplayExternalString,
                "deviceName": t.deviceName as Any,
                ] as NSDictionary
        }

        func present(_ tabs: [NSDictionary]) {
            if !tabs.isEmpty {
                userInfo["sentTabs"] = tabs as NSArray
            }
            notificationContent.userInfo = userInfo
            presentSentTabsNotification(tabs)
        }

        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications { notifications in
            // Let's deal with sent-tab-notifications
            let sentTabNotifications = notifications.filter {
                $0.request.content.categoryIdentifier == self.notificationContent.categoryIdentifier
            }

            // We can delete zero tab sent-tab-notifications
            let emptyTabNotificationsIds = sentTabNotifications.filter {
                $0.request.content.userInfo["sentTabs"] == nil
                }.map { $0.request.identifier }
            center.removeDeliveredNotifications(withIdentifiers: emptyTabNotificationsIds)

            // The one we've just received (but not delivered) may not have any tabs in it either
            // e.g. if the previous one consumed two tabs.
            if serializedTabs.count == 0 {
                // In that case, we try and recycle an existing notification (one that has a tab in it).
                if let firstNonEmpty = sentTabNotifications.first(where: { $0.request.content.userInfo["sentTabs"] != nil }),
                    let previouslyDeliveredTabs = firstNonEmpty.request.content.userInfo["sentTabs"] as? [NSDictionary] {
                    center.removeDeliveredNotifications(withIdentifiers: [firstNonEmpty.request.identifier])
                    return present(previouslyDeliveredTabs)
                }
            }

            // We have tabs in this notification, or we couldn't recycle an existing one that does.
            present(serializedTabs)
        }
    }

    func presentSentTabsNotification(_ tabs: [NSDictionary]) {
        let title: String
        let body: String

        if tabs.count == 0 {
            title = Strings.SentTab_NoTabArrivingNotification_title
            body = Strings.SentTab_NoTabArrivingNotification_body
        } else {
            let deviceNames = Set(tabs.flatMap { $0["deviceName"] as? String })
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
            _ = tabQueue?.addToQueue(item)
        }
    }
}

struct SentTab {
    let url: URL
    let title: String
    let deviceName: String?
}
