/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

protocol FeatureFlagsProtocol { }

extension FeatureFlagsProtocol {
    var featureFlags: FeatureFlagsManager {
        return FeatureFlagsManager.shared
    }
}

/// An enum describing the featureID of all features, historical, avalable, or in development.
enum FeatureFlagName: String, CaseIterable {
    case chronologicalTabs
    case inactiveTabs
    case nimbus
    case recentlySaved
    case shakeToRestore
}

class FeatureFlagsManager {

    /// This Singleton should only be accessed directly in places where the
    /// `FeatureFlagsProtocol` is not available. Otherwise, access to the feature
    /// flags system should be done through the protocol, giving access to the
    /// `featureFlags` variable.
    static let shared = FeatureFlagsManager()

    private var profile: Profile!
    private var features: [FeatureFlagName: FlaggableFeature] = [:]

    public func isFeatureActive(_ featureID: FeatureFlagName) -> Bool {
        guard let feature = features[featureID] else { return false }
        return feature.isActive
    }

    /// Toggles the feature on/off, depending on its current status AND whether or not it is
    /// a feature that can be saved to disk. For more information, see `FlaggableFeature`
    public func toggle(_ featureID: FeatureFlagName) {
        features[featureID]?.toggle()
    }

    /// Sets up features with default channel availablility. For ease of use, please add
    /// new features alphabetically.
    public func setupFeatures(with profile: Profile) {
        features.removeAll()

        let chronTabs = FlaggableFeature(withID: .chronologicalTabs, and: profile, enabledFor: [.developer])
        features[.chronologicalTabs] = chronTabs

        let inactiveTabs = FlaggableFeature(withID: .inactiveTabs, and: profile, enabledFor: [.beta, .developer])
        features[.inactiveTabs] = inactiveTabs

        /// Use the Nimbus experimentation platform. If this is `true` then
        /// `Experiments.shared` provides access to Nimbus. If false, it is a dummy object.
        let nimbus = FlaggableFeature(withID: .nimbus, and: profile, enabledFor: [.release, .beta, .developer])
        features[.nimbus] = nimbus

        let recentlySaved = FlaggableFeature(withID: .recentlySaved, and: profile, enabledFor: [.beta, .developer])
        features[.recentlySaved] = recentlySaved

        let shakeToRestore = FlaggableFeature(withID: .shakeToRestore, and: profile, enabledFor: [.beta, .developer, .other])
        features[.shakeToRestore] = shakeToRestore
    }
}
