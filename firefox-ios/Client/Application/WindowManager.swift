// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import TabDataStore
import WidgetKit

/// Defines various actions in the app which are performed for all open iPad
/// windows. These can be routed through the WindowManager 
enum MultiWindowAction {
    /// Signals that we should store tabs (for all windows) on the default Profile.
    case storeTabs

    /// Signals that we should save Simple Tabs for all windows (used by our widgets).
    case saveSimpleTabs

    /// Closes private tabs across all windows.
    case closeAllPrivateTabs
}

/// General window management class that provides some basic coordination and
/// state management for multiple windows shared across a single running app.
protocol WindowManager {
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

    /// Returns the UUIDs for all open windows, optionally also including windows that
    /// are still in the process of being configured but have not yet completed.
    /// Note: the order of the UUIDs is undefined.
    /// - Parameter includingReserved: whether to include windows that are still launching.
    /// - Returns: a list of UUIDs. Order is undefined.
    func allWindowUUIDs(includingReserved: Bool) -> [WindowUUID]

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
    func reserveNextAvailableWindowUUID(isIpad: Bool) -> ReservedWindowUUID

    /// Signals the WindowManager that a window event has occurred. Window events
    /// are communicated to any interested Coordinators for _all_ windows, but
    /// any one event is always associated with one window in specific. 
    /// - Parameter event: the event that occurred and any associated metadata.
    /// - Parameter windowUUID: the UUID of the window triggering the event.
    func postWindowEvent(event: WindowEvent, windowUUID: WindowUUID)

    /// Performs a MultiWindowAction.
    /// - Parameter action: the action to perform.
    func performMultiWindowAction(_ action: MultiWindowAction)

    /// Returns the current window (if available) which hosts a specific tab.
    /// - Parameter tab: the UUID of the tab.
    /// - Returns: the UUID of the window hosting it (if available and open).
    func window(for tab: TabUUID) -> WindowUUID?
}

/// Captures state and coordinator references specific to one particular app window.
struct AppWindowInfo {
    weak var tabManager: TabManager?
    weak var sceneCoordinator: SceneCoordinator?
}

final class WindowManagerImplementation: WindowManager, WindowTabsSyncCoordinatorDelegate {
    enum WindowPrefKeys {
        static let windowOrdering = "windowOrdering"
    }

    private(set) var windows: [WindowUUID: AppWindowInfo] = [:]

    // A list of UUIDs that have already been reserved for windows which are being actively configured.
    // Because so much of our early launch configuration occurs async, it's possible to request more than
    // one window UUID before previous windows have completed, this tracks reserved UUIDs still in the
    // process of initial configuration.
    private var reservedUUIDs: [WindowUUID] = []

    private let logger: Logger
    private let tabDataStore: TabDataStore
    private let defaults: UserDefaultsInterface
    private let tabSyncCoordinator = WindowTabsSyncCoordinator()
    private let widgetSimpleTabsCoordinator = WindowSimpleTabsCoordinator()

    // Ordered set of UUIDs which determines the order that windows are re-opened on iPad
    // UUIDs at the beginning of the list are prioritized over UUIDs at the end
    private(set) var windowOrderingPriority: [WindowUUID] {
        get {
            let stored = defaults.object(forKey: WindowPrefKeys.windowOrdering)
            guard let prefs: [String] = stored as? [String] else { return [] }
            return prefs.compactMap({ UUID(uuidString: $0) })
        }
        set {
            let mapped: [String] = newValue.compactMap({ $0.uuidString })
            defaults.set(mapped, forKey: WindowPrefKeys.windowOrdering)
        }
    }

    // MARK: - Initializer

    init(logger: Logger = DefaultLogger.shared,
         tabDataStore: TabDataStore? = nil,
         userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.tabDataStore = tabDataStore ?? DefaultTabDataStore(logger: logger, fileManager: DefaultTabFileManager())
        self.logger = logger
        self.defaults = userDefaults
        tabSyncCoordinator.delegate = self
    }

    // MARK: - Public API

    func newBrowserWindowConfigured(_ windowInfo: AppWindowInfo, uuid: WindowUUID) {
        updateWindow(windowInfo, for: uuid)
        clearReservedUUID(uuid)
    }

