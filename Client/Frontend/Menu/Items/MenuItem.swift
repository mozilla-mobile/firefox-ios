/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol MenuItem {
    var title: String { get }
    var action: MenuAction { get }
    var animation: Animatable? { get }
    func iconForState(appState: AppState) -> UIImage?
    func selectedIconForState(appState: AppState) -> UIImage?
}

struct AppMenuItem: MenuItem {
    let title: String
    let action: MenuAction
    let animation: Animatable?
    private let iconName: String
    private let privateModeIconName: String
    private let selectedIconName: String?

    private var icon: UIImage? {
        return UIImage(named: iconName)
    }

    private var privateModeIcon: UIImage? {
        return UIImage(named: privateModeIconName)
    }

    private var selectedIcon: UIImage? {
        guard let selectedIconName = selectedIconName else {
            return nil
        }
        return UIImage(named: selectedIconName)
    }

    func iconForState(appState: AppState) -> UIImage?  {
        return appState.isPrivate() ? privateModeIcon : icon
    }

    func selectedIconForState(appState: AppState) -> UIImage? {
        return selectedIcon
    }

    init(title: String, action: MenuAction, icon: String, privateModeIcon: String, selectedIcon: String? = nil, animation: Animatable? = nil) {
        self.title = title
        self.action = action
        self.iconName = icon
        self.privateModeIconName = privateModeIcon
        self.selectedIconName = selectedIcon
        self.animation = animation
    }
}
