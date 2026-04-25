// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux
import Shared

/// State for the bookmark section that is used in the homepage view
@CopyWithUpdates
struct BookmarksSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var bookmarks: [BookmarkConfiguration]
    let shouldShowSection: Bool

    struct Constants {
        static let sectionHeaderConfiguration = SectionHeaderConfiguration(
            title: .BookmarksSectionTitle,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.bookmarks,
            isButtonHidden: false,
            buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.bookmarks,
            buttonTitle: .BookmarksSavedShowAllText
        )
    }

    init(profile: Profile = AppContainer.shared.resolve(), windowUUID: WindowUUID) {
        // TODO: FXIOS-11412 - Move profile dependency
        let userPreferences: UserFeaturePreferring = AppContainer.shared.resolve()
        let shouldShowSection = userPreferences.isHomepageBookmarksSectionEnabled
        self.init(
            windowUUID: windowUUID,
            bookmarks: [],
            shouldShowSection: shouldShowSection
        )
    }

    private init(
        windowUUID: WindowUUID,
        bookmarks: [BookmarkConfiguration],
        shouldShowSection: Bool
    ) {
        self.windowUUID = windowUUID
        self.bookmarks = bookmarks
        self.shouldShowSection = shouldShowSection
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case BookmarksMiddlewareActionType.initialize:
            return handleInitializeAction(for: state, with: action)
        case BookmarksActionType.toggleShowSectionSetting:
            return handleSettingsToggleAction(action, state: state)
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
        return state.copyWithUpdates(
            bookmarks: bookmarks
        )
    }

    private static func handleSettingsToggleAction(_ action: Action, state: BookmarksSectionState) -> BookmarksSectionState {
        guard let bookmarksAction = action as? BookmarksAction,
              let isEnabled = bookmarksAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            shouldShowSection: isEnabled
        )
    }

    static func defaultState(from state: BookmarksSectionState) -> BookmarksSectionState {
        return state.copyWithUpdates()
    }
}
