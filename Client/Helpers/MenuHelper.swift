/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

@objc public protocol MenuHelperInterface {
    optional func menuHelperCopy(sender: NSNotification)
    optional func menuHelperOpenAndFill(sender: NSNotification)
    optional func menuHelperReveal(sender: NSNotification)
    optional func menuHelperSecure(sender: NSNotification)
    optional func menuHelperFindInPage(sender: NSNotification)
}

public class MenuHelper: NSObject {
    public static let SelectorCopy: Selector = #selector(MenuHelperInterface.menuHelperCopy(_:))
    public static let SelectorHide: Selector = #selector(MenuHelperInterface.menuHelperSecure(_:))
    public static let SelectorOpenAndFill: Selector = #selector(MenuHelperInterface.menuHelperOpenAndFill(_:))
    public static let SelectorReveal: Selector = #selector(MenuHelperInterface.menuHelperReveal(_:))
    public static let SelectorFindInPage: Selector = #selector(MenuHelperInterface.menuHelperFindInPage(_:))

    public class var defaultHelper: MenuHelper {
        struct Singleton {
            static let instance = MenuHelper()
        }
        return Singleton.instance
    }

    public func setItems() {
        let revealPasswordTitle = NSLocalizedString("Reveal", tableName: "LoginManager", comment: "Reveal password text selection menu item")
        let revealPasswordItem = UIMenuItem(title: revealPasswordTitle, action: MenuHelper.SelectorReveal)

        let hidePasswordTitle = NSLocalizedString("Hide", tableName: "LoginManager", comment: "Hide password text selection menu item")
        let hidePasswordItem = UIMenuItem(title: hidePasswordTitle, action: MenuHelper.SelectorHide)

        let copyTitle = NSLocalizedString("Copy", tableName: "LoginManager", comment: "Copy password text selection menu item")
        let copyItem = UIMenuItem(title: copyTitle, action: MenuHelper.SelectorCopy)

        let openAndFillTitle = NSLocalizedString("Open & Fill", tableName: "LoginManager", comment: "Open and Fill website text selection menu item")
        let openAndFillItem = UIMenuItem(title: openAndFillTitle, action: MenuHelper.SelectorOpenAndFill)

        let findInPageTitle = NSLocalizedString("Find in Page", tableName: "FindInPage", comment: "Text selection menu item")
        let findInPageItem = UIMenuItem(title: findInPageTitle, action: MenuHelper.SelectorFindInPage)

        UIMenuController.sharedMenuController().menuItems = [copyItem, revealPasswordItem, hidePasswordItem, openAndFillItem, findInPageItem]
    }
}