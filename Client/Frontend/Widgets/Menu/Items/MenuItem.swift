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
