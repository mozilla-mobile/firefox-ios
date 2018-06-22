/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

protocol Themeable {
    func applyTheme(_ theme: Theme)
}

enum Theme: String {
    case Private
    case Normal
}

/////////////////
var currentTheme = Normal()

protocol Theme2 {
    var name: String { get }
    var tableView: TableViewColor { get }
}

struct Normal: Theme2 {
    var name: String { return "Normal" }

    var tableView: TableViewColor {
        return TableViewColor()
    }
}

extension UIColor {
    static var theme: Theme2 {
        return currentTheme
    }
}

