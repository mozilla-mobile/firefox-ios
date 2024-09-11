// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol NotificationSurfaceDelegate: AnyObject {
    func didDisplayMessage(_ message: GleanPlumbMessage)
    func didTapNotification(_ userInfo: [AnyHashable: Any])
    func didDismissNotification(_ userInfo: [AnyHashable: Any])
}

class NotificationSurfaceManager: NotificationSurfaceDelegate {
    struct Constant {
        static let notificationBaseId: String = "org.mozilla.ios.notification"
        static let notificationCategoryId: String = "org.mozilla.ios.notification.category"
        static let messageDelay: CGFloat = 3 // seconds
        static let messageIdKey: String = "messageId"
    }

    // MARK: - Properties
    private let notificationSurfaceID: MessageSurfaceId = .notification
    private var message: GleanPlumbMessage?
    private var messagingManager: GleanPlumbMessageManagerProtocol
    private var notificationManager: NotificationManagerProtocol

    var shouldShowSurface: Bool {
        updateMessage()
        return message != nil
    }

    static var notificationCategory: UNNotificationCategory {
        return UNNotificationCategory(
            identifier: Constant.notificationCategoryId,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction)
    }

    // MARK: - Initialization
    init(messagingManager: GleanPlumbMessageManagerProtocol = Experiments.messaging,
         notificationManager: NotificationManagerProtocol = NotificationManager()) {
        self.messagingManager = messagingManager
        self.notificationManager = notificationManager
    }

    // MARK: - Functionality
    /// Checks whether a message exists, and is not expired, and schedules
    /// a notification to be presented.
    func showNotificationSurface() {
        guard let message = message, !message.isExpired else { return }

        let notificationId = Constant.notificationBaseId + ".\(message.id)"

        // Check if message is already getting displayed
        notificationManager.findDeliveredNotificationForId(id: notificationId) { [weak self] notification in
            // Don't schedule the notification again if it was already delivered
            guard notification == nil else { return }

            self?.scheduleNotification(message: message, notificationId: notificationId)
        }
    }

    // MARK: NotificationSurfaceDelegate
    func didDisplayMessage(_ message: GleanPlumbMessage) {
        messagingManager.onMessageDisplayed(message)
    }

    func didTapNotification(_ userInfo: [AnyHashable: Any]) {
        guard let messageId = userInfo[Constant.messageIdKey] as? String,
              let message = messagingManager.messageForId(messageId)
        else { return }

        messagingManager.onMessagePressed(message, window: nil, shouldExpire: true)
    }

    func didDismissNotification(_ userInfo: [AnyHashable: Any]) {
        guard let messageId = userInfo[Constant.messageIdKey] as? String,
              let message = messagingManager.messageForId(messageId)
        else { return }

        messagingManager.onMessageDismissed(message)
    }

    // MARK: - Private
    private func scheduleNotification(message: GleanPlumbMessage, notificationId: String) {
        let userInfo = [Constant.messageIdKey: message.id]
        let fallbackTitle = String(format: .Notification.FallbackTitle, AppInfo.displayName)
        let body = String(format: message.text, AppInfo.displayName)
        notificationManager.schedule(title: message.title ?? fallbackTitle,
                                     body: body,
                                     id: notificationId,
                                     userInfo: userInfo,
                                     categoryIdentifier: Constant.notificationCategoryId,
                                     interval: TimeInterval(Constant.messageDelay),
                                     repeats: false)

        // Schedule notification telemetry for when notification gets displayed
        DispatchQueue.global().asyncAfter(deadline: .now() + Constant.messageDelay) { [weak self] in
            self?.didDisplayMessage(message)
        }
    }

    /// Call messagingManager to retrieve the message for notification surface.
    private func updateMessage() {
        message = messagingManager.getNextMessage(for: notificationSurfaceID)
    }
}
