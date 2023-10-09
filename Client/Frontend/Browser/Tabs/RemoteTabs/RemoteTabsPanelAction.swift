// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

/// Defines actions sent to Redux for Sync tab in tab tray
enum RemoteTabsPanelAction: Action {
    case panelDidAppear
    case refreshCachedTabs
    case refreshTabs
}
