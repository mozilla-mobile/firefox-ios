// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared

// MARK: - Protocol
protocol FeatureFlagsProtocol { }

extension FeatureFlagsProtocol {
    var featureFlags: FeatureFlagsManager {
        return FeatureFlagsManager.shared
    }
}

// MARK: - FeatureFlagName
/// An enum describing the featureID of all features, historical, avalable, or in development.
/// Please add new features alphabetically.
enum FeatureFlagName: String, CaseIterable {
    case chronologicalTabs
    case customWallpaper
    case inactiveTabs
    case groupedTabs
    case historyHighlights
    case jumpBackIn
    case nimbus
    case pocket
    case pullToRefresh
    case recentlySaved
    case shakeToRestore
    case startAtHome
    case reportSiteIssue
}

/// Manages feature flags for the application.
///
/// To add a new feature flag, you must do four things:
///
/// 1. Add a name in the `FeatureFlagName` enum
/// 2. Add a new `FlaggableFeature` in the ``FeatureFlagManager.initializeFeatures`` and add it
/// to the `features` dictionary using its key.
/// 3. Optional: If the feature is meant to be togglable, add a key for the feature
/// in the `PrefsKeys` struct, and then also add it to the `FlaggableFeature.featureKey`
/// function to allow the flag status to be changed.
/// 4. Add the `FeatureFlagsProtocol` protocol to the class you wish to use the feature
/// flag in, and access the required flag using `featureFlags.isFeatureActiveForBuild`.
class FeatureFlagsManager {

    /// This Singleton should only be accessed directly in places where the
    /// `FeatureFlagsProtocol` is not available. Otherwise, access to the feature
    /// flags system should be done through the protocol, giving access to the
    /// `featureFlags` variable.
    static let shared = FeatureFlagsManager()

    // MARK: - Variables

    private var profile: Profile!
    private var features: [FeatureFlagName: FlaggableFeature] = [:]

    // MARK: - Public methods

    /// Used as the main way to find out whether a feature is active or not,
    /// specifically for the build.
    public func isFeatureActiveForBuild(_ featureID: FeatureFlagName) -> Bool {
        guard let feature = features[featureID] else { return false }
        return feature.isActiveForBuild()
    }

    public func toggleBuildFeature(_ featureID: FeatureFlagName) {
        features[featureID]?.toggleBuildFeature()
    }

    /// Retrieves a feature key for any specific feature, if it has one.
    public func featureKey(for featureID: FeatureFlagName) -> String? {
        return features[featureID]?.featureOptionsKey
    }

    /// Main interface for accessing feature options.
    ///
    /// Function must have context when called: `let foo: Type = featureOption(.example)`
    /// Any feature with an option attached must be listed, and further converted into
    /// it's appropriate type in the switch statement.
    public func userPreferenceFor<T>(_ featureID: FeatureFlagName) -> T? {
        guard let feature = features[featureID],
              let userSetting = feature.getUserPreference()
        else { return nil }

        switch featureID {
        case .startAtHome: return StartAtHomeSetting(rawValue: userSetting) as? T
        default: return UserFeaturePreference(rawValue: userSetting) as? T
        }
    }

    /// Main interface for setting a feature's state and options. Options are enums of
    /// `FlaggableFeatureOptions` type and also conform to Int.
    public func setUserPreferenceFor<T:FlaggableFeatureOptions>(_ featureID: FeatureFlagName, to option: T) {

        switch featureID {
        case .startAtHome:
            if let option = option as? StartAtHomeSetting {
                features[featureID]?.setUserPreferenceFor(option.rawValue)
            }
        default:
            if let option = option as? UserFeaturePreference {
                features[featureID]?.setUserPreferenceFor(option.rawValue)
            }
        }
    }

    /// Sets up features with default channel availablility. For ease of use, please add
    /// new features alphabetically.
    ///
    /// This should ONLY be called when instatiating the feature flag system,
    /// and never again.
    public func initializeFeatures(with profile: Profile) {
        features.removeAll()

        let chronTabs = FlaggableFeature(withID: .chronologicalTabs,
                                         and: profile,
                                         enabledFor: [])
        features[.chronologicalTabs] = chronTabs

        let customWallpaper = FlaggableFeature(withID: .customWallpaper,
                                               and: profile,
                                               enabledFor: [.developer])
        features[.customWallpaper] = customWallpaper

        let inactiveTabs = FlaggableFeature(withID: .inactiveTabs,
                                            and: profile,
                                            enabledFor: [.developer])
        features[.inactiveTabs] = inactiveTabs

        let groupedTabs = FlaggableFeature(withID: .groupedTabs,
                                           and: profile,
                                           enabledFor: [.developer])
        features[.groupedTabs] = groupedTabs

        let jumpBackIn = FlaggableFeature(withID: .jumpBackIn,
                                          and: profile,
                                          enabledFor: [.release, .beta, .developer])
        features[.jumpBackIn] = jumpBackIn

        /// Use the Nimbus experimentation platform. If this is `true` then
        /// `Experiments.shared` provides access to Nimbus. If false, it is a dummy object.
        let nimbus = FlaggableFeature(withID: .nimbus,
                                      and: profile,
                                      enabledFor: [.release, .beta, .developer])
        features[.nimbus] = nimbus

        let pocket = FlaggableFeature(withID: .pocket,
                                      and: profile,
                                      enabledFor: [.release, .beta, .developer])
        features[.pocket] = pocket


        let pullToRefresh = FlaggableFeature(withID: .pullToRefresh,
                                             and: profile,
                                             enabledFor: [.release ,.beta, .developer])
        features[.pullToRefresh] = pullToRefresh

        let recentlySaved = FlaggableFeature(withID: .recentlySaved,
                                             and: profile,
                                             enabledFor: [.release, .beta, .developer])
        features[.recentlySaved] = recentlySaved

        let historyHighlights = FlaggableFeature(withID: .historyHighlights,
                                                 and: profile,
                                                 enabledFor: [.developer])
        features[.historyHighlights] = historyHighlights

        let shakeToRestore = FlaggableFeature(withID: .shakeToRestore,
                                              and: profile,
                                              enabledFor: [.beta, .developer, .other])
        features[.shakeToRestore] = shakeToRestore

        let startAtHome = FlaggableFeature(withID: .startAtHome,
                                           and: profile,
                                           enabledFor: [.release, .beta, .developer])
        features[.startAtHome] = startAtHome
        
        let reportSiteIssue = FlaggableFeature(withID: .reportSiteIssue,
                                               and: profile,
                                               enabledFor: [.beta, .developer])
        
        features[.reportSiteIssue] = reportSiteIssue
    }
}
