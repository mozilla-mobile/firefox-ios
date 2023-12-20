// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import BackgroundTasks
import Common
import Foundation
import Shared
import Storage

/// A background utility that downloads and stores new Firefox Suggest
/// suggestions when the device is online and connected to power.
class BackgroundFirefoxSuggestIngestUtility: BackgroundUtilityProtocol, FeatureFlaggable {
    static let taskIdentifier = "org.mozilla.ios.firefox.suggest.ingest"

    let firefoxSuggest: RustFirefoxSuggest
    let logger: Logger

    init(firefoxSuggest: RustFirefoxSuggest, logger: Logger = DefaultLogger.shared) {
        self.firefoxSuggest = firefoxSuggest
        self.logger = logger

        setUp()
    }

    /// Schedules the ingestion task to run when the app is backgrounded.
    func scheduleTaskOnAppBackground() {
        guard featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser) else { return }
        logger.log("Scheduling background ingestion",
                   level: .debug,
                   category: .storage)
        do {
            try self.submitBackgroundTaskRequest()
        } catch {
            logger.log("Failed to schedule background ingestion: \(error.localizedDescription)",
                       level: .warning,
                       category: .storage)
        }
    }

    /// Submits a request to schedule the background ingestion task.
    private func submitBackgroundTaskRequest() throws {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = true
        try BGTaskScheduler.shared.submit(request)
    }

    /// Downloads and stores new Firefox Suggest suggestions. Returns `true` on
    /// success or `false` on failure.
    private func ingest() async -> Bool {
        logger.log("Ingesting new suggestions",
                   level: .debug,
                   category: .storage)
        do {
            try await firefoxSuggest.ingest()
            logger.log("Successfully ingested new suggestions",
                       level: .debug,
                       category: .storage)
            return true
        } catch {
            logger.log("Failed to ingest new suggestions: \(error.localizedDescription)",
                       level: .warning,
                       category: .storage)
            return false
        }
    }

    /// Registers a launch handler for the background ingestion task.
    private func setUp() {
        guard featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser) else { return }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            Task {
                let success = await self.ingest()
                if !success {
                    // If ingestion failed, schedule a follow-up task to retry.
                    self.logger.log("Scheduling retry ingestion",
                                    level: .debug,
                                    category: .storage)
                    do {
                        try self.submitBackgroundTaskRequest()
                    } catch {
                        self.logger.log("Failed to schedule retry ingestion: \(error.localizedDescription)",
                                        level: .warning,
                                        category: .storage)
                    }
                }
                task.setTaskCompleted(success: success)
            }
        }
    }
}
