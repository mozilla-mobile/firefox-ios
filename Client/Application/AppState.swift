/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

protocol AppStateDelegate: class {
    func appDidUpdateState(_ appState: AppState)
}

struct AppState {
    let ui: UIState
    let prefs: Prefs
}

enum UIState {
    case tab(tabState: TabState)
    case homePanels(homePanelState: HomePanelState)
    case tabTray(tabTrayState: TabTrayState)
    case loading
    case emptyTab

    func isPrivate() -> Bool {
        switch self {
        case .tab(let tabState):
            return tabState.isPrivate
        case .homePanels(let homePanelState):
            return homePanelState.isPrivate
        case .tabTray(let tabTrayState):
            return tabTrayState.isPrivate
        default:
            return false
        }
    }
}

class AppStateStore {
    let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }
    func updateState(_ state: UIState) -> AppState {
        return AppState(ui: state, prefs: prefs)
    }
}

// The mainStore should be a singleton.
// It's on the global namespace because it's really just accessing the app delegate, 
// not a shared static instance on the AppStateStore class.  
var mainStore: AppStateStore {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    return appDelegate.appStateStore
}

class Accessors {
    static func isPrivate(_ state: AppState) -> Bool {
        return state.ui.isPrivate()
    }

    static func getPrefs(_ state: AppState) -> Prefs {
        return state.prefs
    }
}
