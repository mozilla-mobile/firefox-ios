// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Foundation
import Redux
import Shared

/// State for the search bar section that is used in the homepage
@Copyable
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

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case HomepageMiddlewareActionType.configuredSearchBar:
            return handleSearchBarInitialization(action: action, state: state)

        // Hide homepage search bar when entering zero search state or
        // when address toolbar is shown
        case GeneralBrowserActionType.enteredZeroSearchScreen,
            GeneralBrowserActionType.didUnhideToolbar,
            ToolbarActionType.didStartEditingUrl:
            return handleHidingSearchBar(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleSearchBarInitialization(action: Action, state: Self) -> SearchBarState {
        guard let isSearchBarEnabled = (action as? HomepageAction)?.isSearchBarEnabled else {
            return defaultState(from: state)
        }

        return state.copy(
            shouldShowSearchBar: isSearchBarEnabled
        )
    }

    private static func handleHidingSearchBar(action: Action, state: Self) -> SearchBarState {
        return state.copy(
            shouldShowSearchBar: false
        )
    }

    static func defaultState(from state: SearchBarState) -> SearchBarState {
        return SearchBarState(
            windowUUID: state.windowUUID,
            shouldShowSearchBar: state.shouldShowSearchBar
        )
    }
}
