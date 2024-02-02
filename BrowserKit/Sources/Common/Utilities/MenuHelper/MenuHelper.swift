// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Used to add menu controller items in different parts of our applications, mainly on different textfields type
public protocol MenuHelper {
    func setItems(webViewModel: MenuHelperWebViewModel?,
                  loginModel: MenuHelperLoginModel?,
                  urlBarModel: MenuHelperURLBarModel?)
}

public class DefaultMenuHelper: NSObject, MenuHelper {
    public func setItems(webViewModel: MenuHelperWebViewModel?,
                         loginModel: MenuHelperLoginModel?,
                         urlBarModel: MenuHelperURLBarModel?) {
        var menuItems = [UIMenuItem]()

        if let webViewModel {
            let searchItem = UIMenuItem(title: webViewModel.searchTitle,
                                        action: MenuHelperWebViewModel.selectorSearchWith)
            let findInPageItem = UIMenuItem(title: webViewModel.findInPageTitle,
                                            action: MenuHelperWebViewModel.selectorFindInPage)
            menuItems.append(contentsOf: [searchItem, findInPageItem])
        }

        if let loginModel {
            let openAndFillItem = UIMenuItem(title: loginModel.openAndFillTitle,
                                             action: MenuHelperLoginModel.selectorOpenAndFill)
            let revealPasswordItem = UIMenuItem(title: loginModel.revealPasswordTitle,
                                                action: MenuHelperLoginModel.selectorReveal)
            let hidePasswordItem = UIMenuItem(title: loginModel.hidePasswordTitle,
                                              action: MenuHelperLoginModel.selectorHide)
            let copyItem = UIMenuItem(title: loginModel.copyItemTitle,
                                      action: MenuHelperLoginModel.selectorCopy)
            menuItems.append(contentsOf: [openAndFillItem, revealPasswordItem, hidePasswordItem, copyItem])
        }

        if let urlBarModel {
            let pasteAndGoItem = UIMenuItem(title: urlBarModel.pasteAndGoTitle,
                                            action: MenuHelperURLBarModel.selectorPasteAndGo)
            menuItems.append(contentsOf: [pasteAndGoItem])
        }

        UIMenuController.shared.menuItems = menuItems
    }
}
