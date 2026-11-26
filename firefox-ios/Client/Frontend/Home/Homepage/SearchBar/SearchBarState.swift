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
    // FIXME: FXIOS-17392 UI state should be moved to a homepage lens
    let isShowingCenterSearchBar: Bool
    let isHomepageVisible: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            isShowingCenterSearchBar: false,
            isHomepageVisible: false
        )
    }

    init(
        windowUUID: WindowUUID,
        isShowingCenterSearchBar: Bool,
        isHomepageVisible: Bool
    ) {
        self.windowUUID = windowUUID
        self.isShowingCenterSearchBar = isShowingCenterSearchBar
        self.isHomepageVisible = isHomepageVisible
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

        case HomepageActionType.viewWillAppear:
            return state.copy(isHomepageVisible: true)

        case HomepageActionType.viewWillDisappear:
            return state
                .copy(isShowingCenterSearchBar: false)
                .copy(isHomepageVisible: false)

        // Hide homepage search bar when entering zero search state or editing
        case GeneralBrowserActionType.enteredZeroSearchScreen,
            ToolbarActionType.didStartEditingUrl:
            return handleHidingSearchBar(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleSearchBarInitialization(action: Action, state: Self) -> SearchBarState {
        guard let isCenterSearchEnabled = (action as? HomepageAction)?.isCenterSearchEnabled else {
            return defaultState(from: state)
        }

        return state.copy(
            isShowingCenterSearchBar: isCenterSearchEnabled && state.isHomepageVisible
        )
    }

    private static func handleHidingSearchBar(action: Action, state: Self) -> SearchBarState {
        return state.copy(
            isShowingCenterSearchBar: false
        )
    }

    static func defaultState(from state: SearchBarState) -> SearchBarState {
        return SearchBarState(
            windowUUID: state.windowUUID,
            isShowingCenterSearchBar: state.isShowingCenterSearchBar,
            isHomepageVisible: state.isHomepageVisible
        )
    }
}
