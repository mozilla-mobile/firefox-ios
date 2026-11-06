// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

/// Tracks the install count and last seen date, along with the original purchase date and app version.
/// Keychain history survives reinstalls
@MainActor
final class InstallationTelemetryService {
    private let history: InstallationHistoryStoring
    private let acquisition: AppAcquisitionProviding
    private let telemetry: InstallationTelemetry
    private let profilePrefs: Prefs
    private let featureFlagsProvider: FeatureFlagProviding
    private let dateProvider: DateProvider
    private let installationPrefs: Prefs
    private let logger: Logger
    private var isProcessing = false
    private var hasProcessedInstallation: Bool {
        installationPrefs.boolForKey(PrefsKeys.installationProcessedKey) == true
    }
    private var canCollectTelemetry: Bool {
        featureFlagsProvider.isEnabled(.checkForReinstalls) &&
        profilePrefs.boolForKey(PrefsKeys.TermsOfUseAccepted) == true &&
        (profilePrefs.boolForKey(AppConstants.prefSendUsageData) == true)
    }

    init(
        profilePrefs: Prefs,
        installationPrefs: Prefs = NSUserDefaultsPrefs(prefix: "installationTelemetry", userDefaults: .standard),
        history: InstallationHistoryStoring = InstallationHistoryStore(),
        acquisition: AppAcquisitionProviding = StoreKitAppAcquisitionProvider(),
        telemetry: InstallationTelemetry = InstallationTelemetry(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        dateProvider: DateProvider = SystemDateProvider(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.installationPrefs = installationPrefs
        self.history = history
        self.acquisition = acquisition
        self.telemetry = telemetry
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

    func update() {
        guard !AppConstants.isRunningUnitTest else { return }
        Task {
            do {
                try await updateInstallationHistory()
            } catch {
                logger.log("Could not update installation history",
                           level: hasProcessedInstallation ? .warning : .fatal,
                           category: .telemetry,
                           description: error.localizedDescription)
            }
        }
    }

    func updateInstallationHistory() async throws {
        guard canCollectTelemetry, !isProcessing else { return }
        initializeProcessingState()
        isProcessing = true
        defer { isProcessing = false }

        let currentHistory = try history.load()
        let updatedHistory: InstallationHistory
        if !hasProcessedInstallation {
            updatedHistory = try await processNewInstallation(currentHistory: currentHistory)
        } else {
            updatedHistory = refreshLastSeenDate(currentHistory)
        }

        guard canCollectTelemetry else { return }
        try saveInstallationHistory(updatedHistory)
    }

    /// Prepares history for a new installation with an updated count and last-seen date.
    private func historyForNewInstallation(_ currentHistory: InstallationHistoryState) -> InstallationHistory {
        switch currentHistory {
        case .missing, .corrupt:
            let newHistory = InstallationHistory(
                installCounter: 1,
                lastSeenDate: dateProvider.now()
            )
            return newHistory

        case .valid(let currentInstallHistory):
            let currentCounter = currentInstallHistory.installCounter
            var nextCounter = currentCounter
            if currentCounter < Int64.max {
                nextCounter += 1
            }

            return InstallationHistory(installCounter: nextCounter,
                                       lastSeenDate: dateProvider.now())
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

    /// Prepares the new history and records installation telemetry.
    private func processNewInstallation(currentHistory: InstallationHistoryState) async throws -> InstallationHistory {
        let appAcquisition = try await getAppAcquisition()
        try Task.checkCancellation()
        let installationHistory = historyForNewInstallation(currentHistory)
        guard canCollectTelemetry else { return installationHistory }

        var previousLastSeenDate: Date?
        if case .valid(let history) = currentHistory {
            previousLastSeenDate = history.lastSeenDate
        }
        telemetry.recordInstallationHistory(count: installationHistory.installCounter, lastSeenDate: previousLastSeenDate)
        telemetry.recordAcquisition(appAcquisition: appAcquisition)
        return installationHistory
    }

    private func saveInstallationHistory(_ installationHistory: InstallationHistory) throws {
        try history.save(installationHistory)
        if !hasProcessedInstallation {
            telemetry.submit()
            installationPrefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
        }
    }

    /// Updates the last seen date on later foregrounds, keeping the same install count.
    private func refreshLastSeenDate(_ historyState: InstallationHistoryState) -> InstallationHistory {
        let counter: Int64
        switch historyState {
        case .missing, .corrupt:
            counter = 1
        case .valid(let history):
            counter = history.installCounter
        }
        return InstallationHistory(installCounter: counter, lastSeenDate: dateProvider.now())
    }
}
