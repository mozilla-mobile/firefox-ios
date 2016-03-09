/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation


struct MenuItem {
    let name: String
    let title: String
    private let iconName: String
    private let selectedIconName: String

    var icon: UIImage? {
        return UIImage(named: iconName)
    }

    var selectedIcon: UIImage? {
        return UIImage(named: selectedIconName)
    }

    init(name: String, title: String, icon: String, selectedIcon: String) {
        self.name = name
        self.title = title
        self.iconName = icon
        self.selectedIconName = selectedIcon
    }
}
