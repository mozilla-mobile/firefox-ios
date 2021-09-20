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
/// Please add new features alphabetically.
enum FeatureFlagName: String, CaseIterable {
    case chronologicalTabs
    case inactiveTabs
    case groupedTabs
    case jumpBackIn
    case nimbus
    case pullToRefresh
    case recentlySaved
    case shakeToRestore
    case startAtHome
}

/// Manages feature flags for the application.
///
/// To add a new feature flag, you must do four things:
///
/// 1. Add a name in the `FeatureFlagName` enum
/// 2. Add a new `FlaggableFeature` in the `FeatureFlagManager.setupFeatures` and add it
/// to the `features` dictionary using its key.
/// 3. Optional: If the feature is meant to be togglable, add a key for the feature
/// in the `PrefsKeys` struct, and then also add it to the `FlaggableFeature.featureKey`
/// function to allow the flag status to be changed.
/// 4. Add the `FeatureFlagsProtocol` protocol to the class you wish to use the feature
/// flag in, and access the required flag using `featureFlags.isFeatureActive`.
class FeatureFlagsManager {

    /// This Singleton should only be accessed directly in places where the
    /// `FeatureFlagsProtocol` is not available. Otherwise, access to the feature
    /// flags system should be done through the protocol, giving access to the
    /// `featureFlags` variable.
    static let shared = FeatureFlagsManager()

    private var profile: Profile!
    private var features: [FeatureFlagName: FlaggableFeature] = [:]

    /// Used as the main way to find out whether a feature is active or not.
    public func isFeatureActive(_ featureID: FeatureFlagName) -> Bool {
        guard let feature = features[featureID] else { return false }
        return feature.isActive
    }

    /// Main interface for accessing feature options.
    ///
    /// Function must have context when called: `let foo: Type = featureOption(.example)`
    /// Any feature with an option attached must be listed, and further converted into
    /// it's appropriate type in the switch statement.
    public func featureOption<T>(_ featureID: FeatureFlagName) -> T? {
        guard let feature = features[featureID],
              let featureOption = feature.featureOptions
        else { return nil }

        switch featureID {
        case .startAtHome: return StartAtHomeSetting(rawValue: featureOption) as? T
        default: return nil
        }
    }

    /// Retrieves a feature key for any specific feature, if it has one.
    public func featureKey(for featureID: FeatureFlagName) -> String? {
        return features[featureID]?.featureKey()
    }

    /// Main interface for setting a feature's state and options. Options are enums of
    /// `FlaggableFeatureOptions` type and also conform to Int.
    public func set<T:FlaggableFeatureOptions>(_ featureID: FeatureFlagName, to state: Bool, with option: T? = nil) {
        var optionAsInt: Int?

        switch featureID {
        case .startAtHome:
            if let option = option as? StartAtHomeSetting { optionAsInt = option.rawValue }
        default:
            optionAsInt = nil
        }

        features[featureID]?.setFeatureTo(state, with: optionAsInt)
    }

    /// Toggles the feature on/off, depending on its current status AND whether or not it is
    /// a feature that can be saved to disk. For more information, see `FlaggableFeature`
    /// Should only be used with a feature that has no options. Otherwise, the option will not
    /// not change, while the feature will be toggled.
    public func toggle(_ featureID: FeatureFlagName) {
        features[featureID]?.toggle()
    }

    /// Sets up features with default channel availablility. For ease of use, please add
    /// new features alphabetically.
    public func setupFeatures(with profile: Profile) {
        features.removeAll()

        let chronTabs = FlaggableFeature(withID: .chronologicalTabs, and: profile, enabledFor: [.developer], withDefaultFeatureOption: nil)
        features[.chronologicalTabs] = chronTabs

        let inactiveTabs = FlaggableFeature(withID: .inactiveTabs, and: profile, enabledFor: [.developer], withDefaultFeatureOption: nil)
        features[.inactiveTabs] = inactiveTabs

        let groupedTabs = FlaggableFeature(withID: .groupedTabs, and: profile, enabledFor: [.beta, .developer], withDefaultFeatureOption: nil)
        features[.groupedTabs] = groupedTabs

        let jumpBackIn = FlaggableFeature(withID: .jumpBackIn, and: profile, enabledFor: [.beta, .developer], withDefaultFeatureOption: nil)
        features[.jumpBackIn] = jumpBackIn

        /// Use the Nimbus experimentation platform. If this is `true` then
        /// `Experiments.shared` provides access to Nimbus. If false, it is a dummy object.
        let nimbus = FlaggableFeature(withID: .nimbus, and: profile, enabledFor: [.release, .beta, .developer], withDefaultFeatureOption: nil)
        features[.nimbus] = nimbus

        let pullToRefresh = FlaggableFeature(withID: .pullToRefresh, and: profile, enabledFor: [.release ,.beta, .developer])
        features[.pullToRefresh] = pullToRefresh

        let recentlySaved = FlaggableFeature(withID: .recentlySaved, and: profile, enabledFor: [.beta, .developer], withDefaultFeatureOption: nil)
        features[.recentlySaved] = recentlySaved

        let shakeToRestore = FlaggableFeature(withID: .shakeToRestore, and: profile, enabledFor: [.beta, .developer, .other], withDefaultFeatureOption: nil)
        features[.shakeToRestore] = shakeToRestore

        let startAtHome = FlaggableFeature(withID: .startAtHome, and: profile, enabledFor: [])
        features[.startAtHome] = startAtHome
    }
}
