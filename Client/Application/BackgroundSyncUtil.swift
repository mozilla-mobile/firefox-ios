// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import BackgroundTasks

class BackgroundSyncUtil: Notifiable {

    let profile: Profile
    let application: UIApplication
    var notificationCenter: NotificationCenter

    init(profile: Profile,
         application: UIApplication,
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.profile = profile
        self.application = application
        self.notificationCenter = notificationCenter

        setupNotifications(forObserver: self,
                           observing: [UIApplication.willResignActiveNotification])

        setUpBackgroundSync()
    }

    func setUpBackgroundSync() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.mozilla.ios.sync.part1", using: DispatchQueue.global()) { task in
            guard self.profile.hasSyncableAccount() else {
                self.shutdownProfileWhenNotActive(self.application)
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
                self.shutdownProfileWhenNotActive(self.application)
                task.setTaskCompleted(success: true)
            }
        }
    }

    @objc private func scheduleSyncOnAppBackground() {
        if profile.syncManager.isSyncing {
            // If syncing, create a bg task because _shutdown() is blocking and might take a few seconds to complete
            var taskId = UIBackgroundTaskIdentifier(rawValue: 0)
            taskId = application.beginBackgroundTask(expirationHandler: {
                self.shutdownProfileWhenNotActive(self.application)
                self.application.endBackgroundTask(taskId)
            })

            DispatchQueue.main.async {
                self.shutdownProfileWhenNotActive(self.application)
                self.application.endBackgroundTask(taskId)
            }
        } else {
            // Blocking call, however without sync running it should be instantaneous
            profile._shutdown()

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

    private func shutdownProfileWhenNotActive(_ application: UIApplication) {
        // Only shutdown the profile if we are not in the foreground
        guard application.applicationState != .active else { return }

        profile._shutdown()
    }

    // MARK: Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willResignActiveNotification:
            scheduleSyncOnAppBackground()
        default: break
        }
    }

}
