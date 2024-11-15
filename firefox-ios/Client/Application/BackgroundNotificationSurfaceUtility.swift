// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import BackgroundTasks
import Common
import Shared

class BackgroundNotificationSurfaceUtility: BackgroundUtilityProtocol {
    let taskIdentifier = "org.mozilla.ios.surface.notification.refresh"
    var surfaceManager: NotificationSurfaceManager
    var notificationManager: NotificationManagerProtocol
    private var logger: Logger

    init(surfaceManager: NotificationSurfaceManager = NotificationSurfaceManager(),
         notificationManager: NotificationManagerProtocol = NotificationManager(),
         logger: Logger = DefaultLogger.shared) {
        self.surfaceManager = surfaceManager
        self.notificationManager = notificationManager
        self.logger = logger

        setUp()
    }

    func scheduleTaskOnAppBackground() {
        guard !AppConstants.isRunningUITests else {
            Task {
                await triggerSurfaceManager()
            }
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)

        // Fetch no earlier than 4 hours from now.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.log("Could not schedule app refresh: \(error)",
                       level: .debug,
                       category: .lifecycle)
        }
    }

    func triggerSurfaceManager() async {
        let hasPermission = await notificationManager.hasPermission()

        if hasPermission, surfaceManager.shouldShowSurface {
            surfaceManager.showNotificationSurface()
        }
    }

    // MARK: Private
    private func setUp() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let backgroundRefreshTask = task as? BGAppRefreshTask else {
                self.logger.log("Failed to cast task to BGAppRefreshTask",
                                level: .fatal,
                                category: .lifecycle)
                return
            }
            self.handleAppRefresh(task: backgroundRefreshTask)

            // Schedule a new refresh task.
            self.scheduleTaskOnAppBackground()
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        // Create an operation that performs the main part of the background task.
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }
            Task {
                await self.triggerSurfaceManager()
            }
        }

        // Provide the background task with an expiration handler that cancels the operation.
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            operation.cancel()
        }

        // Inform the system that the background task is complete
        // when the operation completes.
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        // Start the operation.
        queue.addOperation(operation)
     }
}
