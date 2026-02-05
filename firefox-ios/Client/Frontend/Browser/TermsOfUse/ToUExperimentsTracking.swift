// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Shared
import struct MozillaAppServices.EnrolledExperiment

/// Handles tracking of Terms of Use (ToU) experiment enrollment and resets dismissal state
/// when users switch between experiments or branches.
@MainActor
struct ToUExperimentsTracking {
    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    /// Resets dismissal state if experiment configuration changed.
    /// Users who have already accepted ToU are excluded.
    /// Does not reset if bottom sheet hasn't been shown yet (first launch).
    func resetToUDataIfNeeded(currentExperiment: EnrolledExperiment? = nil) {
        guard !(prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false) else { return }

        // Don't reset if bottom sheet hasn't been shown yet (first launch scenario)
        // This prevents resetting when observer fires before bottom sheet is displayed
        let hasShownFirstTime = prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) ?? false
        guard hasShownFirstTime else { return }

        let experiment = currentExperiment ?? getCurrentToUExperiment()
        resetDismissalStateIfExperimentChanged(currentExperiment: experiment)
    }

    /// Gets the current ToU experiment from Nimbus.
    /// Filters to experiments with "tou-feature" in featureIds.
    func getCurrentToUExperiment() -> EnrolledExperiment? {
        let activeExperiments = Experiments.shared.getActiveExperiments()
        return identifyToUExperiment(from: activeExperiments)
    }

    /// Identifies the ToU experiment from a list of active experiments.
    /// Filters to experiments with "tou-feature" in featureIds.
    /// Prioritizes stored experiment slug if it exists in the list.
    func identifyToUExperiment(from experiments: [EnrolledExperiment]) -> EnrolledExperiment? {
        let touExperiments = experiments.filter { $0.featureIds.contains("tou-feature") }

        guard !touExperiments.isEmpty else { return nil }

        if let storedSlug = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug),
           let storedExperiment = touExperiments.first(where: { $0.slug == storedSlug }) {
            return storedExperiment
        }

        return touExperiments.first
    }
    
    /// Sets up observer for Nimbus experiment changes.
    /// Observer is automatically cleaned up when returned object is deallocated.
    func setupExperimentChangeObserver() -> ExperimentChangeObserver {
        let prefs = self.prefs

        let observer = NotificationCenter.default.addObserver(
            forName: .nimbusExperimentsApplied,
            object: nil,
            queue: .main
        ) { notification in
            let experiments = notification.object as? [EnrolledExperiment]

            Task { @MainActor in
                let tracking = ToUExperimentsTracking(prefs: prefs)
                let touExperiment: EnrolledExperiment?
                if let experiments = experiments {
                    touExperiment = tracking.identifyToUExperiment(from: experiments)
                } else {
                    touExperiment = nil
                }
                tracking.resetToUDataIfNeeded(currentExperiment: touExperiment)
            }
        }

        return ExperimentChangeObserver(observer: observer)
    }

    private func resetDismissalStateIfExperimentChanged(currentExperiment: EnrolledExperiment?) {
        let storedSlug = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug)
        let storedBranch = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentBranch)
        let currentSlug = currentExperiment?.slug
        let currentBranch = currentExperiment?.branchSlug

        // Check if we have dismissal data to reset
        let hasDismissalData = prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) != nil ||
                               (prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0) > 0

        // Determine if experiment changed
        let experimentChanged: Bool
        if storedSlug != nil {
            // Had a stored experiment - check if it changed
            // Unenroll (currentSlug == nil) is always considered a change
            experimentChanged = storedSlug != currentSlug || storedBranch != currentBranch
        } else {
            // No stored experiment - reset if re-enrolling (allows re-targeting)
            // hasShownFirstTime check in resetToUDataIfNeeded prevents reset on first launch
            experimentChanged = hasDismissalData && currentSlug != nil
        }

        // Reset dismissal data if experiment changed and we have data to reset
        if experimentChanged && hasDismissalData {
            prefs.removeObjectForKey(PrefsKeys.TermsOfUseDismissedDate)
            prefs.setInt(0, forKey: PrefsKeys.TermsOfUseRemindersCount)
        }

        // Update stored experiment info to current state
        // Remove keys when unenrolled since user is no longer in any experiment
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

    init(observer: NSObjectProtocol) {
        self.observer = observer
    }

    deinit {
        NotificationCenter.default.removeObserver(observer)
    }
}
