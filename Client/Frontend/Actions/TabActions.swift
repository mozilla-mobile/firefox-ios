/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private protocol TabAction {
    func openTab(isPrivate: Bool, tabManager: TabManager, tabTrayController: TabTrayController, themer: Themeable)
}

extension TabAction {
    func openTab(isPrivate: Bool, tabManager: TabManager, tabTrayController: TabTrayController, themer: Themeable) {
        if #available(iOS 9, *) {
            if isPrivate != tabTrayController.privateMode {
                themer.applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)
                tabTrayController.changePrivacyMode(isPrivate)

            }
            tabManager.addTabAndSelect(isPrivate: isPrivate)
        } else {
            tabManager.addTabAndSelect()
        }
    }
}

struct SwitchToNewTabAction: TabAction, Action {
    func performActionWithAppState(appState: AppState, tabManager: TabManager, tabTrayController: TabTrayController, themer: Themeable) {
        self.openTab(false, tabManager: tabManager, tabTrayController: tabTrayController, themer: themer)
    }
}

struct SwitchToNewPrivateTabAction: TabAction, Action {

    func performActionWithAppState(appState: AppState, tabManager: TabManager, tabTrayController: TabTrayController, themer: Themeable) {
        self.openTab(true, tabManager: tabManager, tabTrayController: tabTrayController, themer: themer)
    }
}