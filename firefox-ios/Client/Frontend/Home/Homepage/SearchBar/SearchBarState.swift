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

    /// FXIOS-11504 - This is mainly used for telemetry for top sites and merino and presenting CFRs.
    /// At this time, we are keeping `isZeroSearch` the same as legacy. However, we should revisit this value
    /// and confirm what the expectation is, as it seems inconsistent. See more details in ticket.
    ///
    /// FXIOS-6203 - Comment from legacy homepage:
    /// `isZeroSearch` is true when the homepage is created from the tab tray, a long press
    /// on the tab bar to open a new tab or by pressing the home page button on the tab bar.
    /// The zero search page, aka when the home page is shown by clicking the url bar from a loaded web page.
    /// This needs to be set properly for telemetry and the contextual pop overs that appears on homepage
    let isZeroSearch: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            shouldShowSearchBar: false,
            isZeroSearch: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        shouldShowSearchBar: Bool,
        isZeroSearch: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldShowSearchBar = shouldShowSearchBar
        self.isZeroSearch = isZeroSearch
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case HomepageMiddlewareActionType.configuredSearchBar:
            return handleSearchBarInitialization(action: action, state: state)

        case HomepageActionType.embeddedHomepage:
            return handleEmbeddedHomepageAction(action: action, state: state)

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

    private static func handleEmbeddedHomepageAction(action: Action, state: Self) -> SearchBarState {
        guard let isZeroSearch = (action as? HomepageAction)?.isZeroSearch else {
            return defaultState(from: state)
        }

        return state.copy(
            isZeroSearch: isZeroSearch
        )
    }

    static func defaultState(from state: SearchBarState) -> SearchBarState {
        return SearchBarState(
            windowUUID: state.windowUUID,
            shouldShowSearchBar: state.shouldShowSearchBar,
            isZeroSearch: state.isZeroSearch
        )
    }
}
