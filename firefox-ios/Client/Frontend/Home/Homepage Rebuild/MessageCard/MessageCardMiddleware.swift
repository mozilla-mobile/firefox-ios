// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

struct MessageCardConfiguration: Hashable {
    let title: String?
    let description: String?
    let buttonLabel: String?
}

final class MessageCardMiddleware {
    private var message: GleanPlumbMessage?
    private let messagingManager: GleanPlumbMessageManagerProtocol

    init(messagingManager: GleanPlumbMessageManagerProtocol = Experiments.messaging) {
        self.messagingManager = messagingManager
    }

    lazy var messageCardProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID

        switch action.actionType {
        case HomepageActionType.initialize:
            self.handleInitializeMessageCardAction(windowUUID: windowUUID)
        case MessageCardActionType.tappedOnActionButton:
            guard let message = self.message else { return }
            self.messagingManager.onMessagePressed(message, window: windowUUID, shouldExpire: true)
        case MessageCardActionType.tappedOnCloseButton:
            guard let message = self.message else { return }
            self.messagingManager.onMessageDismissed(message)
        default:
           break
        }
    }

    private func handleInitializeMessageCardAction(windowUUID: WindowUUID) {
        if let message = messagingManager.getNextMessage(for: .newTabCard) {
            let config = MessageCardConfiguration(
                title: message.title,
                description: message.text,
                buttonLabel: message.buttonLabel
            )
            dispatchMessageCardAction(windowUUID: windowUUID, config: config)
            messagingManager.onMessageDisplayed(message)
            self.message = message
        } else {
            self.message = nil
            return
        }
    }

    private func dispatchMessageCardAction(windowUUID: WindowUUID, config: MessageCardConfiguration) {
        let newAction = MessageCardAction(
            messageCardConfiguration: config,
            windowUUID: windowUUID,
            actionType: MessageCardMiddlewareActionType.initialize
        )
        store.dispatchLegacy(newAction)
    }
}
