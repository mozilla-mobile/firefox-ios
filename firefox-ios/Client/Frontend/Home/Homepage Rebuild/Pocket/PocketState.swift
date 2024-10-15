// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

/// State for the pocket section that is used in the homepage
struct PocketState: StateType, Equatable {
    var windowUUID: WindowUUID
    var pocketData: [PocketItem]
    var pocketDiscoverTitle: String

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            pocketData: [],
            pocketDiscoverTitle: ""
        )
    }

    private init(
        windowUUID: WindowUUID,
        pocketData: [PocketItem],
        pocketDiscoverTitle: String
    ) {
        self.windowUUID = windowUUID
        self.pocketData = pocketData
        self.pocketDiscoverTitle = pocketDiscoverTitle
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return PocketState(
                windowUUID: state.windowUUID,
                pocketData: state.pocketData,
                pocketDiscoverTitle: state.pocketDiscoverTitle
            )
        }

        switch action.actionType {
        case PocketMiddlewareActionType.retrievedUpdatedStories:
            guard let pocketAction = action as? PocketAction,
                  let stories = pocketAction.pocketStories
            else {
                return PocketState(
                    windowUUID: state.windowUUID,
                    pocketData: state.pocketData,
                    pocketDiscoverTitle: state.pocketDiscoverTitle
                )
            }

            return PocketState(
                windowUUID: state.windowUUID,
                pocketData: stories,
                pocketDiscoverTitle: .FirefoxHomepage.Pocket.DiscoverMore
            )
        default:
            return PocketState(
                windowUUID: state.windowUUID,
                pocketData: state.pocketData,
                pocketDiscoverTitle: state.pocketDiscoverTitle
            )
        }
    }
}
