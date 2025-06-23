// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared

/// State for the search bar section that is used in the homepage
struct SearchBarState: StateType, Equatable {
    var windowUUID: WindowUUID
    let shouldShowSearchBar: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            shouldShowSearchBar: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        shouldShowSearchBar: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldShowSearchBar = shouldShowSearchBar
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case NavigationBrowserActionType.tapOnHomepageSearchBar:
            return handleHidingSearchBar(action: action, state: state)
        case ToolbarActionType.cancelEdit:
            return handleShowingSearchBar(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleHidingSearchBar(action: Action, state: Self) -> SearchBarState {
        return SearchBarState(
            windowUUID: state.windowUUID,
            shouldShowSearchBar: false
        )
    }

    private static func handleShowingSearchBar(action: Action, state: Self) -> SearchBarState {
        return SearchBarState(
            windowUUID: state.windowUUID,
            shouldShowSearchBar: true
        )
    }

    static func defaultState(from state: SearchBarState) -> SearchBarState {
        return SearchBarState(
            windowUUID: state.windowUUID,
            shouldShowSearchBar: state.shouldShowSearchBar
        )
    }
}
