// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol LaunchSessionProviderProtocol {
    var openedFromExternalSource: Bool { get set }
}

class LaunchSessionProvider: LaunchSessionProviderProtocol {
    init() {
        addObservers()
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default
    var openedFromExternalSource = false
}

extension LaunchSessionProvider: Notifiable {
    func addObservers() {
        setupNotifications(forObserver: self, observing: [UIApplication.willResignActiveNotification,
                                                          UIScene.willDeactivateNotification])
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willResignActiveNotification,
            UIScene.willDeactivateNotification:
            openedFromExternalSource = false

        default: break
        }
    }
}
