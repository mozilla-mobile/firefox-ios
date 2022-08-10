// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol MessageCardDataAdaptor {
    func getMessageCardData() -> GleanPlumbMessage?
}

protocol MessageCardDelegate: AnyObject {
    func didLoadNewData()
}

class MessageCardDataAdaptorImplementation: MessageCardDataAdaptor, GleanPlumbMessageManagable {

    weak var delegate: MessageCardDelegate?
    private var message: GleanPlumbMessage?
    var notificationCenter: NotificationProtocol

    func getMessageCardData() -> GleanPlumbMessage? {
        return message
    }

    init(notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        setupNotifications(forObserver: self, observing: [UIApplication.willEnterForegroundNotification])

        updateMessage()
    }

    /// Call messagingManager to retrieve the message for new tab card
    /// An expired message will not trigger a reload of the section
    /// - Parameter surface: Message surface id
    private func updateMessage(for surface: MessageSurfaceId = .newTabCard) {
        guard let validMessage = messagingManager.getNextMessage(for: .newTabCard) else { return }

        if !validMessage.isExpired {
            message = validMessage
            delegate?.didLoadNewData()
        }
    }
}

extension MessageCardDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
         switch notification.name {
         case UIApplication.willEnterForegroundNotification:
             updateMessage()
         default: break
         }
     }
}
