// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage

final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func call(action: @escaping () -> Void) {
        workItem?.cancel()  // Cancel any previously scheduled work
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay, execute: workItem!)
    }
}

/// `AccountSyncHandler` exists to observe certain `TabEventLabel` notifications,
/// and react accordingly.
class AccountSyncHandler: TabEventHandler {
    private let debouncer: Debouncer
    private let profile: Profile
    private let logger: Logger
    private let queueDelay: Double
    private var windowManager: WindowManager {
        return AppContainer.shared.resolve()
    }
    let tabEventWindowResponseType: TabEventHandlerWindowResponseType =
        .allWindows

    // For testing purposes only:
    private var onSyncCompleted: (() -> Void)?

    init(
        with profile: Profile,
        debounceTime: Double = 5.0,
        queue: DispatchQueueInterface = DispatchQueue.global(),
        queueDelay: Double = 0.5,
        logger: Logger = DefaultLogger.shared,
        onSyncCompleted: (() -> Void)? = nil
    ) {
        self.profile = profile
        self.debouncer = Debouncer(delay: debounceTime)
        self.logger = logger
        self.queueDelay = queueDelay
        self.onSyncCompleted = onSyncCompleted

        // Other clients only show urls and ordering of tabs, we can ignore everything
        // else that doesn't modify those attributes
        register(self, forTabEvents: .didGainFocus, .didClose, .didChangeURL)
    }

    // MARK: - Account Server Sync

    func tab(_ tab: Tab, didChangeURL url: URL) {
        performClientsAndTabsSync()
    }

    func tabDidGainFocus(_ tab: Tab) {
        performClientsAndTabsSync()
    }

    func tabDidClose(_ tab: Tab) {
        performClientsAndTabsSync()
    }

    /// For Task Continuity, we want any tab list modifications to reflect across Synced devices.
    ///
    /// To that end, whenever a user adds/removes/switches to any tab,
    /// we trigger a "sync" of tabs. We upload records to the Sync Server from local storage and download
    /// any records from the Sync server to local storage.
    ///
    /// Tabs and clients should stay in sync, so we update our local tabs before syncing
    ///
    /// To prevent multiple tab actions to have a separate syncs, we sync after 5s of no tab activity
    private func performClientsAndTabsSync() {
        guard profile.hasSyncableAccount() else { return }
        debouncer.call { [weak self] in self?.storeTabs() }
    }

    private func storeTabs() {
        let tabManagers = windowManager.allWindowTabManagers()
        let windowCount = tabManagers.count

        // We want all normal and inactive tabs, we never sync private tabs
        // Store tabs keyed by tabUUID to easily handle overrides.
        var storedTabsDict = [String: RemoteTab]()
        for manager in tabManagers {
            // Set inactive tabs explicitly as inactive (initial state)
            for tab in manager.inactiveTabs {
                if let remoteTab = Tab.toRemoteTab(tab, inactive: true) {
                    storedTabsDict[tab.tabUUID] = remoteTab
                }
            }

            // Active tabs override inactive ones if there's overlap
            for tab in manager.normalActiveTabs {
                if let remoteTab = Tab.toRemoteTab(tab, inactive: false) {
                    storedTabsDict[tab.tabUUID] = remoteTab
                }
            }
        }

        // Final stored tabs for syncing
        let storedTabs = Array(storedTabsDict.values)

        // It's fine if we wait until more busy work has finished. We tend to contend with more important
        // work like querying for top sites.
        DispatchQueue.main.asyncAfter(deadline: .now() + queueDelay) { [weak self] in
            self?.logger.log(
                "Storing \(storedTabs.count) total tabs for \(windowCount) windows", level: .debug, category: .sync)
            self?.profile.storeAndSyncTabs(storedTabs).upon { result in
                switch result {
                case .success(let tabCount):
                    self?.logger.log(
                        "Successfully stored \(tabCount) tabs", level: .debug, category: .sync)
                case .failure(let error):
                    self?.logger.log(
                        "Failed to store tabs: \(error.localizedDescription)", level: .warning, category: .sync)
                }
                self?.onSyncCompleted?() // callback for tests
            }
        }
    }
}
