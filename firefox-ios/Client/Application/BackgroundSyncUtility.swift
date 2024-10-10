// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import BackgroundTasks
import Common

class BackgroundSyncUtility: BackgroundUtilityProtocol {
    let profile: Profile
    let application: UIApplication
    let logger: Logger
    private var taskId = UIBackgroundTaskIdentifier(rawValue: 0)

    init(profile: Profile,
         application: UIApplication,
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.application = application
        self.logger = logger

        setUpBackgroundSync()
    }

    func scheduleTaskOnAppBackground() {
        if profile.syncManager.isSyncing {
            // If syncing, create a background task because _shutdown() is blocking and
            // might take a few seconds to complete
            taskId = application.beginBackgroundTask(expirationHandler: {
                self.shutdownProfileWhenNotActive()
                self.application.endBackgroundTask(self.taskId)
            })

            DispatchQueue.main.async {
                self.shutdownProfileWhenNotActive()
                self.application.endBackgroundTask(self.taskId)
            }
        } else {
            // Blocking call, however without sync running it should be instantaneous
            profile.shutdown()

            let request = BGProcessingTaskRequest(identifier: "org.mozilla.ios.sync.part1")
            request.earliestBeginDate = Date(timeIntervalSinceNow: 1)
            request.requiresNetworkConnectivity = true
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                logger.log("failed to shut down profile \(error.localizedDescription)",
                           level: .warning,
                           category: .sync)
            }
        }
    }

    // MARK: Private
    private func setUpBackgroundSync() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.mozilla.ios.sync.part1",
                                        using: DispatchQueue.global()) { task in
            guard self.profile.hasSyncableAccount() else {
                self.shutdownProfileWhenNotActive()
                return
            }
            let collection = ["bookmarks", "history"]
            self.profile.syncManager.syncNamedCollections(why: .backgrounded, names: collection).uponQueue(.main) { _ in
                task.setTaskCompleted(success: true)
                let request = BGProcessingTaskRequest(identifier: "org.mozilla.ios.sync.part2")
                request.earliestBeginDate = Date(timeIntervalSinceNow: 1)
                request.requiresNetworkConnectivity = true
                do {
                    try BGTaskScheduler.shared.submit(request)
                } catch {
                    self.logger.log("failed to sync named collections \(error.localizedDescription)",
                                    level: .warning,
                                    category: .sync)
                }
            }
        }

        // Split up the sync tasks so each can get maximal time for a bg task.
        // This task runs after the bookmarks+history sync.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.mozilla.ios.sync.part2",
                                        using: DispatchQueue.global()) { task in
            let collection = ["tabs", "logins", "clients"]
            self.profile.syncManager.syncNamedCollections(why: .backgrounded, names: collection).uponQueue(.main) { _ in
                self.shutdownProfileWhenNotActive()
                task.setTaskCompleted(success: true)
            }
        }
    }

    private func shutdownProfileWhenNotActive() {
        ensureMainThread {
            // Only shutdown the profile if we are not in the foreground
            guard self.application.applicationState != .active else { return }
            self.profile.shutdown()
        }
    }
}
