// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
    public static let SelectorCopy: Selector = #selector(MenuHelperInterface.menuHelperCopy)
    public static let SelectorHide: Selector = #selector(MenuHelperInterface.menuHelperSecure)
    public static let SelectorOpenAndFill: Selector = #selector(MenuHelperInterface.menuHelperOpenAndFill)
    public static let SelectorReveal: Selector = #selector(MenuHelperInterface.menuHelperReveal)
    public static let SelectorFindInPage: Selector = #selector(MenuHelperInterface.menuHelperFindInPage)
    public static let SelectorSearchWithFirefox: Selector = #selector(MenuHelperInterface.menuHelperSearchWithFirefox)
    public static let SelectorPasteAndGo: Selector = #selector(MenuHelperInterface.menuHelperPasteAndGo)

    open class var defaultHelper: MenuHelper {
        struct Singleton {
            static let instance = MenuHelper()
        }
        return Singleton.instance
    }

    open func setItems() {
        let pasteAndGoItem = UIMenuItem(title: .MenuHelperPasteAndGo, action: MenuHelper.SelectorPasteAndGo)
        let revealPasswordItem = UIMenuItem(title: .MenuHelperReveal, action: MenuHelper.SelectorReveal)
        let hidePasswordItem = UIMenuItem(title: .MenuHelperHide, action: MenuHelper.SelectorHide)
        let copyItem = UIMenuItem(title: .MenuHelperCopy, action: MenuHelper.SelectorCopy)
        let openAndFillItem = UIMenuItem(title: .MenuHelperOpenAndFill, action: MenuHelper.SelectorOpenAndFill)
        let findInPageItem = UIMenuItem(title: .MenuHelperFindInPage, action: MenuHelper.SelectorFindInPage)
        let searchItem = UIMenuItem(title: .MenuHelperSearchWithFirefox, action: MenuHelper.SelectorSearchWithFirefox)
      
        UIMenuController.shared.menuItems = [pasteAndGoItem, copyItem, revealPasswordItem, hidePasswordItem, openAndFillItem, findInPageItem, searchItem]
    }
}
