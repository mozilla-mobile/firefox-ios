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
    private let logger: Logger

    init(
        messagingManager: GleanPlumbMessageManagerProtocol = Experiments.messaging,
        logger: Logger = DefaultLogger.shared
    ) {
        self.messagingManager = messagingManager
        self.logger = logger
    }

    // TODO: FXIOS-12831 We need this middleware isolated to the main actor (due to `onMessagePressed` call)
    lazy var messageCardProvider: Middleware<AppState> = { state, action in
        // TODO: FXIOS-12557 We assume that we are isolated to the Main Actor
        // because we dispatch to the main thread in the store. We will want to
        // also isolate that to the @MainActor to remove this.
        guard Thread.isMainThread else {
            self.logger.log(
                "MessageCardMiddleware is not being called from the main thread!",
                level: .fatal,
                category: .tabs
            )
            return
        }

        MainActor.assumeIsolated {
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
