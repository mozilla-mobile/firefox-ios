// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// General window management class that provides some basic coordination and
/// state management for multiple windows shared across a single running app.
protocol WindowManager {
    var activeWindow: WindowUUID { get }
    func tabManager(for windowUUID: WindowUUID) -> TabManager
    func tabManagerDidConnectToBrowserWindow(_ tabManager: TabManager)
}

/// Captures state and coordinator references specific to one particular app window.
struct AppWindowInfo {
    var tabManager: TabManager?
}

final class WindowManagerImplementation: WindowManager {
    private var windows: [WindowUUID: AppWindowInfo] = [:]
    private(set) var activeWindow: WindowUUID = .defaultSingleWindowUUID /* [WIP] [FXIOS-7349] iPad multi-window. */

    func tabManagerDidConnectToBrowserWindow(_ tabManager: TabManager) {
        let uuid = tabManager.windowUUID
        var windowInfo = windowInfo(for: uuid, createIfNeeded: true)
        windowInfo?.tabManager = tabManager
        windows[uuid] = windowInfo
    }

    func tabManager(for windowUUID: WindowUUID) -> TabManager {
        guard let tabManager = windowInfo(for: windowUUID)?.tabManager else { fatalError("No tab manager for window UUID.") }
        return tabManager
    }

    // MARK: - Internal Utilities

    private func windowInfo(for windowUUID: WindowUUID, createIfNeeded: Bool = false) -> AppWindowInfo? {
        let windowInfo = windows[windowUUID]
        if windowInfo == nil && createIfNeeded {
            return AppWindowInfo(tabManager: nil)
        }
        return windowInfo
    }
}
