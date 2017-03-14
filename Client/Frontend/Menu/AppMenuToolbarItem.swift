/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct AppMenuToolbarItem: MenuToolbarItem {

    fileprivate let iconName: String

    let title: String
    let accessibilityIdentifier: String
    let action: MenuAction
    let secondaryAction: MenuAction?

    fileprivate var icon: UIImage? {
        return UIImage(named: iconName)
    }

    func iconForState(_ appState: AppState) -> UIImage? {
        return icon
    }

    init(title: String, accessibilityIdentifier: String, action: MenuAction, secondaryAction: MenuAction? = nil, icon: String) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
        self.secondaryAction = secondaryAction
        self.iconName = icon
    }
}
