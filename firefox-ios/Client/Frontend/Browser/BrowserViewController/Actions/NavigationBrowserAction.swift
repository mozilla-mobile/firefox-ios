// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

/// Actions that are related to navigation from the user perspective
class NavigationBrowserAction: Action {
    let url: URL?
    init(url: URL? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.url = url
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum NavigationBrowserActionType: ActionType {
    case tapOnCustomizeHomepage
    case tapOnCell
    case tapOnLink
}
