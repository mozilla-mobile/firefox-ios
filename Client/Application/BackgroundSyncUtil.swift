// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import BackgroundTasks

class BackgroundSyncUtil {
    let profile: Profile
    let application: UIApplication

    init(profile: Profile,
         application: UIApplication) {
        self.profile = profile
        self.application = application

        setUpBackgroundSync()
    }

    func setUpBackgroundSync() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.mozilla.ios.sync.part1", using: DispatchQueue.global()) { task in
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
                    NSLog(error.localizedDescription)
                }
            }
        }

        // Split up the sync tasks so each can get maximal time for a bg task.
        // This task runs after the bookmarks+history sync.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.mozilla.ios.sync.part2", using: DispatchQueue.global()) { task in
            let collection = ["tabs", "logins", "clients"]
            self.profile.syncManager.syncNamedCollections(why: .backgrounded, names: collection).uponQueue(.main) { _ in
                self.shutdownProfileWhenNotActive()
                task.setTaskCompleted(success: true)
            }
        }
    }

    func scheduleSyncOnAppBackground() {
        if profile.syncManager.isSyncing {
            // If syncing, create a bg task because _shutdown() is blocking and might take a few seconds to complete
            var taskId = UIBackgroundTaskIdentifier(rawValue: 0)
            taskId = application.beginBackgroundTask(expirationHandler: {
                self.shutdownProfileWhenNotActive()
                self.application.endBackgroundTask(taskId)
            })

            DispatchQueue.main.async {
                self.shutdownProfileWhenNotActive()
                self.application.endBackgroundTask(taskId)
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
                NSLog(error.localizedDescription)
            }
        }
    }

    private func shutdownProfileWhenNotActive() {
        // Only shutdown the profile if we are not in the foreground
        guard application.applicationState != .active else { return }

        profile.shutdown()
    }
}
