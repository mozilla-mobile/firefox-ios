// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Storage

final class ContextMenuAction: Action {
    var site: Site?

    init(
        site: Site? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.site = site
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ContextMenuActionType: ActionType {
    case tappedOnRemoveTopSite
    case tappedOnPinTopSite
    case tappedOnUnpinTopSite
}
