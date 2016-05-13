/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol AppStateDelegate: class {
    func appDidUpdateState(appState: AppState)
}

struct AppState {
    let ui: UIState
}

enum UIState {
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

class AppStateStore {
    func updateState(state: UIState) -> AppState {
        return AppState(ui: state)
    }
}

// The mainStore should be a singleton.
// It's on the global namespace because it's really just accessing the app delegate, 
// not a shared static instance on the AppStateStore class.  
var mainStore: AppStateStore {
    guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
        // something bad happened here.
        return AppStateStore()
    }
    return appDelegate.appStateStore
}