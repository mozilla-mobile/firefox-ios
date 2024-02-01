// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import TabDataStore

/// General window management class that provides some basic coordination and
/// state management for multiple windows shared across a single running app.
protocol WindowManager {
    /// The UUID of the active window (there is always at least 1, except in
    /// the earliest stages of app startup lifecycle)
    var activeWindow: WindowUUID { get set }

    /// A collection of all open windows and their related metadata.
    var windows: [WindowUUID: AppWindowInfo] { get }

    /// Signals the WindowManager that a new browser window has been configured.
    /// - Parameter windowInfo: the information for the window.
    /// - Parameter uuid: the window's unique ID.
    func newBrowserWindowConfigured(_ windowInfo: AppWindowInfo, uuid: WindowUUID)

    /// Convenience. Returns the TabManager for a specific window.
    func tabManager(for windowUUID: WindowUUID) -> TabManager

    /// Convenience. Returns all TabManagers for all open windows.
    func allWindowTabManagers() -> [TabManager]

    /// Signals the WindowManager that a window was closed.
    /// - Parameter uuid: the ID of the window.
    func windowWillClose(uuid: WindowUUID)

    /// Supplies the UUID for the next window the iOS app should open. This
    /// corresponds with the window tab data saved to disk, or, if no data is
    /// available it provides a new UUID for the window. The resulting UUID
    /// is then "reserved" in order to ensure that during app launch if multiple
    /// windows are being restored concurrently, we never supply the same UUID
    /// to more than one window.
    /// - Returns: a UUID for the next window to be opened.
    func reserveNextAvailableWindowUUID() -> WindowUUID

    /// Signals the WindowManager that a window event has occurred. Window events
    /// are communicated to any interested Coordinators for _all_ windows, but
    /// any one event is always associated with one window in specific. 
    /// - Parameter event: the event that occurred and any associated metadata.
    /// - Parameter windowUUID: the UUID of the window triggering the event.
    func postWindowEvent(event: WindowEvent, windowUUID: WindowUUID)
}

/// Captures state and coordinator references specific to one particular app window.
struct AppWindowInfo {
    weak var tabManager: TabManager?
    weak var sceneCoordinator: SceneCoordinator?
}

final class WindowManagerImplementation: WindowManager {
    private(set) var windows: [WindowUUID: AppWindowInfo] = [:]
    private var reservedUUIDs: [WindowUUID] = []
    var activeWindow: WindowUUID {
        get { return uuidForActiveWindow() }
        set { _activeWindowUUID = newValue }
    }
    private let logger: Logger
    private let tabDataStore: TabDataStore
    private var _activeWindowUUID: WindowUUID?
    private let defaultUITestingUUID = WindowUUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!

    // MARK: - Initializer

    init(logger: Logger = DefaultLogger.shared,
         tabDataStore: TabDataStore = AppContainer.shared.resolve()) {
        self.logger = logger
        self.tabDataStore = tabDataStore
    }

    // MARK: - Public API

    func newBrowserWindowConfigured(_ windowInfo: AppWindowInfo, uuid: WindowUUID) {
        updateWindow(windowInfo, for: uuid)
        if let reservedUUIDIdx = reservedUUIDs.firstIndex(where: { $0 == uuid }) {
            reservedUUIDs.remove(at: reservedUUIDIdx)
        }
    }

    func tabManager(for windowUUID: WindowUUID) -> TabManager {
        guard let tabManager = window(for: windowUUID)?.tabManager else {
            assertionFailure("Tab Manager unavailable for requested UUID: \(windowUUID). This is a client error.")
            logger.log("No tab manager for window UUID.", level: .fatal, category: .window)
            return window(for: activeWindow)?.tabManager ?? windows.first!.value.tabManager!
        }

        return tabManager
    }

    func allWindowTabManagers() -> [TabManager] {
        return windows.compactMap { uuid, window in window.tabManager }
    }

    func windowWillClose(uuid: WindowUUID) {
        postWindowEvent(event: .windowWillClose, windowUUID: uuid)
        updateWindow(nil, for: uuid)
    }

    func reserveNextAvailableWindowUUID() -> WindowUUID {
        // Continue to provide the expected hardcoded UUID for UI tests.
        guard !AppConstants.isRunningUITests else { return defaultUITestingUUID }

        // • If no saved windows (tab data), we generate a new UUID.
        // • If user has saved windows (tab data), we return the first available UUID
        //   not already associated with an open window.
        // • If multiple window UUIDs are available, we currently return the first one
        //   after sorting based on the uuid value.
        //   TODO: [FXIOS-7929] This ^ is temporary, part of ongoing multi-window work, eventually
        //   we'll be updating this (to use `isPrimary` on WindowData etc). Forthcoming.
        let openWindowUUIDs = windows.keys
        let uuids = tabDataStore.fetchWindowDataUUIDs().filter {
            !openWindowUUIDs.contains($0) && !reservedUUIDs.contains($0)
        }
        let sortedUUIDs = uuids.sorted(by: { return $0.uuidString > $1.uuidString })
        let resultUUID = sortedUUIDs.first ?? WindowUUID()
        reservedUUIDs.append(resultUUID)
        return resultUUID
    }

    func postWindowEvent(event: WindowEvent, windowUUID: WindowUUID) {
        windows.forEach { uuid, windowInfo in
            // Notify any interested Coordinators, in each window, of the
            // event. Any Coordinator can receive these by conforming to the
            // WindowEventCoordinator protocol.
            windowInfo.sceneCoordinator?.recurseChildCoordinators {
                guard let coordinator = $0 as? WindowEventCoordinator else { return }
                coordinator.coordinatorHandleWindowEvent(event: event, uuid: windowUUID)
            }
        }
    }

    // MARK: - Internal Utilities

    private func updateWindow(_ info: AppWindowInfo?, for uuid: WindowUUID) {
        windows[uuid] = info
        didUpdateWindow(uuid)
    }

    /// Called internally when a window is updated (or removed).
    /// - Parameter uuid: the UUID of the window that changed.
    private func didUpdateWindow(_ uuid: WindowUUID) {
        // Convenience. If the client has successfully configured
        // a window and it is the only window in the app, we can
        // be sure we automatically set it as the active window.
        if windows.count == 1 {
            activeWindow = windows.keys.first!
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
            let message = "App has multiple windows but no active window UUID. This is a client error."
            logger.log(message, level: .fatal, category: .window)
            assertionFailure(message)
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
