/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct MenuToolbarItem {

    private let iconName: String
    private let privateModeIconName: String

    let title: String

    var icon: UIImage? {
        return UIImage(named: iconName)
    }

    var privateModeIcon: UIImage? {
        return UIImage(named: privateModeIconName)
    }

    func iconForMode(isPrivate isPrivate: Bool = false) -> UIImage?  {
        return isPrivate ? privateModeIcon : icon
    }

    init(title: String, icon: String, privateModeIcon: String) {
        self.title = title
        self.iconName = icon
        self.privateModeIconName = privateModeIcon
    }
}
