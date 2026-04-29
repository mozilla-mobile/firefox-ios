// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Protocol for checking whether a feature is enabled via Nimbus remote config.
protocol FeatureFlagProviding: Sendable {
    func isEnabled(_ flag: FeatureFlagID) -> Bool
    func setDebugOverride(_ flag: FeatureFlagID, to value: Bool)
}

/// Wraps NimbusFeatureFlagLayer with debug override support for beta/dev builds.
/// Registered in AppContainer; accessed via `FeatureFlagProviding` protocol.
final class FeatureFlagsProvider: FeatureFlagProviding, @unchecked Sendable {
    private let prefs: Prefs
    private let backendLayer: NimbusFeatureFlagLayerProviding

    init(
        prefs: Prefs,
        backendLayer: NimbusFeatureFlagLayerProviding
    ) {
        self.prefs = prefs
        self.backendLayer = backendLayer
    }

    /// Used for checking the status of a feature flag from the feature flag backend
    func isEnabled(_ flag: FeatureFlagID) -> Bool {
        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        if let debugKey = flag.debugKey,
           let override = prefs.boolForKey(debugKey) {
            return override
        }
        #endif
        return backendLayer.checkNimbusConfigFor(flag)
    }

    /// Used specifically for overriding the status of a feature flag from the backend.
    func setDebugOverride(_ flag: FeatureFlagID, to value: Bool) {
        guard let debugKey = flag.debugKey else { return }
        prefs.setBool(value, forKey: debugKey)
    }
}

// MARK: - DI Access Protocol

/// Adopt this protocol to access Nimbus feature flags via AppContainer.
/// Replaces FeatureFlaggable for Nimbus checks.
protocol FeatureFlaggable {
    var featureFlagsProvider: FeatureFlagProviding { get }
}

extension FeatureFlaggable {
    var featureFlagsProvider: FeatureFlagProviding {
        AppContainer.shared.resolve()
    }
}
