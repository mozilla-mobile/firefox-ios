// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Glean
import MozillaAppServices

protocol VersionProviding {
  func object(forInfoDictionaryKey key: String) -> Any?
}

extension Bundle: VersionProviding {}

struct TermsOfServiceManager: FeatureFlaggable {
    var prefs: Prefs
    private let bundle: VersionProviding

    init(prefs: Prefs, bundle: VersionProviding = Bundle.main) {
        self.prefs = prefs
        self.bundle = bundle
    }

    var isFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.tosFeature, checking: .buildAndUser)
    }

    var isAccepted: Bool {
        prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == 1
    }

    var shouldShowScreen: Bool {
        guard featureFlags.isFeatureEnabled(.tosFeature, checking: .buildAndUser) else { return false }

        return prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == nil
    }

    func setAccepted() {
        prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
    }

    func shouldSendTechnicalData(value: Bool) {
        // AdjustHelper.setEnabled($0)
        DefaultGleanWrapper().setUpload(isEnabled: value)
        Experiments.setTelemetrySetting(value)
    }

    // MARK: – Constants

    private enum VersionRange {
        static let minimum = "138.0"
        static let maximum = "138.1"
    }

    private enum Experiment {
        static let onboardingPhase4ID = "new-onboarding-experience-experiment-phase-4-ios"
        static let controlBranch = "control"
    }

    // MARK: – Public API

    /// Returns `true` if all of the following are satisfied:
    /// 1. App version is in [138.0, 138.1)
    /// 2. The TOS feature flag is enabled
    /// 3. User is in the "control" branch of the onboarding experiment
    /// 4. User did not see the TOC screen
    var isAffectedUser: Bool {
        // 1) Version check
        guard isAppVersion(in: VersionRange.minimum..<VersionRange.maximum) else {
            // Outside of the target version window
            return false
        }

        // 2) Feature-flag check
        guard isFeatureEnabled else {
            // TOS feature is disabled
            return false
        }

        // 3) Experiment branch check
        guard isInControlBranch(experimentId: Experiment.onboardingPhase4ID) else {
            // Not in the control group
            return false
        }

        // 4) TOS screen was not shown
        guard shouldShowScreen else {
            return false
        }

        return true
    }

    // MARK: – Helpers

    /// Checks whether the app’s CFBundleShortVersionString lies within the half-open range [min, max).
    func isAppVersion(in range: Range<String>) -> Bool {
        guard let versionString = bundle
            .object(forInfoDictionaryKey: "CFBundleShortVersionString")
                as? String else {
            return false
        }
        let v = versionString as NSString
        let meetsMin  = v.compare(range.lowerBound, options: .numeric) != .orderedAscending
        let belowMax  = v.compare(range.upperBound, options: .numeric) == .orderedAscending
        return meetsMin && belowMax
    }

    /// Returns `true` if the given experiment’s branch slug exists and equals “control”.
    private func isInControlBranch(experimentId: String) -> Bool {
        guard
            let branch = Experiments.shared.getExperimentBranch(experimentId: experimentId)
        else {
            return false
        }
        return branch == Experiment.controlBranch
    }
}
