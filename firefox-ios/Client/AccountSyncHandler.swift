// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage

@MainActor
final class MainActorDebouncer {
    private let delayInNanoseconds: UInt64
    private var task: Task<Void, Never>?

    init(delay: TimeInterval) {
        self.delayInNanoseconds = delay.nanoseconds
    }

    func call(action: @escaping @MainActor () -> Void) {
        task?.cancel()

        task = Task { [delayInNanoseconds] in
            try? await Task.sleep(nanoseconds: delayInNanoseconds)
            guard !Task.isCancelled else { return }
            action()
        }
    }
}

/// `AccountSyncHandler` exists to observe certain `TabEventLabel` notifications,
/// and react accordingly.
@MainActor
final class AccountSyncHandler: TabEventHandler, Notifiable, Sendable {
    private let notificationCenter: NotificationProtocol = NotificationCenter.default
    private let debouncer: MainActorDebouncer
    private let profile: Profile
    private let logger: Logger
    private var windowManager: WindowManager {
        return AppContainer.shared.resolve()
    }
    let tabEventWindowResponseType: TabEventHandlerWindowResponseType =
        .allWindows

    // For testing purposes only:
    private let onSyncCompleted: (@Sendable () -> Void)?

    init(
        with profile: Profile,
        debounceTime: Double = 5.0,
        logger: Logger = DefaultLogger.shared,
        onSyncCompleted: (@Sendable () -> Void)? = nil
    ) {
        self.profile = profile
        self.debouncer = MainActorDebouncer(delay: debounceTime)
        self.logger = logger
        self.onSyncCompleted = onSyncCompleted

        // Other clients only show urls and ordering of tabs, we can ignore everything
        // else that doesn't modify those attributes
        register(self, forTabEvents: .didGainFocus, .didClose, .didChangeURL)

        // Upload local tabs immediately after login so other clients see them
        // without requiring any tab interaction. syncEverything() fires on login
        // but the Rust TabsStore's local tab list is empty until setLocalTabs()
        // is called...so we do that here as soon as the account is ready.
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [.accountAuthenticated]
        )
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
        debouncer.call { [weak self] in
            self?.storeTabs()
        }
    }

    private func storeTabs() {
        let tabManagers = windowManager.allWindowTabManagers()
        let windowCount = tabManagers.count

        // We want all normal and inactive tabs, we never sync private tabs
        // Store tabs keyed by tabUUID to easily handle overrides.
        var storedTabsDict = [String: RemoteTab]()
        for manager in tabManagers {
            for tab in manager.normalTabs {
                if let remoteTab = RemoteTabCreator.toRemoteTab(from: tab) {
                    storedTabsDict[tab.tabUUID] = remoteTab
                }
            }
        }

        // Final stored tabs for syncing
        let storedTabs = Array(storedTabsDict.values)

        logger.log(
            "Storing \(storedTabs.count) total tabs for \(windowCount) windows", level: .debug, category: .sync
        )

        profile.storeAndSyncTabs(storedTabs).upon { [logger, onSyncCompleted] result in
            switch result {
            case .success(let tabCount):
                logger.log(
                    "Successfully stored \(tabCount) tabs", level: .debug, category: .sync)
            case .failure(let error):
                logger.log(
                    "Failed to store tabs: \(error.localizedDescription)", level: .warning, category: .sync)
            }
            onSyncCompleted?() // callback for tests
        }
    }
}

// MARK: - Notifiable
extension AccountSyncHandler {
    nonisolated func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .accountAuthenticated:
            // Wait until more busy work has finished
            // such as contending with querying for top sites
            Task { @MainActor [weak self] in
                let settleTime: TimeInterval = 0.5
                try? await Task.sleep(nanoseconds: settleTime.nanoseconds)
                self?.storeTabs()
            }
        default:
            break
        }
    }
}

private extension TimeInterval {
    // Convert to nanoseconds for easy use with `Task.sleep` calls pre-iOS 16
    var nanoseconds: UInt64 {
        let nanosecondsPerSecond: Double = 1_000_000_000
        return UInt64(max(0, self) * nanosecondsPerSecond)
    }
}
