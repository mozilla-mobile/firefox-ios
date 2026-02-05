// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Shared
import struct MozillaAppServices.EnrolledExperiment

/// Handles tracking of Terms of Use experiments and resets dismissal state
/// when users enrollment status changes.
final class ToUExperimentsTracking {
    private let prefs: Prefs
    private let experimentChangeObserver: ExperimentChangeObserver

    init(prefs: Prefs) {
        self.prefs = prefs
        self.experimentChangeObserver = ExperimentChangeObserver(prefs: prefs)
    }

    /// Resets dismissal state if experiment configuration changed.
    /// Excludes users who have already accepted ToU.
    /// Only resets if bottom sheet has been shown at least once.
    func resetToUDataIfNeeded(currentExperiment: EnrolledExperiment? = nil) {
        guard !(prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false) else { return }

        let experiment = currentExperiment ?? getCurrentToUExperiment()

        // Read previous values BEFORE storing new ones
        let previousSlug = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug)
        let previousBranch = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentBranch)

        // Store experiment info BEFORE checking if reset is needed
        // This ensures slug is stored before we check if user is already in experiment
        storeExperimentInfo(currentExperiment: experiment)

        let hasShownFirstTime = prefs.boolForKey(PrefsKeys.TermsOfUseFirstShown) ?? false
        if hasShownFirstTime {
            resetDismissalStateIfExperimentChanged(
                currentExperiment: experiment,
                previousSlug: previousSlug,
                previousBranch: previousBranch
            )
        }
    }

    /// Find the current ToU experiment from Nimbus, where user is enrolled
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

    /// Resets dismissal state if the tracked experiment changed.
    /// Handles slug, branch, and enrollment status changes.
    /// Only called when TermsOfUseFirstShown = true.
    private func resetDismissalStateIfExperimentChanged(
        currentExperiment: EnrolledExperiment?,
        previousSlug: String?,
        previousBranch: String?
    ) {
        let currentSlug = currentExperiment?.slug
        let currentBranch = currentExperiment?.branchSlug

        let hasDismissalData = prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) != nil ||
                               (prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0) > 0

        // Compare previous stored values with current experiment.
        // Since we store before comparing, we can detect slug/branch changes and enrollment.
        let experimentChanged: Bool
        if let previousSlug = previousSlug {
            // Previous slug exists: user was already enrolled
            // Don't reset on unenrollment, only reset when enrolling in a different experiment/branch
            if currentSlug == nil {
                // User unenrolled: don't reset, just clear stored slug
                experimentChanged = false
            } else {
                // User enrolled in different experiment or branch: reset to allow retargeting
                experimentChanged = previousSlug != currentSlug || previousBranch != currentBranch
            }
        } else {
            // No previous slug: user was not enrolled, now enrolling
            // Reset to allow retargeting (user was unenrolled and now enrolling)
            // Users already enrolled have slug stored before, so previousSlug won't be nil
            if currentExperiment != nil && hasDismissalData {
                // User enrolling after being unenrolled: reset to allow retargeting
                experimentChanged = true
            } else {
                // User enrolling for first time (no dismissal data): don't reset
                experimentChanged = false
            }
        }

        if experimentChanged && hasDismissalData {
            prefs.removeObjectForKey(PrefsKeys.TermsOfUseDismissedDate)
            prefs.setInt(0, forKey: PrefsKeys.TermsOfUseRemindersCount)
        }
    }

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

final class ExperimentChangeObserver: Notifiable {
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
