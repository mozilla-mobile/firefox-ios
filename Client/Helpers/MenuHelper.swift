/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

@objc public protocol MenuHelperInterface {
    @objc optional func menuHelperCopy()
    @objc optional func menuHelperOpenAndFill()
    @objc optional func menuHelperReveal()
    @objc optional func menuHelperSecure()
    @objc optional func menuHelperFindInPage()
    @objc optional func menuHelperSearchWithFirefox()
    @objc optional func menuHelperPasteAndGo()
}

open class MenuHelper: NSObject {
    open static let SelectorCopy: Selector = #selector(MenuHelperInterface.menuHelperCopy)
    open static let SelectorHide: Selector = #selector(MenuHelperInterface.menuHelperSecure)
    open static let SelectorOpenAndFill: Selector = #selector(MenuHelperInterface.menuHelperOpenAndFill)
    open static let SelectorReveal: Selector = #selector(MenuHelperInterface.menuHelperReveal)
    open static let SelectorFindInPage: Selector = #selector(MenuHelperInterface.menuHelperFindInPage)
    open static let SelectorSearchWithFirefox: Selector = #selector(MenuHelperInterface.menuHelperSearchWithFirefox)
    open static let SelectorPasteAndGo: Selector = #selector(MenuHelperInterface.menuHelperPasteAndGo)

    open class var defaultHelper: MenuHelper {
        struct Singleton {
            static let instance = MenuHelper()
        }
        return Singleton.instance
    }

    open func setItems() {
        let pasteAndGoTitle = NSLocalizedString("UIMenuItem.PasteGo", value: "Paste & Go", comment: "The menu item that pastes the current contents of the clipboard into the URL bar and navigates to the page")
        let pasteAndGoItem = UIMenuItem(title: pasteAndGoTitle, action: MenuHelper.SelectorPasteAndGo)

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

        let searchTitle = NSLocalizedString("UIMenuItem.SearchWithFirefox", value: "Search with Firefox", comment: "Search in New Tab Text selection menu item")
        let searchItem = UIMenuItem(title: searchTitle, action: MenuHelper.SelectorSearchWithFirefox)
      
        UIMenuController.shared.menuItems = [pasteAndGoItem, copyItem, revealPasswordItem, hidePasswordItem, openAndFillItem, findInPageItem, searchItem]
    }
}
