// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import TabDataStore

protocol TabRestorer: AnyObject {
    func restoreTabs(for windowUUID: WindowUUID) async -> TabRestorationResult
}

@MainActor
final class DefaultTabRestorer: TabRestorer {
    private weak var delegate: TabRestorerDelegate?
    private let tabDataStore: TabDataStore
    private let shouldClearPrivateTabs: Bool
    private let logger: Logger

    init(
        delegate: TabRestorerDelegate,
        tabDataStore: TabDataStore,
        shouldClearPrivateTabs: Bool,
        logger: Logger = DefaultLogger.shared
    ) {
        self.delegate = delegate
        self.tabDataStore = tabDataStore
        self.shouldClearPrivateTabs = shouldClearPrivateTabs
        self.logger = logger
    }

    func restoreTabs(for windowUUID: WindowUUID) async -> TabRestorationResult {
        let windowData = await tabDataStore.fetchWindowData(uuid: windowUUID)
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
            delegate?.restoreScreenshot(for: tab)
        }

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
}
