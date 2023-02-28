// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ResearchSurfaceManager {
    private var message: GleanPlumbMessage?
    private let messagingManager: GleanPlumbMessageManagerProtocol

    var shouldShowResearchSurface: Bool {
        updateMessage()
        if message != nil { return true }
        return false
    }

//    weak var delegate: MessageCardDelegate? {
//        didSet {
//            updateMessage()
//        }
//    }

    init(messagingManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared) {
        self.messagingManager = messagingManager
    }

//    func getMessageCardData() -> GleanPlumbMessage? {
//        return message
//    }

    /// Call messagingManager to retrieve the message for research surface
    func updateMessage(for surface: MessageSurfaceId = .survey) {
        guard let validMessage = messagingManager.getNextMessage(for: surface) else { return }

        if !validMessage.isExpired {
            message = validMessage
//            delegate?.didLoadNewData()
        }
    }
}
