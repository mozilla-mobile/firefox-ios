// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common
import Storage

protocol WindowTabsSyncCoordinatorDelegate: AnyObject {
    /// Returns a collection of all tab managers for which tabs
    /// should be collected for syncing with the user's profile.
    func tabManagers() -> [TabManager]
}

final class WindowTabsSyncCoordinator {
    private struct Timing {
        static let throttleDelay = 0.5
        static let dbInsertionDelay = 0.1
    }
    private let throttler = Throttler(seconds: Timing.throttleDelay)
    weak var delegate: WindowTabsSyncCoordinatorDelegate?
    private let profile: Profile
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
    }

    func syncTabsToProfile() {
        throttler.throttle { [weak self] in self?.performSync() }
    }

    // MARK: - Utility

    private func performSync() {
        guard let delegate else { return }
        // This work is performed on the main thread to avoid potential threading issues with the tab collections
        let allTabManagers = delegate.tabManagers()
        let windowCount = allTabManagers.count
        let normalTabs = allTabManagers.flatMap({ $0.normalTabs })
        let inactiveTabs = Set(allTabManagers.flatMap({ $0.inactiveTabs }))

        // It is possible that not all tabs have loaded yet, so we filter out tabs with a nil URL.
        let storedTabs: [RemoteTab] = normalTabs.compactMap { Tab.toRemoteTab($0, inactive: inactiveTabs.contains($0)) }

        // Don't insert into the DB immediately. We tend to contend with more important
        // work like querying for top sites.
        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.dbInsertionDelay) { [weak self] in
            self?.logger.log("Storing \(storedTabs.count) total tabs for \(windowCount) windows", level: .info, category: .sync)
            self?.profile.storeTabs(storedTabs).upon { result in
                switch result {
                case .success(let tabCount):
                    self?.logger.log("Successfully stored \(tabCount) tabs", level: .info, category: .sync)
                case .failure(let error):
                    self?.logger.log("Failed to store tabs: \(error.localizedDescription)", level: .warning, category: .sync)
                }
            }
        }
    }
}
