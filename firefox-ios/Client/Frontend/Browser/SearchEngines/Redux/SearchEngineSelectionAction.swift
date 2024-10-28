// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MenuKit
import Redux

final class SearchEngineSelectionAction: Action {
    let searchEngines: [OpenSearchEngine]?

    init(windowUUID: WindowUUID, actionType: ActionType, searchEngines: [OpenSearchEngine]? = nil) {
        self.searchEngines = searchEngines
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum SearchEngineSelectionActionType: ActionType {
    case viewDidLoad
    case didLoadSearchEngines
}

enum SearchEngineSelectionMiddlewareActionType: ActionType {}
