// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Storage

final class ContextMenuAction: Action {
    let section: HomepageSection?
    let site: Site?

    init(
        section: HomepageSection? = nil,
        site: Site? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.section = section
        self.site = site
        super.init(windowUUID: windowUUID, actionType: actionType)
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
