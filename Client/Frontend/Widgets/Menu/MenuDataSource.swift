/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit


// toolbar
protocol MenuToolbarDataSource: class {
    // how many items we will be displaying in our toolbar
    func numberOfToolbarItemsInMenuView(menuView: MenuView) -> Int

    // the button that we should display at this point in the toolbar
    func menuView(menuView: MenuView, buttonForItemAtIndex index: Int) -> UIView
}

// menu items
protocol MenuItemDataSource: class {
    // how many pages we should provide in our menu
    func numberOfPagesInMenuView(menuView: MenuView) -> Int

    func numberOfItemsPerRowInMenuView(menuView: MenuView) -> Int

    // for this page, the number of items that we will display
    func menuView(menuView: MenuView, numberOfItemsForPage page: Int) -> Int

    // get the menu cell for this page item
    func menuView(menuView: MenuView, menuItemCellForIndexPath indexPath: NSIndexPath) -> MenuItemCollectionViewCell
}
