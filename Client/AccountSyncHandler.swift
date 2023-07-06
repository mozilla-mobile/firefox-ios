// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

/// `AccountSyncHandler` exists to observe certain `TabEventLabel` notifications,
/// and react accordingly.
class AccountSyncHandler: TabEventHandler {
    private let throttler: Throttler
    private let profile: Profile

    init(with profile: Profile,
         throttleTime: Double = 5.0,
         queue: DispatchQueueInterface = DispatchQueue.global()) {
        self.profile = profile
        self.throttler = Throttler(seconds: throttleTime,
                                   on: queue)

        register(self, forTabEvents: .didLoadPageMetadata, .didGainFocus)
    }

    // MARK: - Account Server Sync

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        performClientsAndTabsSync()
    }

    func tabDidGainFocus(_ tab: Tab) {
        performClientsAndTabsSync()
    }

    /// For Task Continuity, we want tab loads and tab switches to reflect across Synced devices.
    ///
    /// To that end, whenever a user's tab finishes loading page metadata or switches to focus on a new tab,
    /// we trigger a "sync" of tabs. We upload records to the Sync Server from local storage and download
    /// any records from the Sync server to local storage.
    ///
    /// Tabs and clients should stay in sync, so a call to sync tabs will also sync clients.
    ///
    /// Make sure there's at least a 5 second difference between Syncs.
    private func performClientsAndTabsSync() {
        guard profile.hasSyncableAccount() else { return }

        throttler.throttle { [weak self] in
            _ = self?.profile.syncManager.syncNamedCollections(why: .user, names: ["tabs"])
        }
    }
}
