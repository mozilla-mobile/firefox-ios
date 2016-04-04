/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct NewTabAction: Action {

    func performActionWithAppState(appState: AppState, tabManager: TabManager) {
        if #available(iOS 9, *) {
            tabManager.addTabAndSelect(isPrivate: appState.isPrivate())
        } else {
            tabManager.addTabAndSelect()
        }
    }
}