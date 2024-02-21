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

class MessageCardDataAdaptorImplementation: MessageCardDataAdaptor {
    private var message: GleanPlumbMessage?
    private let messagingManager: GleanPlumbMessageManagerProtocol

    weak var delegate: MessageCardDelegate? {
        didSet {
            updateMessage()
        }
    }

    init(messagingManager: GleanPlumbMessageManagerProtocol = Experiments.messaging) {
        self.messagingManager = messagingManager
    }

    func getMessageCardData() -> GleanPlumbMessage? {
        return message
    }

    /// Call messagingManager to retrieve the message for new tab card
    /// An expired message will not trigger a reload of the section
    /// - Parameter surface: Message surface id
    func updateMessage(for surface: MessageSurfaceId = .newTabCard) {
        if let message = messagingManager.getNextMessage(for: surface) {
            self.message = message
            delegate?.didLoadNewData()
        }
    }
}
