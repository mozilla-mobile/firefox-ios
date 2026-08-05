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
}

final class MergeWindowsManager: WindowMerging {
    private let windowManager: WindowManager
    private let tabDataStore: TabDataStore
    private let sceneDestroyer: SceneDestroying
    private let logger: Logger

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
            guard let tabManager = windowManager.tabManager(for: windowUUID) else { continue }
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

        sceneDestroyer.destroyScenes(for: sourceWindowUUIDs) { [logger] windowUUID, error in
            logger.log("Merge windows could not close window \(windowUUID): \(error)",
                       level: .warning,
                       category: .window)
        }

        Task { [tabDataStore] in
            await tabDataStore.removeWindowData(forUUIDs: sourceWindowUUIDs)
        }

        logger.log("""
                   Merged \(mergedTabData.count) tab(s) from \(sourceWindowUUIDs.count) window(s) \
                   into window \(targetWindowUUID).
                   """,
                   level: .info,
                   category: .window)
    }
}
