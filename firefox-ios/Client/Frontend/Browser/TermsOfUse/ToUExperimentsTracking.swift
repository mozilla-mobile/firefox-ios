// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Shared
import struct MozillaAppServices.EnrolledExperiment

/// Handles tracking of Terms of Use experiment enrollment and resets dismissal state
/// when users switch between experiments or branches.
/// Automatically sets up observer for experiment changes on initialization.
@MainActor
final class ToUExperimentsTracking {
    private let prefs: Prefs
    private let experimentChangeObserver: ExperimentChangeObserver

    init(prefs: Prefs) {
        self.prefs = prefs
        self.experimentChangeObserver = ExperimentChangeObserver(prefs: prefs)
    }

    /// Resets dismissal state if experiment configuration changed.
    /// Users who have already accepted ToU are excluded.
    /// Does not reset if bottom sheet hasn't been shown yet (first launch).
    /// Always stores experiment info to track user's enrollment, even on first launch.
    func resetToUDataIfNeeded(currentExperiment: EnrolledExperiment? = nil) {
        guard !(prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false) else { return }

        let experiment = currentExperiment ?? getCurrentToUExperiment()
        let hasShownFirstTime = prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) ?? false
        if hasShownFirstTime {
            // Compare previous stored experiment with current one and reset if needed.
            resetDismissalStateIfExperimentChanged(currentExperiment: experiment)
        }
        storeExperimentInfo(currentExperiment: experiment)
    }

    /// Gets the current ToU experiment from Nimbus where user is enrolled.
    /// Prioritizes stored experiment slug if it exists, otherwise returns the first ToU experiment.
    func getCurrentToUExperiment() -> EnrolledExperiment? {
        let activeExperiments = Experiments.shared.getActiveExperiments()
        let touExperiments = activeExperiments.filter { $0.featureIds.contains("tou-feature") }

        guard !touExperiments.isEmpty else { return nil }

        if let storedSlug = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug),
           let storedExperiment = touExperiments.first(where: { $0.slug == storedSlug }) {
            return storedExperiment
        }

        let sortedExperiments = touExperiments.sorted { $0.slug < $1.slug }
        return sortedExperiments.first
    }

    /// Resets dismissal state if the tracked experiment changed or disappeared.
    /// Handles: slug changes, branch changes, and unenrollment.
    /// Note: If storedSlug is nil (first run with new code), we don't reset to avoid affecting
    /// users who are already in an experiment. We only reset when we have a stored slug that changes.
    private func resetDismissalStateIfExperimentChanged(currentExperiment: EnrolledExperiment?) {
        let storedSlug = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug)
        let storedBranch = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentBranch)
        let currentSlug = currentExperiment?.slug
        let currentBranch = currentExperiment?.branchSlug

        let hasDismissalData = prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) != nil ||
                               (prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0) > 0

        // Only reset if we have a stored slug that changed (slug/branch change or unenrollment).
        // If storedSlug is nil, it means first run with new code - don't reset to avoid affecting
        // users who are already in an experiment.
        let experimentChanged: Bool
        if let storedSlug = storedSlug {
            // We have a stored slug - check if it changed or user was unenrolled
            experimentChanged = storedSlug != currentSlug || storedBranch != currentBranch
        } else {
            // No stored slug - first run with new code, don't reset
            experimentChanged = false
        }

        if experimentChanged && hasDismissalData {
            prefs.removeObjectForKey(PrefsKeys.TermsOfUseDismissedDate)
            prefs.setInt(0, forKey: PrefsKeys.TermsOfUseRemindersCount)
        }
    }

    /// Stores experiment info to track user's enrollment.
    /// Called even on first launch to ensure we know which experiment user is in.
    private func storeExperimentInfo(currentExperiment: EnrolledExperiment?) {
        let currentSlug = currentExperiment?.slug
        let currentBranch = currentExperiment?.branchSlug

        if let slug = currentSlug {
            prefs.setString(slug, forKey: PrefsKeys.TermsOfUseExperimentSlug)
        } else {
            prefs.removeObjectForKey(PrefsKeys.TermsOfUseExperimentSlug)
        }

        if let branch = currentBranch {
            prefs.setString(branch, forKey: PrefsKeys.TermsOfUseExperimentBranch)
        } else {
            prefs.removeObjectForKey(PrefsKeys.TermsOfUseExperimentBranch)
        }
    }
}

final class ExperimentChangeObserver {
    private let observer: NSObjectProtocol

    init(prefs: Prefs) {
        let observer = NotificationCenter.default.addObserver(
            forName: .nimbusExperimentsApplied,
            object: nil,
            queue: .main
        ) { notification in
            Task { @MainActor in
                let tracking = ToUExperimentsTracking(prefs: prefs)
                tracking.resetToUDataIfNeeded()
            }
        }
        self.observer = observer
    }

    deinit {
        NotificationCenter.default.removeObserver(observer)
    }
}
