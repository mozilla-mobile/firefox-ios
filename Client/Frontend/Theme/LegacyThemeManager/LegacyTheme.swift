// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

protocol PrivateModeUI {
    func applyUIMode(isPrivate: Bool, theme: Theme)
}

extension UIColor {
    static var legacyTheme: LegacyTheme {
        return LegacyThemeManager.instance.current
    }
}

enum BuiltinThemeName: String {
    case normal
    case dark
}

class TableViewColor {
    var rowText: UIColor { return UIColor.Photon.Grey90 } // textPrimary
    var disabledRowText: UIColor { return UIColor.Photon.Grey40 } // textDisabled
}

class BrowserColor {
    var background: UIColor { return UIColor.Photon.Grey10 } // layer1
}

class TabTrayColor {
    var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.extraLight }
}

protocol LegacyTheme {
    var name: String { get }
    var tableView: TableViewColor { get }
    var browser: BrowserColor { get }
    var tabTray: TabTrayColor { get }
}

class LegacyNormalTheme: LegacyTheme {
    var name: String { return BuiltinThemeName.normal.rawValue }
    var tableView: TableViewColor { return TableViewColor() }
    var browser: BrowserColor { return BrowserColor() }
    var tabTray: TabTrayColor { return TabTrayColor() }
}
