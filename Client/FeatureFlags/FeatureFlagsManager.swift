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

enum FeatureFlagID: String, CaseIterable {
    case chronologicalTabs
    case inactiveTabs
    case nimbus
    case punyCode
    case recentlySaved
    case shakeToRestore
}

class FeatureFlagsManager {

    /// This singleton should only be accessed directly in places where the
    /// `FeatureFlagsProtocol` is not available.
    static let shared = FeatureFlagsManager()

    private var profile: Profile!
    private var features: [FlaggableFeature] = []

    init() { }

    public func isFeatureActive(_ featureID: FeatureFlagID) -> Bool {
        for feature in features {
            if feature.featureID == featureID {
                return feature.isActive
            }
        }
        return false
    }

    public func toggle(_ featureID: FeatureFlagID) {
        for feature in features {
            if feature.featureID == featureID {
                feature.toggle()
            }
        }
    }

    public func setupFeatures(with profile: Profile) {
        features.removeAll()

        let chronTabs = FlaggableFeature(withID: .chronologicalTabs, and: profile, enabledFor: [.developer])
        features.append(chronTabs)

        let inactiveTabs = FlaggableFeature(withID: .inactiveTabs, and: profile, enabledFor: [.beta, .developer])
        features.append(inactiveTabs)

        /// Use the Nimbus experimentation platform. If this is `true` then
        /// `Experiments.shared` provides access to Nimbus. If false, it is a dummy object.
        let nimbus = FlaggableFeature(withID: .nimbus, and: profile, enabledFor: [.release, .beta, .developer])
        features.append(nimbus)

        let recentlySaved = FlaggableFeature(withID: .recentlySaved, and: profile, enabledFor: [.beta, .developer])
        features.append(recentlySaved)

        let shakeToRestore = FlaggableFeature(withID: .shakeToRestore, and: profile, enabledFor: [.beta, .developer, .other])
        features.append(shakeToRestore)
    }
}
