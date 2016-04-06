/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum Action {
    // Tab Actions
    case OpenNewTab(isPrivate: Bool, tabManager: TabManager, tabTrayController: TabTrayController?, themer: Themeable?)
    case OpenExistingTabOrOpenNew(tabManager: TabManager, tabTrayController: TabTrayController?, themer: Themeable?)
    case OpenNewTabAndFocus(tabManager: TabManager, tabTrayController: TabTrayController?, themer: Themeable?)
}

protocol Actionable {
    func performAction(action: Action)
}
