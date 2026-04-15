// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Protocol for checking whether a feature is enabled via Nimbus remote config.
protocol NimbusFeatureFlagProviding: Sendable {
    func isEnabled(_ flag: FeatureFlagID) -> Bool
}

/// Wraps NimbusFeatureFlagLayer with debug override support for beta/dev builds.
/// Registered in AppContainer; accessed via `NimbusFeatureFlagProviding` protocol.
final class NimbusFeatureFlags: NimbusFeatureFlagProviding, @unchecked Sendable {
    private let layer: NimbusFeatureFlagLayer
    private let prefs: Prefs

    init(layer: NimbusFeatureFlagLayer = NimbusManager.shared.featureFlagLayer,
         prefs: Prefs) {
        self.layer = layer
        self.prefs = prefs
    }

    func isEnabled(_ flag: FeatureFlagID) -> Bool {
        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        if let debugKey = flag.debugKey,
           let override = prefs.boolForKey(debugKey) {
            return override
        }
        #endif
        return layer.checkNimbusConfigFor(flag)
    }
}

// MARK: - DI Access Protocol

/// Adopt this protocol to access Nimbus feature flags via AppContainer.
/// Replaces FeatureFlaggable for Nimbus checks.
protocol FeatureFlaggable {
    var featureFlagsProvider: NimbusFeatureFlagProviding { get }
}

extension FeatureFlaggable {
    var featureFlagsProvider: NimbusFeatureFlagProviding {
        AppContainer.shared.resolve()
    }
}
