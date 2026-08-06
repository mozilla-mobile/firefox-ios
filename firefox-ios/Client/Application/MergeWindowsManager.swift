// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import TabDataStore

/// Merges the tabs from every other open iPad window into a single destination window and closes the
/// emptied windows. Triggered by the "Merge All Windows" home screen Quick Action (issue #25356).
protocol WindowMerging {
    /// Moves every tab from all other open windows into the destination window (preserving each
    /// tab's history), then closes the other windows and removes their persisted window data.
    /// - Parameter targetWindowUUID: the window that survives and receives all of the merged tabs.
    @MainActor
    func mergeAllWindows(into targetWindowUUID: WindowUUID)

    /// Signals that a window has finished closing, which is when a window emptied by a merge has
    /// its persisted data removed. `requestSceneSessionDestruction` reports only failures, so a
    /// disconnecting scene is the only confirmation available that a window actually went away;
    /// a window that never closes therefore keeps its data.
    /// - Parameter uuid: the UUID of the window that closed.
    @MainActor
    func windowDidClose(uuid: WindowUUID)
}

final class MergeWindowsManager: WindowMerging {
    private let windowManager: WindowManager
    private let tabDataStore: TabDataStore
    private let sceneDestroyer: SceneDestroying
    private let logger: Logger
    @MainActor private var windowUUIDsAwaitingClose: Set<WindowUUID> = []

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         tabDataStore: TabDataStore = DefaultTabDataStore(),
         sceneDestroyer: SceneDestroying = DefaultSceneDestroyer(),
         logger: Logger = DefaultLogger.shared) {
        self.windowManager = windowManager
        self.tabDataStore = tabDataStore
        self.sceneDestroyer = sceneDestroyer
        self.logger = logger
    }

    @MainActor
    func mergeAllWindows(into targetWindowUUID: WindowUUID) {
        guard let targetTabManager = windowManager.tabManager(for: targetWindowUUID) else {
            logger.log("Merge windows aborted: no tab manager for the target window.",
                       level: .warning,
                       category: .window)
            return
        }

        let otherWindowUUIDs = windowManager.allWindowUUIDs(includingReserved: false)
            .filter { $0 != targetWindowUUID }

        guard !otherWindowUUIDs.isEmpty else {
            logger.log("Merge windows requested but no other windows are open.",
                       level: .debug,
                       category: .window)
            return
        }

        var mergedTabData: [TabData] = []
        var sourceWindowUUIDs: [WindowUUID] = []
        for windowUUID in otherWindowUUIDs {
            guard let tabManager = windowManager.tabManager(for: windowUUID) else {
                logger.log("Failed to retrieve tabManager for windowUUID \(windowUUID)",
                           level: .warning,
                           category: .window)
                continue
            }
            mergedTabData.append(contentsOf: tabManager.tabDataForWindowMerge())
            sourceWindowUUIDs.append(windowUUID)
        }

        targetTabManager.addTabs(fromWindowMergeData: mergedTabData)

        // Must happen before the windows close: a closing scene resigns active first, and
        // TabManager persists its tab list on that notification, which would recreate the window
        // data deleted below and duplicate every merged tab the next time a window is opened.
        for windowUUID in sourceWindowUUIDs {
            windowManager.tabManager(for: windowUUID)?.discardTabsMovedToAnotherWindow()
        }

        // The window data is removed in windowDidClose(uuid:) once each scene has actually gone,
        // so a window iOS declines to close keeps both its (now empty) tabs and its stored data.
        windowUUIDsAwaitingClose.formUnion(sourceWindowUUIDs)

        sceneDestroyer.destroyScenes(for: sourceWindowUUIDs) { [weak self, logger] windowUUID, error in
            logger.log("Merge windows could not close window \(windowUUID): \(error)",
                       level: .warning,
                       category: .window)
            self?.windowUUIDsAwaitingClose.remove(windowUUID)
        }

        logger.log("""
                   Merged \(mergedTabData.count) tab(s) from \(sourceWindowUUIDs.count) window(s) \
                   into window \(targetWindowUUID).
                   """,
                   level: .info,
                   category: .window)
    }

    @MainActor
    func windowDidClose(uuid: WindowUUID) {
        guard windowUUIDsAwaitingClose.remove(uuid) != nil else { return }

        Task { [tabDataStore] in
            await tabDataStore.removeWindowData(forUUIDs: [uuid])
        }
    }
}
