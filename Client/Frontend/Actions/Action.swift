/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum Action {
    // Tab Actions
    case OpenNewTab(isPrivate: Bool, url: NSURL?, tabManager: TabManager, tabTrayController: TabTrayController?, themer: Themeable?)
    case OpenExistingTabOrOpenNew(isPrivate: Bool, url: NSURL, tabManager: TabManager, currentViewController: UIViewController, tabTrayController: TabTrayController?, themer: Themeable?)
    case OpenNewTabAndFocus(isPrivate: Bool, url: NSURL?, tabManager: TabManager, urlBar: URLBarView, currentViewController: UIViewController)
}

protocol Actionable {
    func performAction(action: Action)
}
