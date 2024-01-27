// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

private class DarkBrowserColor: BrowserColor {
    override var background: UIColor { return UIColor.Photon.DarkGrey60 }
}


private class DarkTabTrayColor: TabTrayColor {
    override var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.dark }
}

class LegacyDarkTheme: LegacyNormalTheme {
    override var name: String { return BuiltinThemeName.dark.rawValue }
    override var browser: BrowserColor { return DarkBrowserColor() }
    override var tabTray: TabTrayColor { return DarkTabTrayColor() }
}
