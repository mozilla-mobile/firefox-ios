// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct ShortcutsLibraryState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    let shortcuts: [TopSiteConfiguration]
    let toast: Toast?

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
            shortcuts: shortcutsLibraryState.shortcuts,
            toast: shortcutsLibraryState.toast
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            shortcuts: [],
            toast: nil
        )
    }

    private init(
        windowUUID: WindowUUID,
        shortcuts: [TopSiteConfiguration],
        toast: Toast? = nil,
    ) {
        self.windowUUID = windowUUID
        self.shortcuts = shortcuts
        self.toast = toast
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case TopSitesMiddlewareActionType.retrievedUpdatedSites:
            return handleRetrievedUpdatedSitesAction(action: action, state: state)
        case ShortcutsLibraryMiddlewareActionType.openedNewTab:
            return handleOpenedNewTabAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleRetrievedUpdatedSitesAction(action: Action, state: Self) -> ShortcutsLibraryState {
        guard let topSitesAction = action as? TopSitesAction,
              let sites = topSitesAction.topSites
        else {
            return defaultState(from: state)
        }

        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            shortcuts: sites
        )
    }

    private static func handleOpenedNewTabAction(action: Action, state: Self) -> ShortcutsLibraryState {
        guard let toast = (action as? ShortcutsLibraryAction)?.toast else { return defaultState(from: state) }

        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            shortcuts: state.shortcuts,
            toast: toast
        )
    }

    static func defaultState(from state: ShortcutsLibraryState) -> ShortcutsLibraryState {
        return ShortcutsLibraryState(
            windowUUID: state.windowUUID,
            shortcuts: state.shortcuts,
            toast: state.toast
        )
    }
}
