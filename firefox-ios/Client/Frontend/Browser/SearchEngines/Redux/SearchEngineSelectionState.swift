// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux

@CopyWithUpdates
struct SearchEngineSelectionState: ScreenState {
    var windowUUID: WindowUUID

    // Default search engine should appear in position 0
    var searchEngines: [SearchEngineModel]
    // The currently selected search engine, if different from the default. Nil means the user hasn't changed the default.
    var selectedSearchEngine: SearchEngineModel?

    init(appState: AppState, uuid: WindowUUID) {
        guard let state = appState.screenState(
            SearchEngineSelectionState.self,
            for: .searchEngineSelection,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self = state.copyWithUpdates()
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID, searchEngines: [], selectedSearchEngine: nil)
    }

    private init(
        windowUUID: WindowUUID,
        searchEngines: [SearchEngineModel],
        selectedSearchEngine: SearchEngineModel?,
    ) {
        self.windowUUID = windowUUID
        self.searchEngines = searchEngines
        self.selectedSearchEngine = selectedSearchEngine
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case SearchEngineSelectionActionType.didLoadSearchEngines:
            guard let action = action as? SearchEngineSelectionAction,
                  let searchEngines = action.searchEngines
            else {
                return defaultState(from: state)
            }

            // With the current usage, we don't want to reset the selectedSearchEngine to nil for didLoadSearchEngines
            return state.copyWithUpdates(
                searchEngines: searchEngines
            )

        case SearchEngineSelectionActionType.didTapSearchEngine:
            guard let action = action as? SearchEngineSelectionAction,
                let selectedSearchEngine = action.selectedSearchEngine
            else { return defaultState(from: state) }

            return state.copyWithUpdates(
                selectedSearchEngine: selectedSearchEngine
            )

        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: SearchEngineSelectionState) -> SearchEngineSelectionState {
        return state.copyWithUpdates()
    }
}
