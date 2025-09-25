// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol NotificationSurfaceDelegate: AnyObject {
    func didDisplayMessage(_ message: GleanPlumbMessage)
    @MainActor
    func didTapNotification(_ messageId: String)
    func didDismissNotification(_ messageId: String)
}

// TODO: FXIOS-FXIOS-13583 - NotificationSurfaceManager should be concurrency safe
class NotificationSurfaceManager: NotificationSurfaceDelegate, @unchecked Sendable {
    struct Constant {
        static let notificationBaseId = "org.mozilla.ios.notification"
        static let notificationCategoryId = "org.mozilla.ios.notification.category"
        static let messageDelay: CGFloat = 3 // seconds
        static let messageIdKey = "messageId"
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
    func showNotificationSurface() async {
        guard let message = message, !message.isExpired else { return }

        let notificationId = Constant.notificationBaseId + ".\(message.id)"

        // Check if message is already getting displayed
        let notification = await notificationManager.findDeliveredNotificationForId(id: notificationId)
        // Don't schedule the notification again if it was already delivered
        guard notification == nil else { return }

        scheduleNotification(message: message, notificationId: notificationId)
    }

    // MARK: NotificationSurfaceDelegate
    func didDisplayMessage(_ message: GleanPlumbMessage) {
        messagingManager.onMessageDisplayed(message)
    }

    func didTapNotification(_ messageId: String) {
        guard let message = messagingManager.messageForId(messageId)
        else { return }

        messagingManager.onMessagePressed(message, window: nil, shouldExpire: true)
    }

    func didDismissNotification(_ messageId: String) {
        guard let message = messagingManager.messageForId(messageId)
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

        // TODO: FXIOS-13583 - Capture of 'message' with non-Sendable type 'GleanPlumbMessage' in a '@Sendable' closure
        nonisolated(unsafe) let message = message
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
