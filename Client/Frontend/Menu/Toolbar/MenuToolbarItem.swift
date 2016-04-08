/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol MenuToolbarItem {
    var title: String { get }
    var action: MenuAction { get }
    func iconForState(appState: AppState) -> UIImage?
}

struct AppMenuToolbarItem: MenuToolbarItem {

    private let iconName: String

    let title: String
    let action: MenuAction

    private var icon: UIImage? {
        return UIImage(named: iconName)
    }

    func iconForState(appState: AppState) -> UIImage?  {
        return icon
    }

    init(title: String, action: MenuAction, icon: String) {
        self.title = title
        self.action = action
        self.iconName = icon
    }
}
