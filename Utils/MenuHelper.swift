/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class MenuHelper: NSObject {
    public class var defaultHelper: MenuHelper {
        struct Singleton {
            static let instance = MenuHelper()
        }
        return Singleton.instance
    }

    public func setItems() {
        let revealPasswordTitle = NSLocalizedString("Reveal", tableName: "LoginManager", comment: "Reveal password text selection menu item")
        let revealPasswordItem = UIMenuItem(title: revealPasswordTitle, action: "SELrevealDescription")

        let hidePasswordTitle = NSLocalizedString("Hide", tableName: "LoginManager", comment: "Hide password text selection menu item")
        let hidePasswordItem = UIMenuItem(title: hidePasswordTitle, action: "SELsecureDescription")

        let copyTitle = NSLocalizedString("Copy", tableName: "LoginManager", comment: "Copy password text selection menu item")
        let copyItem = UIMenuItem(title: copyTitle, action: "SELcopyDescription")

        let openAndFillTitle = NSLocalizedString("Open & Fill", tableName: "LoginManager", comment: "Open and Fill website text selection menu item")
        let openAndFillItem = UIMenuItem(title: openAndFillTitle, action: "SELopenAndFillDescription")

        UIMenuController.sharedMenuController().menuItems = [copyItem, revealPasswordItem, hidePasswordItem, openAndFillItem]
    }
}