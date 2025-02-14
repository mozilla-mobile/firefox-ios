// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

/// Actions that are related to view updates (i.e. orientation change)
class ViewLifecycleAction: Action {
    let viewConfiguration: ViewLifecycleConfiguration?

    init(viewConfiguration: ViewLifecycleConfiguration? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.viewConfiguration = viewConfiguration
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum ViewLifecycleActionType: ActionType {
    case viewWillTransition
    case traitCollectionDidChange
}
