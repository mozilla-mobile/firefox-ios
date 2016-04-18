/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol State {
}

protocol MenuConfiguration {

    func menuForState(state: State) -> MenuConfiguration

    var menuItems: [MenuItem] { get }
    var menuToolbarItems: [MenuToolbarItem]? { get }
    var numberOfItemsInRow: Int { get }

    init(state: State)
    func toolbarColor() -> UIColor
    func toolbarTintColor() -> UIColor
    func menuBackgroundColor() -> UIColor
    func menuTintColor() -> UIColor
    func menuFont() -> UIFont
    func menuIcon() -> UIImage?
    func minMenuRowHeight() -> CGFloat
    func shadowColor() -> UIColor
    func selectedItemTintColor() -> UIColor
}

protocol MenuActionDelegate: class {
    func performMenuAction(action: MenuAction, withState state: State)
}

struct MenuAction {
    let action: String!

    init(action: String) {
        self.action = action
    }
}
