/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol MenuToolbarItemDelegate {
    func menuView(menuView: MenuView, didSelectItemAtIndex index: Int)
}

protocol MenuItemDelegate {
    func menuView(menuView: MenuView, didSelectItemAtIndexPath indexPath: NSIndexPath)

    func menuView(menuView: MenuView, didLongPressItemAtIndexPath indexPath: NSIndexPath)

    func heightForRowsInMenuView(menuView: MenuView) -> CGFloat
}
