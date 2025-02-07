// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage

/// State for the bookmark section that is used in the homepage view
struct BookmarksSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var bookmarks: [BookmarkConfiguration]

    let sectionHeaderState = SectionHeaderState(
        title: .BookmarksSectionTitle,
        a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.bookmarks,
        isButtonHidden: false,
        buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.bookmarks,
        buttonTitle: .BookmarksSavedShowAllText
    )

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            bookmarks: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        bookmarks: [BookmarkConfiguration]
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
        case BookmarksMiddlewareActionType.initialize:
            return handleInitializeAction(for: state, with: action)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleInitializeAction(
        for state: BookmarksSectionState,
        with action: Action
    ) -> BookmarksSectionState {
        guard let bookmarksAction = action as? BookmarksAction,
              let bookmarks = bookmarksAction.bookmarks
        else {
            return defaultState(from: state)
        }
        return BookmarksSectionState(
            windowUUID: state.windowUUID,
            bookmarks: bookmarks
        )
    }

    static func defaultState(from state: BookmarksSectionState) -> BookmarksSectionState {
        return BookmarksSectionState(
            windowUUID: state.windowUUID,
            bookmarks: state.bookmarks
        )
    }
}
