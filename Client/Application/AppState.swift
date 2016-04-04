/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum AppState {
    case Tab(tabState: TabState)
    case HomePanels(homePanelState: HomePanelState)
    case TabTray(tabTrayState: TabTrayState)
    case Loading

    func isPrivate() -> Bool {
        switch self {
        case .Tab(let tabState):
            return tabState.isPrivate
        case .HomePanels(let homePanelState):
            return homePanelState.isPrivate
        case .TabTray(let tabTrayState):
            return tabTrayState.isPrivate
        default:
            return false
        }
    }
}