    func tabManager(for windowUUID: WindowUUID) -> TabManager {
        guard let tabManager = window(for: windowUUID)?.tabManager else {
            assertionFailure("Tab Manager unavailable for requested UUID: \(windowUUID). This is a client error.")
            logger.log("No tab manager for window UUID.", level: .fatal, category: .window)
            return windows.first!.value.tabManager!
        }

        return tabManager
    }

    func allWindowTabManagers() -> [TabManager] {
        return windows.compactMap { uuid, window in window.tabManager }
    }

    func allWindowUUIDs(includingReserved: Bool) -> [WindowUUID] {
        return Array(windows.keys) + (includingReserved ? reservedUUIDs : [])
    }

    func windowWillClose(uuid: WindowUUID) {
        postWindowEvent(event: .windowWillClose, windowUUID: uuid)
        updateWindow(nil, for: uuid)
        // Fix edge case in which a scene's UUID might still be reserved when the scene is disconnected
        clearReservedUUID(uuid)

        // Closed windows are popped off and moved behind any already-open windows in the list
        var prefs = windowOrderingPriority
        prefs.removeAll(where: { $0 == uuid })
        let openWindows = Array(windows.keys)
        let idx = prefs.firstIndex(where: { !openWindows.contains($0) })
        prefs.insert(uuid, at: idx ?? prefs.count)
        windowOrderingPriority = prefs
    }

