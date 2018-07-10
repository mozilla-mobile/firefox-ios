/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

fileprivate class DarkBrowserColor: BrowserColor {
    override var background: UIColor { return .red }
    override var locationBarBackground: UIColor { return .red }
    override var tint: UIColor { return .yellow }
}

fileprivate class DarkTableViewColor: TableViewColor {
    override var rowBackground: UIColor { return .red }
    override var headerBackground: UIColor { return .brown }
}

class DarkTheme: NormalTheme {
    override var name: String { return BuiltinThemeName.dark.rawValue }
    override var browser: BrowserColor { return DarkBrowserColor() }
    override var tableView: TableViewColor { return DarkTableViewColor() }
}
