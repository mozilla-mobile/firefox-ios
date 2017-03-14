/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol MenuToolbarItemDelegate: class {
    func menuView(_ menuView: MenuView, didSelectItemAtIndex index: Int)

    func menuView(_ menuView: MenuView, didLongPressItemAtIndex index: Int)
}

protocol MenuItemDelegate: class {
    func menuView(_ menuView: MenuView, didSelectItemAtIndexPath indexPath: IndexPath)

    func menuView(_ menuView: MenuView, didLongPressItemAtIndexPath indexPath: IndexPath)

    func menuView(_ menuView: MenuView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool

    func heightForRowsInMenuView(_ menuView: MenuView) -> CGFloat
}