    func reserveNextAvailableWindowUUID(isIpad: Bool) -> ReservedWindowUUID {
        // Continue to provide the expected hardcoded UUID for UI tests.
        guard !AppConstants.isRunningUITests else {
            return ReservedWindowUUID(uuid: WindowUUID.DefaultUITestingUUID, isNew: false)
        }
        assert(Thread.isMainThread, "Window UUID configuration currently expected on main thread only.")

        // • If no saved windows (tab data), we generate a new UUID.
        // • If user has saved windows (tab data), we return the first available UUID
        //   not already associated with an open window.
        // • If multiple window UUIDs are available, we currently return the first one
        //   after sorting based on the order they were last closed (which we track in
        //   client user defaults).
        // • If for some reason the user defaults are unavailable we sort open the
        //   windows by order of their UUID value.

        // Fetch available window data on disk, and remove any already-opened windows
        // or UUIDs that are already reserved and in the process of opening.
        let openWindowUUIDs = windows.keys
        let onDiskUUIDs = tabDataStore.fetchWindowDataUUIDs()

        let onDiskUUIDLog = onDiskUUIDs.map({ $0.uuidString.prefix(8) }).joined(separator: ", ")
        let reserveLog = reservedUUIDs.map({ $0.uuidString.prefix(8) }).joined(separator: ", ")
        let openLog = openWindowUUIDs.map({ $0.uuidString.prefix(8) }).joined(separator: ", ")
        logger.log("WindowManager: reserve next UUID. Disk: \(onDiskUUIDLog). Reserved: \(reserveLog). Open: \(openLog)",
                   level: .debug,
                   category: .window)

        // On iPhone devices, we expect there only to ever be a single window. If there
        // are >1 windows we've encountered some type of unexpected state.
        let result: ReservedWindowUUID
        if !isIpad {
            // We should always have either a single UUID on disk or no UUIDs because this is a brand new app install
            if onDiskUUIDs.isEmpty {
                result = ReservedWindowUUID(uuid: WindowUUID(), isNew: true)
            } else {
                result = ReservedWindowUUID(uuid: onDiskUUIDs.first!, isNew: false)

                let uuidCount = onDiskUUIDs.count
                if uuidCount > 1 {
                    // This is unexpected. Potentially related to incident in v128 (see: FXIOS-9516).
                    // On iPhone, we should never have more than 1 window tab file. Log an error and
                    // clean up the UUID(s) that we know won't be used. We expect a certain number of
                    // these fatal errors to be logged for users previously impacted by the above, and
                    // then it should fall to zero.
                    logger.log("Detected multiple window tab files on iPhone (UUID count: \(uuidCount))",
                               level: .fatal,
                               category: .window)
                    let uuidsToDelete = Array(onDiskUUIDs.dropFirst())
                    Task { await tabDataStore.removeWindowData(forUUIDs: uuidsToDelete) }
                }
            }
        } else {
            let filteredUUIDs = onDiskUUIDs.filter {
                !openWindowUUIDs.contains($0) && !reservedUUIDs.contains($0)
            }

            result = nextWindowUUIDToOpen(filteredUUIDs)
        }

        logger.log("WindowManager: reserve next UUID result = \(result.uuid.uuidString) Is new?: \(result.isNew)",
                   level: .debug,
                   category: .window)
        let resultUUID = result.uuid
        if result.isNew {
            // Be sure to add any brand-new windows to our ordering preferences
            var prefs = windowOrderingPriority
            prefs.insert(resultUUID, at: 0)
            windowOrderingPriority = prefs
        }

        // Reserve the UUID until the Client finishes the window configuration process
        reservedUUIDs.append(resultUUID)
        return result
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

    func performMultiWindowAction(_ action: MultiWindowAction) {
        switch action {
        case .closeAllPrivateTabs:
            windows.forEach {
                guard let browserCoordinator = $0.value.sceneCoordinator?
                    .childCoordinators.first(where: { $0 is BrowserCoordinator }) as? BrowserCoordinator else { return }
                browserCoordinator.browserViewController.closeAllPrivateTabs()
            }
        case .storeTabs:
            storeTabs()
        case .saveSimpleTabs:
            saveSimpleTabs()
        }
    }

    func window(for tab: TabUUID) -> WindowUUID? {
        return allWindowTabManagers().first(where: { $0.tabs.contains(where: { $0.tabUUID == tab }) })?.windowUUID
    }

    // MARK: - WindowTabSyncCoordinatorDelegate

    private func storeTabs() {
        tabSyncCoordinator.syncTabsToProfile()
    }

    func tabManagers() -> [TabManager] {
        return allWindowTabManagers()
    }

    // MARK: - Internal Utilities

    private func clearReservedUUID(_ uuid: WindowUUID) {
        guard let reservedUUIDIdx = reservedUUIDs.firstIndex(where: { $0 == uuid }) else { return }
        reservedUUIDs.remove(at: reservedUUIDIdx)
    }

    private func saveSimpleTabs() {
        let providers = allWindowTabManagers() as? [WindowSimpleTabsProvider] ?? []
        widgetSimpleTabsCoordinator.saveSimpleTabs(for: providers)
    }

    /// When provided a list of UUIDs of available window data files on disk,
    /// this function determines which of them should be the next to be
    /// opened. This allows multiple windows to be restored in a sensible way.
    /// - Parameter onDiskUUIDs: on-disk UUIDs representing windows that are not
    /// already open or reserved (this is important - these UUIDs should be pre-
    /// filtered).
    /// - Returns: the UUID for the next window that will be opened on iPad.
    private func nextWindowUUIDToOpen(_ onDiskUUIDs: [WindowUUID]) -> ReservedWindowUUID {
        func nextUUIDUsingFallbackSorting() -> ReservedWindowUUID {
            let sortedUUIDs = onDiskUUIDs.sorted(by: { return $0.uuidString > $1.uuidString })
            if let resultUUID = sortedUUIDs.first {
                return ReservedWindowUUID(uuid: resultUUID, isNew: false)
            }
            return ReservedWindowUUID(uuid: WindowUUID(), isNew: true)
        }

        guard !onDiskUUIDs.isEmpty else {
            return ReservedWindowUUID(uuid: WindowUUID(), isNew: true)
        }

        // Get the ordering preference
        let priorityPreference = windowOrderingPriority
        guard !priorityPreference.isEmpty else {
            // Preferences are empty. Could be initial launch after multi-window release
            // or preferences have been cleared. Fallback to default sort.
            return nextUUIDUsingFallbackSorting()
        }

        // Iterate and return the first UUID that is available within our on-disk UUIDs
        // (which excludes windows already open or reserved).
        for uuid in priorityPreference where onDiskUUIDs.contains(uuid) {
            return ReservedWindowUUID(uuid: uuid, isNew: false)
        }

        return nextUUIDUsingFallbackSorting()
    }

    private func updateWindow(_ info: AppWindowInfo?, for uuid: WindowUUID) {
        windows[uuid] = info
    }

    private func window(for windowUUID: WindowUUID, createIfNeeded: Bool = false) -> AppWindowInfo? {
        let windowInfo = windows[windowUUID]
        if windowInfo == nil && createIfNeeded {
            return AppWindowInfo(tabManager: nil)
        }
        return windowInfo
    }
}
