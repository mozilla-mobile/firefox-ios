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
    // The currently selected search engine, if different from the default. Nil means the user hasn't changed the default.
    var selectedSearchEngine: OpenSearchEngine?

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
            selectedSearchEngine: state.selectedSearchEngine,
            shouldDismiss: state.shouldDismiss
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID, searchEngines: [], selectedSearchEngine: nil)
    }

    private init(
        windowUUID: WindowUUID,
        searchEngines: [OpenSearchEngine],
        selectedSearchEngine: OpenSearchEngine?,
        shouldDismiss: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.searchEngines = searchEngines
        self.selectedSearchEngine = selectedSearchEngine
        self.shouldDismiss = shouldDismiss
    }

    /// Returns a new `SearchEngineSelectionState` which clears any transient data.
    static func defaultState(fromPreviousState state: SearchEngineSelectionState) -> SearchEngineSelectionState {
        return SearchEngineSelectionState(
            windowUUID: state.windowUUID,
            searchEngines: state.searchEngines,
            selectedSearchEngine: state.selectedSearchEngine
        )
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case SearchEngineSelectionActionType.didLoadSearchEngines:
            guard let action = action as? SearchEngineSelectionAction,
                  let searchEngines = action.searchEngines
            else {
                return defaultState(from: state)
            }

            return SearchEngineSelectionState(
                windowUUID: state.windowUUID,
                searchEngines: searchEngines,
                // With the current usage, we don't want to reset the selectedSearchEngine to nil for didLoadSearchEngines
                selectedSearchEngine: state.selectedSearchEngine
            )

        case SearchEngineSelectionActionType.didTapSearchEngine:
            guard let action = action as? SearchEngineSelectionAction,
                  let selectedSearchEngine = action.selectedSearchEngine
            else { return defaultState(fromPreviousState: state) }

            return SearchEngineSelectionState(
                windowUUID: state.windowUUID,
                searchEngines: state.searchEngines,
                selectedSearchEngine: selectedSearchEngine
            )

        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: SearchEngineSelectionState) -> SearchEngineSelectionState {
        return SearchEngineSelectionState(
            windowUUID: state.windowUUID,
            searchEngines: state.searchEngines
        )
    }
}
