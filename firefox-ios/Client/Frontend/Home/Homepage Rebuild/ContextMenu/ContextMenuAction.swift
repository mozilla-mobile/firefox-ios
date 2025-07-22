// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Storage

struct ContextMenuAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let section: HomepageSection?
    let site: Site?

    init(
        section: HomepageSection? = nil,
        site: Site? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.section = section
        self.site = site
    }
}

enum ContextMenuActionType: ActionType {
    case tappedOnOpenNewPrivateTab
    case tappedOnRemoveTopSite
    case tappedOnPinTopSite
    case tappedOnUnpinTopSite
    case tappedOnSponsoredAction
    case tappedOnSettingsAction
}
