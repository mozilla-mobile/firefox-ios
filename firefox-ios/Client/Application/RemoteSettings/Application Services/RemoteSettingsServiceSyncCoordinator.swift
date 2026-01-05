// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import MozillaAppServices
import Shared
import Common

// TODO: FXIOS-14203 RemoteSettingsServiceSyncCoordinator is not sendable
final class RemoteSettingsServiceSyncCoordinator: @unchecked Sendable, Notifiable {
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

        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [
                UIApplication.didBecomeActiveNotification,
                UIApplication.willResignActiveNotification
            ]
        )
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didBecomeActiveNotification:
            didBecomeActive()
        case UIApplication.willResignActiveNotification:
            willResignActive()
        default:
            break
        }
    }

    // This is primarily for internal testing or QA purposes.
    func forceImmediateSync() {
        performSync()
    }

    // MARK: - Private API

    private func willResignActive() {
        syncTimer?.invalidate()
    }

    private func didBecomeActive() {
        // Don't perform sync immediately upon becoming active, give the app
        // some time to allow any other work or threads to take priority
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { _ in
            // Sync needs to be scheduled on a background thread, otherwise it will block ui
            DispatchQueue.global().async { [weak self] in
                self?.syncIfNeeded()
            }
        }
    }

    private func syncIfNeeded() {
        let lastSync = prefs.objectForKey(prefsKey) as Date? ?? .distantPast
        let timeSince = lastSync.timeIntervalSinceNow
        if timeSince <= -maxSyncFrequency {
            // Persist our sync time. Note that this will persist the timestamp
            // even if the sync fails, which means we won't retry for another 24hrs
            updateLastSyncTime()
            performSync()
        }
    }

    private func performSync() {
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

    private func updateLastSyncTime() {
        prefs.setObject(Date(), forKey: prefsKey)
    }
}
