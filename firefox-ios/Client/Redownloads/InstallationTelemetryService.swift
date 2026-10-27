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
    private var isProcessing = false

    init(
        profilePrefs: Prefs,
        installationPrefs: Prefs = NSUserDefaultsPrefs(prefix: "installationTelemetry", userDefaults: .standard),
        history: InstallationHistoryStoring = InstallationHistoryStore(),
        acquisition: AppAcquisitionProviding = StoreKitAppAcquisitionProvider(),
        gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.installationPrefs = installationPrefs
        self.history = history
        self.acquisition = acquisition
        self.gleanWrapper = gleanWrapper
        self.profilePrefs = profilePrefs
        self.featureFlagsProvider = featureFlagsProvider
        self.dateProvider = dateProvider
        initializeProcessingState()
    }

    /// Marks existing users as processed so enabling this feature does not count them as new installations.
    private func initializeProcessingState() {
        guard featureFlagsProvider.isEnabled(.checkForReinstalls) else { return }
        guard installationPrefs.boolForKey(PrefsKeys.installationProcessedKey) == nil else { return }

        let hasSeenIntro = profilePrefs.intForKey(PrefsKeys.IntroSeen) != nil
        installationPrefs.setBool(hasSeenIntro, forKey: PrefsKeys.installationProcessedKey)
    }

    private var isInstallationProcessed: Bool {
        installationPrefs.boolForKey(PrefsKeys.installationProcessedKey) == true
    }

    private var canCollect: Bool {
        featureFlagsProvider.isEnabled(.checkForReinstalls) &&
        profilePrefs.boolForKey(PrefsKeys.TermsOfUseAccepted) == true &&
        (profilePrefs.boolForKey(AppConstants.prefSendUsageData) ?? true)
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

    /// When history is corrupt, saves only the available purchase date and app version to Glean.
    private func recordAcquisitionOnly() async throws {
        let result = await acquisition.fetch()
        try Task.checkCancellation()
        guard canCollect else { return }
        recordAcquisition(result)
        installationPrefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
    }

    /// Increments the install count and updates history for a new installation.
    /// Saves the count, previous last seen date, and available purchase details to Glean.
    private func processInstallationHistory() async throws {
        let historyState = try history.load()
        let previous: InstallationHistory?
        switch historyState {
        case .missing:
            previous = nil
        case .valid(let history):
            previous = history
        case .corrupt:
            try await recordAcquisitionOnly()
            return
        }

        let previousCounter = previous?.installCounter ?? 0
        guard previousCounter < Int64.max else { return }
        let nextCounter = previousCounter + 1

        let acquisitionResult = await acquisition.fetch()
        try Task.checkCancellation()
        guard canCollect else { return }

        try history.save(
            InstallationHistory(
                installCounter: nextCounter,
                lastSeenDate: dateProvider.now()
            )
        )

        gleanWrapper.recordQuantity(
            for: GleanMetrics.Installation.installCounter,
            value: nextCounter
        )

        if let lastSeenDate = previous?.lastSeenDate {
            gleanWrapper.recordString(
                for: GleanMetrics.Installation.lastSeenDate,
                value: lastSeenDate.toISO8601DateString()
            )
        }

        recordAcquisition(acquisitionResult)
        installationPrefs.setBool(true, forKey: PrefsKeys.installationProcessedKey)
    }

    /// Saves the original purchase date and app version to Glean when available.
    private func recordAcquisition(_ result: AcquisitionOutcome) {
        guard case .available(let info) = result else { return }
        gleanWrapper.recordString(
            for: GleanMetrics.Installation.originalPurchaseDate,
            value: info.originalPurchaseDate.toISO8601DateString()
        )
        gleanWrapper.recordString(
            for: GleanMetrics.Installation.originalAppVersion,
            value: info.originalAppVersion
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
