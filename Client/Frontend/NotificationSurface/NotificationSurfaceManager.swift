// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol NotificationSurfaceDelegate: AnyObject {
    func didDisplayMessage(_ message: GleanPlumbMessage)
    func didTapNotification(_ userInfo: [AnyHashable: Any])
}

class NotificationSurfaceManager: NotificationSurfaceDelegate {
    struct Constant {
        static let notificationBaseId: String = "org.mozilla.ios.notification"
        static let messageDelay: CGFloat = 3 // seconds
        static let messageIdKey: String = "messageId"
    }

    // MARK: - Properties
    private let notificationSurfaceID: MessageSurfaceId = .notification
    private var message: GleanPlumbMessage?
    private var messagingManager: GleanPlumbMessageManagerProtocol
    private var notificationManager: NotificationManagerProtocol
    private var notificationCenter: NotificationProtocol

    var shouldShowSurface: Bool {
        updateMessage()
        return message != nil
    }

    // MARK: - Initialization
    init(messagingManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared,
         notificationManager: NotificationManagerProtocol = NotificationManager(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.messagingManager = messagingManager
        self.notificationManager = notificationManager
        self.notificationCenter = notificationCenter
    }

    // MARK: - Functionality
    /// Checks whether a message exists, and is not expired, and schedules
    /// a notification to be presented.
    func showNotificationSurface() {
        guard let message = message, !message.isExpired else { return }

        let notificationId = Constant.notificationBaseId + ".\(message.id)"
        let userInfo = [Constant.messageIdKey: message.id]
        notificationManager.schedule(title: message.data.title ?? "",
                                     body: message.data.text,
                                     id: notificationId,
                                     userInfo: userInfo,
                                     interval: TimeInterval(Constant.messageDelay),
                                     repeats: false)

        // Schedule notification telemetry for when notification gets displayed
        DispatchQueue.main.asyncAfter(deadline: .now() + Constant.messageDelay) { [weak self] in
            self?.didDisplayMessage(message)
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

        switch message.action {
        case "OPEN_NEW_TAB":
            let object = OpenTabNotificationObject(type: .openNewTab)
            notificationCenter.post(name: .OpenTabNotification, withObject: object)
            messagingManager.onMessagePressed(message)
        default:
            // do nothing
            return
        }
    }

    // MARK: - Private

    /// Call messagingManager to retrieve the message for notification surface.
    private func updateMessage() {
        // Set the message to nil just to make sure we're not accidentally
        // showing an old message.
        message = nil
        guard let newMessage = messagingManager.getNextMessage(for: notificationSurfaceID) else { return }
        if !newMessage.isExpired { message = newMessage }
    }
}
