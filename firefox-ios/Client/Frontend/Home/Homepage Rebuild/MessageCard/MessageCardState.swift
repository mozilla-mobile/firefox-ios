// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

/// State for the message cell that is used in the homepage view
struct MessageCardState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var messageCardConfiguration: MessageCardConfiguration?

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            messageCardConfiguration: nil
        )
    }

    private init(
        windowUUID: WindowUUID,
        messageCardConfiguration: MessageCardConfiguration?
    ) {
        self.windowUUID = windowUUID
        self.messageCardConfiguration = messageCardConfiguration
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case MessageCardMiddlewareActionType.initialize:
            return handleInitializeAction(for: state, with: action)
        case MessageCardActionType.tappedOnActionButton, MessageCardActionType.tappedOnCloseButton:
            return handleTappingAction(for: state, with: action)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleInitializeAction(for state: MessageCardState, with action: Action) -> MessageCardState {
        guard let messageCardAction = action as? MessageCardAction,
              let messageCardConfiguration = messageCardAction.messageCardConfiguration
        else {
            return defaultState(from: state)
        }
        return MessageCardState(
            windowUUID: state.windowUUID,
            messageCardConfiguration: messageCardConfiguration
        )
    }

    /// Tapping an action on the card should dismiss the message card and we do this by setting the configuration to nil
    private static func handleTappingAction(for state: MessageCardState, with action: Action) -> MessageCardState {
        return MessageCardState(
            windowUUID: state.windowUUID,
            messageCardConfiguration: nil
        )
    }

    static func defaultState(from state: MessageCardState) -> MessageCardState {
        return MessageCardState(
            windowUUID: state.windowUUID,
            messageCardConfiguration: state.messageCardConfiguration
        )
    }
}
