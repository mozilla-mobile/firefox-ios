/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TabAction: Actionable {
    func performAction(action: Action) {
        switch(action) {
        case .OpenNewTab(let isPrivate, let tabManager, let tabTrayController, let themer):
            if let tabTrayController = tabTrayController where tabTrayController.privateMode != isPrivate {
                switchToPrivacyMode(isPrivate, tabTrayController: tabTrayController, themer: themer)
            }
            openNewTab(isPrivate, tabManager: tabManager)
        default: break
        }
    }

    private func switchToPrivacyMode(isPrivate: Bool, tabTrayController: TabTrayController, themer: Themeable?) {
        if #available(iOS 9, *) {
            if let themer = themer {
                themer.applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)
            }
            tabTrayController.changePrivacyMode(isPrivate)
        }
    }

    private func openNewTab(isPrivate: Bool = false, url: NSURLRequest? = nil, tabManager: TabManager, inBackground: Bool = false) {
        if inBackground {
            tabManager.addTab(url, isPrivate: isPrivate)
        } else {
            tabManager.addTabAndSelect(url, isPrivate: isPrivate)
        }
    }
}
