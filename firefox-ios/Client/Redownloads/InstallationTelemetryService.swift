// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Glean
import Shared

/// Tracks the install count and last seen date, along with the original purchase date and app version.
/// Keychain history survives reinstalls
@MainActor
final class InstallationTelemetryService {
    private let history: InstallationHistoryStoring
    private let acquisition: AppAcquisitionProviding
    private let gleanWrapper: GleanWrapper
    private let profilePrefs: Prefs
    private let featureFlagsProvider: FeatureFlagProviding
    private let dateProvider: DateProvider
    private let installationPrefs: Prefs
    private let logger: Logger
    private var isProcessing = false

    init(
        profilePrefs: Prefs,
        installationPrefs: Prefs = NSUserDefaultsPrefs(prefix: "installationTelemetry", userDefaults: .standard),
        history: InstallationHistoryStoring = InstallationHistoryStore(),
        acquisition: AppAcquisitionProviding = StoreKitAppAcquisitionProvider(),
        gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        dateProvider: DateProvider = SystemDateProvider(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.installationPrefs = installationPrefs
        self.history = history
        self.acquisition = acquisition
        self.gleanWrapper = gleanWrapper
        self.profilePrefs = profilePrefs
        self.featureFlagsProvider = featureFlagsProvider
        self.dateProvider = dateProvider
        self.logger = logger
        initializeProcessingState()
    }

    /// Marks existing users as processed so enabling this feature does not count them as new installations.
    private func initializeProcessingState() {
        guard featureFlagsProvider.isEnabled(.checkForReinstalls),
            installationPrefs.boolForKey(PrefsKeys.installationProcessedKey) == nil
        else { return }

        let hasSeenIntro = profilePrefs.intForKey(PrefsKeys.IntroSeen) != nil
        installationPrefs.setBool(hasSeenIntro, forKey: PrefsKeys.installationProcessedKey)
    }

    private var isInstallationProcessed: Bool {
        return installationPrefs.boolForKey(PrefsKeys.installationProcessedKey)
    }

    private var canCollect: Bool {
        featureFlagsProvider.isEnabled(.checkForReinstalls) &&
        profilePrefs.boolForKey(PrefsKeys.TermsOfUseAccepted) == true &&
        (profilePrefs.boolForKey(AppConstants.prefSendUsageData) ?? true)
    }

    func update() {
        guard !AppConstants.isRunningUnitTest else { return }
        Task {
            do {
                try await onForeground()
            } catch {
                // [IHC] Careful, a refresh status update can call this error too. We probably want the error handling lower.
                // Likely we want to log a fatal error to sentry for anything that prevents us from sending the telemetry,
                // and a warning level breadcrumb just for an issue saving to the keychain any local updates (last seen
                // timestamp).
                logger.log("Could not update installation history",
                           level: .warning,
                           category: .telemetry,
                           description: error.localizedDescription)
            }
        }
    }

    func onForeground() async throws {
        guard canCollect, !isProcessing else { return }
        initializeProcessingState()
        isProcessing = true
        defer { isProcessing = false }

        if !isInstallationProcessed {
            try await processInstallationHistory()
        } else {
            try refreshLastSeenDate()
        }
    }

    /// Gets the current install history from the keychain and then saves the newest values with current timestamps.
    func getAndUpdateInstallationHistory() throws -> InstallationHistory {
        let currentHistory = try history.load()
        let previous: InstallationHistory?

        switch currentHistory {
        case .missing, .corrupt:
            if currentHistory == .corrupt {
                // TODO add fatal error sentry

            }

            // If history is missing or corrupt, the best we can do is set it again
            let newHistory = InstallationHistory(
                installCounter: 0,
                lastSeenDate: dateProvider.now()
            )

            try history.save(
                newHistory
            )

            return newHistory

        case .valid(let currentInstallHistory):
            let currentCounter = currentInstallHistory.installCounter
            var nextCounter = currentCounter + 1

            if nextCounter > Int64.max { nextCounter = Int64.max }

            try history.save(
                InstallationHistory(
                    installCounter: nextCounter,
                    lastSeenDate: dateProvider.now()
                )
            )

            return currentInstallHistory
        }
    }

    func getAppAcquisition() async throws -> AppAcquisition {
        let acquisitionResult = await acquisition.fetch()

        switch acquisitionResult {
        case .available(let appAcquisition):
            return appAcquisition

        case .unavailable(let error):
            throw error
        }
    }

    /// Increments the install count and updates history for a new installation.
    /// Saves the count, previous last seen date, and available purchase details to Glean.
    private func processInstallationHistory() async throws {
        // A. Get current keychain values + update values
        let currentInstallHistory = try getAndUpdateInstallationHistory()

        // B. Get current app store receipt values
        let appAcquisition = try await getAppAcquisition()

        // FIXME Do we still need these somewhere?
        try Task.checkCancellation()
        guard canCollect else { return } // [IHC] Is this in case the user disabled telemetry while async work happened?

        // C. Record Glean telemetry (TODO - Move to InstallationTelemetry struct)
        recordInstallationHistory(installationHistory: currentInstallHistory)
        recordAcquisition(appAcquisition: appAcquisition)
        // TODO also submit the ping from the telemetry struct
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.installation)

        // D. Save done processing
        installationPrefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
    }

    // TODO Move to telemetry struct
    /// Saves the original purchase date and app version to Glean when available.
    private func recordAcquisition(appAcquisition: AppAcquisition) {
        gleanWrapper.recordDatetime(
            for: GleanMetrics.Installation.originalPurchaseDate,
            value: appAcquisition.originalPurchaseDate
        )
        gleanWrapper.recordString(
            for: GleanMetrics.Installation.originalAppVersion,
            value: appAcquisition.originalAppVersion
        )
    }

    // TODO Move to telemetry struct
    private func recordInstallationHistory(installationHistory: InstallationHistory) {
        gleanWrapper.recordQuantity(
            for: GleanMetrics.Installation.installCounter,
            value: installationHistory.installCounter
        )

        gleanWrapper.recordDatetime(
            for: GleanMetrics.Installation.lastSeenDate,
            value: installationHistory.lastSeenDate
        )
    }

    /// Updates the last seen date on later foregrounds, keeping the same install count.
    private func refreshLastSeenDate() throws {
        let historyState = try history.load()
        let counter: Int64
        switch historyState {
        case .missing:
            counter = 1
        case .valid(let history):
            counter = history.installCounter
        case .corrupt:
            return
        }
        try history.save(
            InstallationHistory(
                installCounter: counter,
                lastSeenDate: dateProvider.now()
            )
        )
    }
}
