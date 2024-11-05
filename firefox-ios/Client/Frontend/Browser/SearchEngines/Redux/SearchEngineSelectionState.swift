// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Redux

struct SearchEngineSelectionState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var shouldDismiss: Bool
    // Default search engine should appear in position 0
    var searchEngines: [OpenSearchEngine]

    init(appState: AppState, uuid: WindowUUID) {
        guard let state = store.state.screenState(
            SearchEngineSelectionState.self,
            for: .searchEngineSelection,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: state.windowUUID,
            searchEngines: state.searchEngines,
            shouldDismiss: state.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID, searchEngines: [])
    }

    private init(
        windowUUID: WindowUUID,
        searchEngines: [OpenSearchEngine],
        shouldDismiss: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.searchEngines = searchEngines
        self.shouldDismiss = shouldDismiss
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultActionState(from: state)
        }

        switch action.actionType {
        case SearchEngineSelectionActionType.didLoadSearchEngines:
            guard let action = action as? SearchEngineSelectionAction,
                  let searchEngines = action.searchEngines
            else {
                return defaultActionState(from: state)
            }

            return SearchEngineSelectionState(
                windowUUID: state.windowUUID,
                searchEngines: searchEngines
            )

        default:
            return defaultActionState(from: state)
        }
    }

    static func defaultActionState(from state: SearchEngineSelectionState) -> SearchEngineSelectionState {
        return SearchEngineSelectionState(
            windowUUID: state.windowUUID,
            searchEngines: state.searchEngines
        )
    }
}
