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
    func resetToUDataIfNeeded(currentExperiment: EnrolledExperiment? = nil) {
        guard !(prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false) else { return }
        
        let experiment = currentExperiment ?? getCurrentToUExperiment()
        resetDismissalStateIfExperimentChanged(currentExperiment: experiment)
    }
    
    /// Gets the current ToU experiment from Nimbus.
    /// Filters to experiments with "tou-feature" in featureIds.
    func getCurrentToUExperiment() -> EnrolledExperiment? {
        let activeExperiments = Experiments.shared.getActiveExperiments()
        let touExperiments = activeExperiments.filter { $0.featureIds.contains("tou-feature") }
        
        guard !touExperiments.isEmpty else { return nil }
        
        if let storedSlug = prefs.stringForKey(PrefsKeys.TermsOfUseExperimentSlug),
           let storedExperiment = touExperiments.first(where: { $0.slug == storedSlug }) {
            return storedExperiment
        }
        
        return touExperiments.first
    }
    
    /// Identifies the specific ToU experiment from a list of active experiments.
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
        
        // Only consider it a change if we had a stored experiment before
        // This prevents resetting on first launch when stored is nil and current exists
        let experimentChanged: Bool
        if storedSlug != nil {
            // Had a stored experiment - check if it changed
            experimentChanged = storedSlug != currentSlug || storedBranch != currentBranch
        } else {
            // No stored experiment - only consider it changed if we're unenrolling (current is nil)
            // If current exists, it's first enrollment, don't reset dismissal state
            experimentChanged = currentSlug == nil
        }
        
        // Only reset if experiment actually changed AND we have dismissal data to reset
        // This prevents resetting when bottom sheet is already shown (first launch scenario)
        if experimentChanged {
            // Check if there's dismissal data to reset - if not, it's first launch, don't reset
            let hasDismissalData = prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) != nil ||
                                   (prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0) > 0
            
            if hasDismissalData {
                prefs.removeObjectForKey(PrefsKeys.TermsOfUseDismissedDate)
                prefs.setInt(0, forKey: PrefsKeys.TermsOfUseRemindersCount)
            }
        }
        
        // Always update stored experiment info to current state
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
