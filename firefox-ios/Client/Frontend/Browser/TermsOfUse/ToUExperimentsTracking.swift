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
    private let experimentChangeObserver: ExperimentChangeObserver?

    init(prefs: Prefs, subscribeToExperimentChanges: Bool = true) {
        self.prefs = prefs
        self.experimentChangeObserver = subscribeToExperimentChanges ? ExperimentChangeObserver(prefs: prefs) : nil
    }

    private var hasDismissalData: Bool {
        prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) != nil ||
        (prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0) > 0
    }

    func resetToUDataIfNeeded(currentExperiment: EnrolledExperiment? = nil) {
        guard !(prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false) else { return }

        let experiment = currentExperiment ?? getCurrentToUExperiment()
        let previousExperimentKey = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentKey)
        let currentExperimentKey = experiment.map { experimentKey($0) }
        let trackingInitialized = prefs.boolForKey(PrefsKeys.TermsOfUseExperimentTrackingInitialized) ?? false

        let hasShownFirstTime = prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) ?? false
        if hasShownFirstTime {
            resetDismissalStateIfExperimentChanged(
                currentExperiment: experiment,
                previousExperimentKey: previousExperimentKey,
                currentExperimentKey: currentExperimentKey,
                trackingInitialized: trackingInitialized
            )
        }
        storeExperimentInfo(currentExperiment: experiment)
        prefs.setBool(true, forKey: PrefsKeys.TermsOfUseExperimentTrackingInitialized)
    }

    func getCurrentToUExperiment() -> EnrolledExperiment? {
        let activeExperiments = Experiments.shared.getActiveExperiments()
        let touExperiments = activeExperiments.filter { $0.featureIds.contains(ToUExperimentConstants.featureId) }

        guard !touExperiments.isEmpty else { return nil }

        /// Select the experiment previously tracked since can be multiple ToU experiments active
        if let previousExperimentKey = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentKey),
           let storedExperiment = touExperiments.first(where: { experimentKey($0) == previousExperimentKey }) {
            return storedExperiment
        }

        let sortedExperiments = touExperiments.sorted { $0.slug < $1.slug }
        return sortedExperiments.first
    }

    private func resetDismissalStateIfExperimentChanged(
        currentExperiment: EnrolledExperiment?,
        previousExperimentKey: String?,
        currentExperimentKey: String?,
        trackingInitialized: Bool
    ) {
        let experimentChanged: Bool
        switch (previousExperimentKey, currentExperimentKey) {
        case let (prev?, curr?):
            /// User was enrolled before and is still enrolled: reset only if experiment
            /// key changed (retargeting user)
            experimentChanged = prev != curr
        case (.some, nil):
            /// User was enrolled and is now unenrolled: do not reset here;
            /// dismissal data is reset when users enroll again into a new experiment
            experimentChanged = false
        case (nil, _):
            /// No stored experiment key (legacy users): reset only
            /// after tracking initialized, to avoid affecting users already enrolled
            experimentChanged = trackingInitialized && currentExperiment != nil && hasDismissalData
        }
        guard experimentChanged, hasDismissalData else { return }

        prefs.removeObjectForKey(PrefsKeys.TermsOfUseDismissedDate)
        prefs.setInt(0, forKey: PrefsKeys.TermsOfUseRemindersCount)
        prefs.setBool(false, forKey: PrefsKeys.TermsOfUseFirstShown)
        prefs.setBool(false, forKey: PrefsKeys.TermsOfUseShownRecorded)
    }

    /// Experiment key: slug|branch|name. New experiment variant = new name in Experimenter
    private func experimentKey(_ experiment: EnrolledExperiment) -> String {
        "\(experiment.slug)|\(experiment.branchSlug)|\(experiment.userFacingName)"
    }

    private func storeExperimentInfo(currentExperiment: EnrolledExperiment?) {
        guard let experiment = currentExperiment else { return }
        prefs.setString(experimentKey(experiment), forKey: PrefsKeys.TermsOfUseExperimentKey)
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
                let tracking = ToUExperimentsTracking(prefs: prefs, subscribeToExperimentChanges: false)
                tracking.resetToUDataIfNeeded()
            }
        }
    }
}
