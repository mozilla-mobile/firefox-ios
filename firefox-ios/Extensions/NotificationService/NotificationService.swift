// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Account
import Shared
import UserNotifications
import MozillaAppServices

class NotificationService: UNNotificationServiceExtension {
    var display: SyncDataDisplay?
    var profile: BrowserProfile?

    // This is run when an APNS notification with `mutable-content` is received.
    // If the app is backgrounded, then the alert notification is displayed.
    // If the app is foregrounded, then the notification.userInfo is passed straight to
    // AppDelegate.application(_:didReceiveRemoteNotification:completionHandler:)
    // Once the notification is tapped, then the same userInfo is passed to the same method in the AppDelegate.
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        // Set-up Rust network stack. This is needed in addition to the call
        // from the AppDelegate due to the fact that this uses a separate process
        Viaduct.shared.useReqwestBackend()
        MozillaAppServices.initialize()

        let userInfo = request.content.userInfo

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }

        if self.profile == nil {
            self.profile = BrowserProfile(localName: "profile")
        }

        guard let profile = self.profile else {
            self.didFinish(with: .noProfile)
            return
        }

        let display = SyncDataDisplay(content: content, contentHandler: contentHandler)
        self.display = display
        let handlerCompletion = { (result: Result<PushMessage, PushMessageError>) in
            guard case .success(let event) = result else {
                if case .failure(let failure) = result {
                    self.didFinish(nil, with: failure)
                }
                return
            }
            self.didFinish(event)
        }
        self.handleEncryptedPushMessage(userInfo: userInfo, profile: profile, completion: handlerCompletion)
    }

    func handleEncryptedPushMessage(userInfo: [AnyHashable: Any],
                                    profile: BrowserProfile,
                                    completion: @escaping (Result<PushMessage, PushMessageError>) -> Void
    ) {
        Task {
            do {
                let autopush = try await Autopush(files: profile.files)
                var payload = [String: String]()
                for (key, value) in userInfo {
                    if let key = key as? String, let value = value as? String {
                        payload[key] = value
                    }
                }
                let decryptResult = try await autopush.decrypt(payload: payload)
                guard let decryptedString = String(
                    bytes: decryptResult.result.map { byte in UInt8(bitPattern: byte) },
                    encoding: .utf8
                ) else {
                    completion(.failure(.notDecrypted))
                    return
                }
                if decryptResult.scope == RustFirefoxAccounts.pushScope {
                    let handler = FxAPushMessageHandler(with: profile)
                    handler.handleDecryptedMessage(message: decryptedString, completion: completion)
                } else {
                    completion(.failure(.messageIncomplete("Unknown sender")))
                }
            } catch {
                completion(.failure(.accountError))
            }
        }
    }

    func didFinish(_ what: PushMessage? = nil, with error: PushMessageError? = nil) {
        defer {
            profile?.shutdown()
        }

        profile?.setCommandArrived()

        guard let display = self.display else { return }

        display.messageDelivered = false
        display.displayNotification(what, profile: profile, with: error)
        if !display.messageDelivered {
            display.displayUnknownMessageNotification(debugInfo: "Not delivered")
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified
        // content, otherwise the original push payload will be used.
        didFinish(with: .timeout)
    }
}

class SyncDataDisplay {
    var contentHandler: (UNNotificationContent) -> Void
    var notificationContent: UNMutableNotificationContent
    var messageDelivered = false

    init(content: UNMutableNotificationContent,
         contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.notificationContent = content
    }

    func displayNotification(
        _ message: PushMessage? = nil,
        profile: BrowserProfile?,
        with error: PushMessageError? = nil
    ) {
        guard let message = message, error == nil else {
            return displayUnknownMessageNotification(debugInfo: "Error \(error?.description ?? "")")
        }

        switch message {
        case .commandReceived(let command):
            switch command {
                case .tabReceived(let tab):
                    displayNewSentTabNotification(tab: tab)
                case .tabsClosed(let urls):
                    displayClosedTabNotification(urls: urls)
                }
        case .deviceConnected(let deviceName):
            displayDeviceConnectedNotification(deviceName)
        case .deviceDisconnected:
            displayDeviceDisconnectedNotification()
        case .thisDeviceDisconnected:
            displayThisDeviceDisconnectedNotification()
        default:
            displayUnknownMessageNotification(debugInfo: "Unknown: \(message)")
            break
        }
    }

    func displayDeviceConnectedNotification(_ deviceName: String) {
        presentNotification(title: .FxAPush_DeviceConnected_title,
                            body: .FxAPush_DeviceConnected_body,
                            bodyArg: deviceName)
    }

    func displayDeviceDisconnectedNotification() {
        presentNotification(title: .FxAPush_DeviceDisconnected_title,
                            body: .FxAPush_DeviceDisconnected_UnknownDevice_body)
    }

    func displayThisDeviceDisconnectedNotification() {
        presentNotification(title: .FxAPush_DeviceDisconnected_ThisDevice_title,
                            body: .FxAPush_DeviceDisconnected_ThisDevice_body)
    }

    func displayAccountVerifiedNotification() {
        #if MOZ_CHANNEL_beta || DEBUG
            presentNotification(
                title: .SentTab_NoTabArrivingNotification_title,
                body: "DEBUG: Account Verified"
            )
            return
        #else
            presentNotification(
                title: .SentTab_NoTabArrivingNotification_title,
                body: .SentTab_NoTabArrivingNotification_body
            )
        #endif
    }

    func displayUnknownMessageNotification(debugInfo: String) {
        #if MOZ_CHANNEL_beta || DEBUG
            presentNotification(
                title: .SentTab_NoTabArrivingNotification_title,
                body: "DEBUG: " + debugInfo
            )
            return
        #else
            presentNotification(
                title: .SentTab_NoTabArrivingNotification_title,
                body: .SentTab_NoTabArrivingNotification_body
            )
        #endif
    }

    func displayNewSentTabNotification(tab: [String: String]) {
        if let urlString = tab[NotificationSentTabs.Payload.urlKey],
            let url = URL(string: urlString, invalidCharacters: false),
            url.isWebPage(),
            let title = tab[NotificationSentTabs.Payload.titleKey] {
            let tab = [
                NotificationSentTabs.Payload.titleKey: title,
                NotificationSentTabs.Payload.urlKey: url.absoluteString,
                NotificationSentTabs.Payload.displayURLKey: url.absoluteDisplayExternalString,
                NotificationSentTabs.Payload.deviceNameKey: nil
            ] as NSDictionary

            notificationContent.userInfo[NotificationSentTabs.sentTabsKey] = [tab] as NSArray

            presentNotification(
                title: .SentTab_TabArrivingNotification_NoDevice_title,
                body: url.absoluteDisplayExternalString
            )
        }
    }

    func displayClosedTabNotification(urls: [String]) {
        notificationContent.userInfo[NotificationCloseTabs.closeTabsKey]
        = [NotificationCloseTabs.messageIdKey: "closeRemoteTab"]

        notificationContent.categoryIdentifier = NotificationCloseTabs.notificationCategoryId

        presentNotification(
            title: String(format: .CloseTab_ArrivingNotification_title, AppInfo.displayName, "\(urls.count)"),
            body: .CloseTabViewActionTitle
        )
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

struct SentTab {
    let url: URL
    let title: String
    let deviceName: String?
}
