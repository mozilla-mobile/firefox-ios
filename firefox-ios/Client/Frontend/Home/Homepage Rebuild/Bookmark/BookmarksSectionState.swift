// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage

/// State for the bookmark section that is used in the homepage view
struct BookmarksSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var bookmarks: [BookmarkState]

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            bookmarks: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        bookmarks: [BookmarkState]
    ) {
        self.windowUUID = windowUUID
        self.bookmarks = bookmarks
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

    private static func handleInitializeAction(
        for state: BookmarksSectionState,
        with action: Action
    ) -> BookmarksSectionState {
        // TODO: FXIOS-11051 Update state from middleware
        return BookmarksSectionState(
            windowUUID: state.windowUUID,
            bookmarks: [
                BookmarkState(
                    site: Site.createBasicSite(
                        url: "www.mozilla.org",
                        title: "Bookmarks Title"
                    )
                )
            ]
        )
    }

    static func defaultState(from state: BookmarksSectionState) -> BookmarksSectionState {
        return BookmarksSectionState(
            windowUUID: state.windowUUID,
            bookmarks: state.bookmarks
        )
    }
}
