// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Shared
import struct MozillaAppServices.EnrolledExperiment

/// Tracking ToU experiments and reset dismissal data when experiment changes
/// Avoid reset data for users who accepted ToU or already enrolled

final class ToUExperimentsTracking {
    private enum ToUExperimentConstants {
        static let featureId = "tou-feature"
    }

    private let prefs: Prefs
    private let experimentChangeObserver: ExperimentChangeObserver

    init(prefs: Prefs) {
        self.prefs = prefs
        self.experimentChangeObserver = ExperimentChangeObserver(prefs: prefs)
    }

    private var hasDismissalData: Bool {
        prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) != nil ||
        (prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0) > 0
    }

    func resetToUDataIfNeeded(currentExperiment: EnrolledExperiment? = nil) {
        guard !(prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false) else { return }

        let experiment = currentExperiment ?? getCurrentToUExperiment()
        let previousSlug = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug)
        let previousBranch = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentBranch)
        let trackingInitialized = prefs.boolForKey(PrefsKeys.TermsOfUseExperimentTrackingInitialized) ?? false

        storeExperimentInfo(currentExperiment: experiment)

        let hasShownFirstTime = prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) ?? false
        if hasShownFirstTime {
            resetDismissalStateIfExperimentChanged(
                currentExperiment: experiment,
                previousSlug: previousSlug,
                previousBranch: previousBranch,
                trackingInitialized: trackingInitialized
            )
        }
        prefs.setBool(true, forKey: PrefsKeys.TermsOfUseExperimentTrackingInitialized)
    }

    func getCurrentToUExperiment() -> EnrolledExperiment? {
        let activeExperiments = Experiments.shared.getActiveExperiments()
        let touExperiments = activeExperiments.filter { $0.featureIds.contains(ToUExperimentConstants.featureId) }

        guard !touExperiments.isEmpty else { return nil }

        if let storedSlug = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug),
           let storedExperiment = touExperiments.first(where: { $0.slug == storedSlug }) {
            return storedExperiment
        }
        let sortedExperiments = touExperiments.sorted { $0.slug < $1.slug }
        return sortedExperiments.first
    }

    private func resetDismissalStateIfExperimentChanged(
        currentExperiment: EnrolledExperiment?,
        previousSlug: String?,
        previousBranch: String?,
        trackingInitialized: Bool
    ) {
        let currentSlug = currentExperiment?.slug
        let currentBranch = currentExperiment?.branchSlug

        let experimentChanged: Bool
        switch (previousSlug, currentSlug) {
        case let (previous?, current?):
            /// User was enrolled before and is still enrolled: reset only if experiment slug
            /// or branch changed (retargeting user)
            experimentChanged = previous != current || previousBranch != currentBranch
        case (.some, nil):
            /// User was enrolled and is now unenrolled: do not reset here;
            /// dismissal data is reset when users enroll again into a new experiment
            experimentChanged = false
        case (nil, _):
            /// Legacy user with no stored slug: reset only after tracking is initialized,
            /// to avoid affecting users that are already enrolled
            experimentChanged = trackingInitialized && currentExperiment != nil && hasDismissalData
        }
        guard experimentChanged, hasDismissalData else { return }

        prefs.removeObjectForKey(PrefsKeys.TermsOfUseDismissedDate)
        prefs.setInt(0, forKey: PrefsKeys.TermsOfUseRemindersCount)
        prefs.setBool(false, forKey: PrefsKeys.TermsOfUseFirstShown)
    }

    /// Store current experiment slug/branch only when enrolled,
    /// so we can avoid unwanted data reset
    private func storeExperimentInfo(currentExperiment: EnrolledExperiment?) {
        guard let experiment = currentExperiment else { return }
        updatePersistedValue(experiment.slug, forKey: PrefsKeys.TermsOfUseExperimentSlug)
        updatePersistedValue(experiment.branchSlug, forKey: PrefsKeys.TermsOfUseExperimentBranch)
    }

    private func updatePersistedValue(_ value: String?, forKey key: String) {
        if let value = value {
            prefs.setString(value, forKey: key)
        } else {
            prefs.removeObjectForKey(key)
        }
    }

    private final class ExperimentChangeObserver: Notifiable {
        private let prefs: Prefs
        private let notificationCenter: NotificationProtocol

        init(prefs: Prefs, notificationCenter: NotificationProtocol = NotificationCenter.default) {
            self.prefs = prefs
            self.notificationCenter = notificationCenter
            startObservingNotifications(
                withNotificationCenter: notificationCenter,
                forObserver: self,
                observing: [.nimbusExperimentsApplied]
            )
        }

        nonisolated func handleNotifications(_ notification: Notification) {
            guard notification.name == .nimbusExperimentsApplied else { return }
            let prefs = self.prefs
            ensureMainThread {
                let tracking = ToUExperimentsTracking(prefs: prefs)
                tracking.resetToUDataIfNeeded()
            }
        }
    }
}
