// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

enum TabTrayAction: Action {
    case togglePrivateMode(Bool)
    case openExistingTab
    case addNewTab(Bool) // isPrivate
    case closeTab
    case closeAllTabs
    case closeInactiveTab

    // Private tabs action
    case learnMorePrivateMode
}
