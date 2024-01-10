// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

/// Events related to multiple window support on iPad. These events are
/// always associated with one window in particular, but are typically of
/// interest to all open windows. As such, any WindowEvent posted is
/// broadcast to any Coordinators interested in responding, across any/all
/// open windows on iPadOS.
enum WindowEvent {
    /// A window is being closed.
    case windowWillClose

    /// A window opened the library view controller.
    case libraryOpened

    /// A window opened the settings menu.
    case settingsOpened
}

/// Abstract protocol that any Coordinator can conform to in order to respond
/// to key window lifecycle events, such as cleaning up when a window is closed.
protocol WindowEventCoordinator {
    /// Notifies the coordinator that its parent window/scene is being removed.
    func coordinatorHandleWindowEvent(event: WindowEvent, uuid: WindowUUID)
}
