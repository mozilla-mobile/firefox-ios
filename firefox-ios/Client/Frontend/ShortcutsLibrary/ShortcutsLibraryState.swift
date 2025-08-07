// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct ShortcutsLibraryState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    let topSitesData: [TopSiteConfiguration]

    init(appState: AppState, uuid: WindowUUID) {
        guard let shortcutsLibraryState = store.state.screenState(
            ShortcutsLibraryState.self,
            for: .shortcutsLibrary,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: shortcutsLibraryState.windowUUID,
            topSitesData: shortcutsLibraryState.topSitesData
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            topSitesData: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        topSitesData: [TopSiteConfiguration]
    ) {
        self.windowUUID = windowUUID
        self.topSitesData = topSitesData
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case ShortcutsLibraryMiddlewareActionType.retrievedUpdatedSites:
            return handleRetrievedUpdatedSitesAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleRetrievedUpdatedSitesAction(action: Action, state: Self) -> ShortcutsLibraryState {
        guard let shortcutsLibraryAction = action as? ShortcutsLibraryAction,
              let sites = shortcutsLibraryAction.topSites
        else {
            return defaultState(from: state)
        }

        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            topSitesData: sites
        )
    }

    static func defaultState(from state: ShortcutsLibraryState) -> ShortcutsLibraryState {
        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            topSitesData: state.topSitesData
        )
    }
}
