// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// An `activation` occurs when a user taps on the icon, or otherwise goes to the app in some way.
///
/// A launch is when the process needs to start, and a resume is when your app already had a process alive, even if suspended.
enum ActivationState {
    case launch, resume
}

protocol LaunchSessionProviderProtocol {
    var activationState: ActivationState { get set }
    var openedFromExternalSource: Bool { get set }
}

class LaunchSessionProvider: LaunchSessionProviderProtocol {

    init() {
        addObservers()
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default
    var activationState: ActivationState = .launch
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
            activationState = .resume
            openedFromExternalSource = false

        default: break
        }
    }

}
