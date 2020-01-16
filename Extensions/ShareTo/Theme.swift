/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIColor {
    static var theme: Theme {
        return ThemeManager.instance.current
    }
}

class ThemeManager {
    static let instance = ThemeManager()
    var current: Theme = NormalTheme()
}

protocol Theme {
    var doneLabelBackgroundColor: UIColor { get }
    var separatorColor: UIColor { get }
    var actionRowTextAndIconColor: UIColor { get }
    var defaultBackground: UIColor { get }
}

class NormalTheme: Theme {
    var defaultBackground = UIColor.white
    var doneLabelBackgroundColor = UIColor.Photon.Blue40
    var separatorColor = UIColor.Photon.Grey30
    var actionRowTextAndIconColor = UIColor.Photon.Grey80
}

class DarkTheme: Theme {
    var defaultBackground = UIColor.Photon.Grey80
    var doneLabelBackgroundColor = UIColor.Photon.Blue40
    var separatorColor = UIColor.Photon.Grey10
    var actionRowTextAndIconColor = UIColor.white
}
