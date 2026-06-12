// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import TabDataStore

/// Owns the full tab restoration lifecycle for a single window.
///
/// `DefaultTabRestorer` fetches persisted window data, filters private tabs, and builds
/// `Tab` objects through `TabRestorerDelegate`, keeping `TabManagerImplementation`
/// agnostic of how tabs are fetched or filtered.
///
/// See ADR 0007 (Deeplink Startup Flow Refactor) for the rationale behind this separation.
@MainActor
protocol TabRestorer: AnyObject {
    /// Fetches persisted tab data for `windowUUID`, builds the corresponding `Tab` objects,
    /// and returns a `TabRestorationResult` ready to be applied by the caller.
    func restoreTabs(for windowUUID: WindowUUID) async -> TabRestorationResult

    /// Loads the screenshot for `tab` on demand. Skips the load if `tab.screenshot` is already set.
    /// `onComplete` fires on the main actor once the in-memory screenshot is settled (loaded, failed,
    /// or skipped). See ADR 0008 for the lazy restoration model that drives this entry point.
    func restoreScreenshot(tab: Tab, onComplete: (() -> Void)?)
}

@MainActor
final class DefaultTabRestorer: TabRestorer {
    private weak var delegate: TabRestorerDelegate?
    private let tabDataStore: TabDataStore
    private let shouldClearPrivateTabs: Bool
    private let logger: Logger
    private let windowIsNew: Bool

    init(
        delegate: TabRestorerDelegate,
        tabDataStore: TabDataStore,
        shouldClearPrivateTabs: Bool,
        windowIsNew: Bool,
        logger: Logger = DefaultLogger.shared
    ) {
        self.delegate = delegate
        self.tabDataStore = tabDataStore
        self.shouldClearPrivateTabs = shouldClearPrivateTabs
        self.logger = logger
        self.windowIsNew = windowIsNew
    }

    func restoreTabs(for windowUUID: WindowUUID) async -> TabRestorationResult {
        // Only attempt a tab data store fetch if we know we should have tabs on disk (ignore new windows)
        let windowData: WindowData? = windowIsNew ? nil : await tabDataStore.fetchWindowData(uuid: windowUUID)
        return buildResult(from: windowData, windowUUID: windowUUID)
    }

    private func buildResult(from windowData: WindowData?, windowUUID: WindowUUID) -> TabRestorationResult {
        let empty = TabRestorationResult(restoredTabs: [], selectedTabUUID: nil, windowUUID: windowUUID)

        guard let windowData else {
            logger.log("Not restoring tabs: no window data", level: .warning, category: .tabs)
            return empty
        }

        let filteredTabData = filterPrivateTabs(from: windowData)

        guard !filteredTabData.isEmpty else {
            logger.log("Not restoring tabs: no tab data after filtering", level: .warning, category: .tabs)
            return empty
        }

        var restoredTabs: [Tab] = []
        var selectedTabUUID: TabUUID?

        for tabData in filteredTabData {
            guard let tab = delegate?.createTab(with: tabData) else { continue }
            restoredTabs.append(tab)
            if windowData.activeTabId == tabData.id {
                selectedTabUUID = tab.tabUUID
            }
        }

        logger.log("There were \(filteredTabData.count) tabs restored",
                   level: .debug,
                   category: .tabs)

        return TabRestorationResult(
            restoredTabs: restoredTabs,
            selectedTabUUID: selectedTabUUID,
            windowUUID: windowUUID
        )
    }

    private func filterPrivateTabs(from windowData: WindowData) -> [TabData] {
        guard shouldClearPrivateTabs else { return windowData.tabData }
        return windowData.tabData.filter { !$0.isPrivate }
    }

    func restoreScreenshot(tab: Tab, onComplete: (() -> Void)?) {
        guard tab.screenshot == nil else {
            onComplete?()
            return
        }
        delegate?.restoreScreenshot(for: tab, onComplete: onComplete)
    }
}
