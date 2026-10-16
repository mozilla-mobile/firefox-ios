// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// TODO: FXIOS-14194 - @preconcurrency on BackgroundTasks
@preconcurrency import BackgroundTasks
import Common
import Foundation
import Storage

/// A background utility that downloads and stores new Firefox Suggest
/// suggestions when the device is online and connected to power.
final class BackgroundFirefoxSuggestIngestUtility: BackgroundUtilityProtocol,
                                                   FeatureFlaggable,
                                                   UserFeaturePreferenceProvider,
                                                   @unchecked Sendable {
    static let taskIdentifier = "org.mozilla.ios.firefox.suggest.ingest"

    let firefoxSuggest: RustFirefoxSuggestProtocol?
    let logger: Logger
    private var didRegisterTaskHandler = false

    init(firefoxSuggest: RustFirefoxSuggestProtocol?, logger: Logger = DefaultLogger.shared) {
        self.firefoxSuggest = firefoxSuggest
        self.logger = logger

        setUp()
    }

    private var isIngestEnabled: Bool {
        firefoxSuggest != nil
            && featureFlagsProvider.isEnabled(.firefoxSuggestFeature)
            && userPreferences.getPreferenceFor(.firefoxSuggestFeature)
    }

    /// Schedules the ingestion task to run when the app is backgrounded, or
    /// cancels any pending request when the feature is disabled.
    func scheduleTaskOnAppBackground() {
        guard isIngestEnabled else {
            cancelPendingTaskRequest()
            return
        }

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
        guard didRegisterTaskHandler else { return }
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = true
        try BGTaskScheduler.shared.submit(request)
    }

    private func cancelPendingTaskRequest() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
    }

    /// Downloads and stores new Firefox Suggest suggestions. Returns `true` on
    /// success or `false` on failure.
    private func ingest(using firefoxSuggest: RustFirefoxSuggestProtocol) async -> Bool {
        logger.log("Ingesting new suggestions",
                   level: .debug,
                   category: .storage)
        do {
            try await firefoxSuggest.ingest(emptyOnly: false)
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
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard self.isIngestEnabled, let firefoxSuggest = self.firefoxSuggest else {
                self.logger.log("Firefox Suggest is disabled, completing background ingestion without work.",
                                level: .debug,
                                category: .storage)
                self.cancelPendingTaskRequest()
                task.setTaskCompleted(success: true)
                return
            }

            task.expirationHandler = {
                // Interrupt all ongoing storage operations if our
                // background time is about to expire.
                firefoxSuggest.interruptEverything()
                task.setTaskCompleted(success: false)
            }
            Task {
                let success = await self.ingest(using: firefoxSuggest)
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
        didRegisterTaskHandler = true
    }
}
