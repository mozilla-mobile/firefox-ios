// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol Themeable: Notifiable {
    var themeManager: ThemeManager { get }
    func listenForThemeUpdates()
    func applyTheme()
}

extension Themeable {
    func listenForThemeUpdates() {
        setupNotifications(forObserver: self,
                           observing: [.ThemeDidChange])
    }

    func handleNotifications(_ notification: Notification) {
        if notification.name == .ThemeDidChange {
            applyTheme()
        }
    }
}
