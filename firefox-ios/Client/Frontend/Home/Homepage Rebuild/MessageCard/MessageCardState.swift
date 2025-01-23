// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

/// State for the message cell that is used in the homepage view
struct MessageCardState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var title: String?
    var description: String?
    var buttonLabel: String?

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            title: nil,
            description: nil,
            buttonLabel: nil
        )
    }

    private init(
        windowUUID: WindowUUID,
        title: String?,
        description: String?,
        buttonLabel: String?
    ) {
        self.windowUUID = windowUUID
        self.title = title
        self.description = description
        self.buttonLabel = buttonLabel
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            return handleInitializeAction(for: state, with: action)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleInitializeAction(for state: MessageCardState, with action: Action) -> MessageCardState {
        // TODO: FXIOS-11133 - Pull appropriate data from message card manager
        return MessageCardState(
            windowUUID: state.windowUUID,
            title: String.FirefoxHomepage.HomeTabBanner.EvergreenMessage.HomeTabBannerTitle,
            description: String.FirefoxHomepage.HomeTabBanner.EvergreenMessage.HomeTabBannerDescription,
            buttonLabel: String.FirefoxHomepage.HomeTabBanner.EvergreenMessage.HomeTabBannerButton
        )
    }

    static func defaultState(from state: MessageCardState) -> MessageCardState {
        return MessageCardState(
            windowUUID: state.windowUUID,
            title: state.title,
            description: state.description,
            buttonLabel: state.buttonLabel
        )
    }
}
