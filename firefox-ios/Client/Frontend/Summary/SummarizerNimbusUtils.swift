// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Tiny utility to simplify checking for availability of the summarizers
struct SummarizerNimbusUtils: FeatureFlaggable {
    static let shared = SummarizerNimbusUtils()

    func isAppleSummarizerEnabled() -> Bool {
        #if canImport(FoundationModels)
            let isFlagEnabled = featureFlags.isFeatureEnabled(.appleSummarizer, checking: .buildOnly)
            return AppleIntelligenceUtil().isAppleIntelligenceAvailable && isFlagEnabled
        #else
            return false
        #endif
    }

    func isHostedSummarizerEnabled() -> Bool {
        return featureFlags.isFeatureEnabled(.hostedSummarizer, checking: .buildOnly)
    }

    func isAppleSummarizerToolbarEndpointEnabled() -> Bool {
        let isFlagEnabled = featureFlags.isFeatureEnabled(.appleSummarizerToolbarEntrypoint, checking: .buildOnly)
        return isAppleSummarizerEnabled() && isFlagEnabled
    }

    func isHostedSummarizerToolbarEndpointEnabled() -> Bool {
        let isFlagEnabled = featureFlags.isFeatureEnabled(.hostedSummarizerToolbarEntrypoint, checking: .buildOnly)
        return isHostedSummarizerEnabled() && isFlagEnabled
    }
}
