// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import MozillaAppServices
import Shared
import Common

final class RemoteSettingsServiceSyncCoordinator {
    private weak var service: RemoteSettingsService?
    private let prefs: Prefs
    private let prefsKey = PrefsKeys.RemoteSettings.lastRemoteSettingsServiceSyncTimestamp
    private let logger: Logger
    private var syncTimer: Timer?
    private let maxSyncFrequency: Double = 60 * 60 * 24 // 24 hours

    init(service: RemoteSettingsService,
         prefs: Prefs,
         logger: Logger = DefaultLogger.shared) {
        self.service = service
        self.prefs = prefs
        self.logger = logger
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            // Don't perform sync immediately upon becoming active, give the app
            // some time to allow any other work or threads to take priority
            syncTimer?.invalidate()
            syncTimer = Timer.scheduledTimer(
                withTimeInterval: 5.0,
                repeats: false
            ) { [weak self] _ in
                self?.syncIfNeeded()
                self?.syncTimer = nil
            }
        }
    }

    // MARK: - Private API

    private func syncIfNeeded() {
        let lastSync = (prefs.objectForKey(prefsKey) as Any? as? Date) ?? Date.distantPast
        let timeSince = lastSync.timeIntervalSinceNow
        if timeSince <= -maxSyncFrequency {
            guard let service else {
                logger.log(
                    "Remote Settings needs sync but service instance is nil.",
                    level: .warning,
                    category: .remoteSettings
                )
                return
            }
            do {
                let syncResults = try service.sync()
                updateLastSyncTime()
                logger.log(
                    "Remote Settings Service sync'd: \(syncResults)",
                    level: .info,
                    category: .remoteSettings
                )
            } catch {
                logger.log(
                    "Remote Settings sync error: \(error)",
                    level: .warning,
                    category: .remoteSettings
                )
            }
        }
    }

    private func updateLastSyncTime() {
        prefs.setObject(Date(), forKey: prefsKey)
    }
}
