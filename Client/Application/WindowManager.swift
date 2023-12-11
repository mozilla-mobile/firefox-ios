// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// General window management class that provides some basic coordination and
/// state management for multiple windows shared across a single running app.
protocol WindowManager {
    // Managing and checking the active iPad window
    var activeWindow: WindowUUID { get set }
    var windows: [WindowUUID: AppWindowInfo] { get }

    // Managing TabManagers associated with windows
    func tabManager(for windowUUID: WindowUUID) -> TabManager
    func tabManagerDidConnectToBrowserWindow(_ tabManager: TabManager)

    // Closing windows
    func windowDidClose(uuid: WindowUUID)
}

/// Captures state and coordinator references specific to one particular app window.
struct AppWindowInfo {
    var tabManager: TabManager?
}

final class WindowManagerImplementation: WindowManager {
    private(set) var windows: [WindowUUID: AppWindowInfo] = [:]
    var activeWindow: WindowUUID {
        get { return uuidForActiveWindow() }
        set { _activeWindowUUID = newValue }
    }
    private var _activeWindowUUID: WindowUUID?

    func tabManagerDidConnectToBrowserWindow(_ tabManager: TabManager) {
        let uuid = tabManager.windowUUID
        guard var info = window(for: uuid, createIfNeeded: true) else { fatalError() }
        info.tabManager = tabManager
        updateWindow(info, for: uuid)
    }

    func tabManager(for windowUUID: WindowUUID) -> TabManager {
        guard let tabManager = window(for: windowUUID)?.tabManager else { fatalError("No tab manager for window UUID.") }
        return tabManager
    }

    func windowDidClose(uuid: WindowUUID) {
        updateWindow(nil, for: uuid)
    }

    // MARK: - Internal Utilities

    private func updateWindow(_ info: AppWindowInfo?, for uuid: WindowUUID) {
        assert(info != nil || windows.count > 1,
               "Cannot remove the only active window in the app. This is a client error.")

        windows[uuid] = info

        if windows.count == 1 {
            // Convenience. If the client has successfully configured
            // a window and it is the only window in the app, we can
            // automatically set it as the active window.
            activeWindow = uuid
        }
    }

    private func uuidForActiveWindow() -> WindowUUID {
        guard !windows.isEmpty else {
            // No app windows. Unsupported state; can't recover gracefully.
            fatalError()
        }

        guard windows.count > 1 else {
            // For apps with only 1 window we can always safely return it as the active window.
            return windows.keys.first!
        }

        guard let uuid = _activeWindowUUID else {
            assertionFailure("The app has multiple windows but there is no active window UUID. This is a client error.")
            return windows.keys.first!
        }
        return uuid
    }

    private func window(for windowUUID: WindowUUID, createIfNeeded: Bool = false) -> AppWindowInfo? {
        let windowInfo = windows[windowUUID]
        if windowInfo == nil && createIfNeeded {
            return AppWindowInfo(tabManager: nil)
        }
        return windowInfo
    }
}
