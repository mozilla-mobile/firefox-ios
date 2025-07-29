// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

struct SearchEngineSelectionAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let searchEngines: [SearchEngineModel]?
    let selectedSearchEngine: SearchEngineModel?

    init(
        windowUUID: WindowUUID,
        actionType: ActionType,
        searchEngines: [SearchEngineModel]? = nil,
        selectedSearchEngine: SearchEngineModel? = nil
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.searchEngines = searchEngines
        self.selectedSearchEngine = selectedSearchEngine
    }
}

enum SearchEngineSelectionActionType: ActionType {
    case viewDidLoad
    case didLoadSearchEngines
    case didTapSearchEngine
}

enum SearchEngineSelectionMiddlewareActionType: ActionType {
    case didClearAlternativeSearchEngine
}
