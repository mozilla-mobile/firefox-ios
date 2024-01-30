// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum TabTrayAction: Action {
    case tabTrayDidLoad(TabTrayPanelType)
    case changePanel(TabTrayPanelType)

    // Middleware actions
    case didLoadTabTray(TabTrayModel)
    case dismissTabTray
    case firefoxAccountChanged(Bool)

    var windowUUID: UUID? {
        // TODO: [8188] Update to be non-optional and return windowUUID. Forthcoming.
        switch self {
        default: return nil
        }
    }
}
