// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared

// MARK: - Protocol
protocol FeatureFlaggable { }

extension FeatureFlaggable {
    var featureFlags: FeatureFlagsManager {
        return FeatureFlagsManager.shared
    }
}

/// An enum representing the different types of checks we need to use for features.
/// All Nimbus default values are stored in the `nimbus.fml.yaml`
enum FlaggableFeatureCheckOptions {
    /// Checking only Nimbus value for the build.
    case buildOnly
    /// Checking Nimbus value first, then whether or not the user has set a preference,
    /// and, if no preference is set, the default Nimbus value.
    case buildAndUser
    /// Checking only the user preference. If no user preference exists,
    /// then nimbus defaults are used.
    case userOnly
}

class FeatureFlagsManager: NimbusManageable {

    /// This Singleton should only be accessed directly in places where the
    /// `FeatureFlagsProtocol` is not available. Otherwise, access to the feature
    /// flags system should be done through the protocol, giving access to the
    /// `featureFlags` variable.
    static let shared = FeatureFlagsManager()

    // MARK: - Variables
    private var profile: Profile!
    private var coreFeatures: [CoreFeatureFlagID: CoreFlaggableFeature] = [:]

    // MARK: - Public methods

    /// Used as the main way to find out whether a core feature is active or not.
    public func isCoreFeatureEnabled(_ featureID: CoreFeatureFlagID) -> Bool {
        guard let feature = coreFeatures[featureID] else { return false }
        return feature.isActiveForBuild()
    }

    /// Used as the main way to find out whether a feature is active or not,
    /// specifically for the build.
    public func isFeatureEnabled(_ featureID: NimbusFeatureFlagID,
                                 checking channelsToCheck: FlaggableFeatureCheckOptions
    ) -> Bool {
        let feature = NimbusFlaggableFeature(withID: featureID, and: profile)

        let nimbusSetting = feature.isNimbusEnabled(using: nimbusManager.featureFlagLayer)
        let userSetting = feature.isUserEnabled(using: nimbusManager.featureFlagLayer)

        switch channelsToCheck {
        case .buildOnly:
            return nimbusSetting
        case .buildAndUser:
            return nimbusSetting && userSetting
        case .userOnly:
            return userSetting
        }
    }

//    public func userPreferenceFor<T>(_ featureID: NimbusFeatureFlagID) -> T? {
//        let feature = NimbusFlaggableFeature(withID: featureID, and: profile)
//        guard let userSetting = feature.getUserPreference(using: nimbusManager.featureFlagLayer) else { return nil }
//
//        switch featureID {
//        case .startAtHome: return StartAtHomeSetting(rawValue: userSetting) as? T
//        default: return nil
//        }
//    }

    public func toggleBuildFeature(_ featureID: NimbusFeatureFlagID) {
        let feature = NimbusFlaggableFeature(withID: featureID, and: profile)
        feature.toggleBuildFeature(using: nimbusManager.featureFlagLayer)
    }

//    /// Retrieves a feature key for any specific feature, if it has one.
//    public func featureKey(for featureID: NimbusFeatureFlagID) -> String? {
////        return features[featureID]?.featureOptionsKey
//    }

    /// Main interface for accessing feature options.
    ///
    /// Function must have context when called: `let foo: Type = featureOption(.example)`
    /// Any feature with an option attached must be listed, and further converted into
    /// it's appropriate type in the switch statement.
//    public func userPreferenceFor<T>(_ featureID: NimbusFeatureFlagID) -> T? {
//        guard let feature = features[featureID],
//              let userSetting = feature.getUserPreference(using: nimbusLayer)
//        else { return nil }
//
//        switch featureID {
//        case .startAtHome: return StartAtHomeSetting(rawValue: userSetting) as? T
//        default: return UserFeaturePreference(rawValue: userSetting) as? T
//        }
//    }
//
//    /// Main interface for setting a feature's state and options. Options are enums of
//    /// `FlaggableFeatureOptions` type and also conform to Int.
//    public func setUserPreferenceFor<T: FlaggableFeatureOptions>(_ featureID: NimbusFeatureFlagID, to option: T) {
//
//        switch featureID {
//        case .startAtHome:
//            if let option = option as? StartAtHomeSetting {
////                features[featureID]?.setUserPreferenceFor(option.rawValue)
//            }
//        default:
//            if let option = option as? UserFeaturePreference {
////                features[featureID]?.setUserPreferenceFor(option.rawValue)
//            }
//        }
//    }
//
    /// Sets up features with default channel availablility. For ease of use, please add
    /// new features alphabetically.
    ///
    /// This should ONLY be called when instatiating the feature flag system,
    /// and never again.
    public func initializeDeveloperFeatures(with profile: Profile) {
        coreFeatures.removeAll()

        let adjustEnvironmentProd = CoreFlaggableFeature(withID: .adjustEnvironmentProd,
                                                         enabledFor: [.release, .beta])
        coreFeatures[.adjustEnvironmentProd] = adjustEnvironmentProd

        /// Use the Nimbus experimentation platform. If this is `true` then
        /// `FxNimbus.shared` provides access to Nimbus. If false, it is a dummy object.
        let nimbus = CoreFlaggableFeature(withID: .nimbus,
                                          enabledFor: [.release, .beta, .developer])
        coreFeatures[.nimbus] = nimbus

        let useMockData = CoreFlaggableFeature(withID: .useMockData,
                                               enabledFor: [.developer])
        coreFeatures[.useMockData] = useMockData
    }

    // ROUX
//        let bottomSearchBar = FlaggableFeature(withID: .bottomSearchBar,
//                                               and: profile,
//                                               enabledFor: [.release, .beta, .developer])
//        features[.bottomSearchBar] = bottomSearchBar
//
//        let historyHighlights = FlaggableFeature(withID: .historyHighlights,
//                                                 and: profile,
//                                                 enabledFor: [.release, .beta, .developer])
//        features[.historyHighlights] = historyHighlights
//
//        let historyGroups = FlaggableFeature(withID: .historyGroups,
//                                             and: profile,
//                                             enabledFor: [.developer, .beta])
//        features[.historyGroups] = historyGroups
//
//        let inactiveTabs = FlaggableFeature(withID: .inactiveTabs,
//                                            and: profile,
//                                            enabledFor: [.developer, .beta, .release])
//        features[.inactiveTabs] = inactiveTabs
//
//        let jumpBackIn = FlaggableFeature(withID: .jumpBackIn,
//                                          and: profile,
//                                          enabledFor: [.release, .beta, .developer])
//        features[.jumpBackIn] = jumpBackIn
//
//        let librarySection = FlaggableFeature(withID: .librarySection,
//                                              and: profile,
//                                              enabledFor: [.release, .beta, .developer])
//        features[.librarySection] = librarySection
//
//        let pocket = FlaggableFeature(withID: .pocket,
//                                      and: profile,
//                                      enabledFor: [.release, .beta, .developer])
//        features[.pocket] = pocket
//
//        let pullToRefresh = FlaggableFeature(withID: .pullToRefresh,
//                                             and: profile,
//                                             enabledFor: [.release, .beta, .developer])
//        features[.pullToRefresh] = pullToRefresh
//
//        let recentlySaved = FlaggableFeature(withID: .recentlySaved,
//                                             and: profile,
//                                             enabledFor: [.release, .beta, .developer])
//        features[.recentlySaved] = recentlySaved
//
//        let reportSiteIssue = FlaggableFeature(withID: .reportSiteIssue,
//                                               and: profile,
//                                               enabledFor: [.beta, .developer])
//
//        features[.reportSiteIssue] = reportSiteIssue
//
//        let shakeToRestore = FlaggableFeature(withID: .shakeToRestore,
//                                              and: profile,
//                                              enabledFor: [.beta, .developer, .other])
//        features[.shakeToRestore] = shakeToRestore
//
//        let sponsoredTiles = FlaggableFeature(withID: .sponsoredTiles,
//                                              and: profile,
//                                              enabledFor: [.developer])
//        features[.sponsoredTiles] = sponsoredTiles
//
//        let startAtHome = FlaggableFeature(withID: .startAtHome,
//                                           and: profile,
//                                           enabledFor: [.release, .beta, .developer])
//        features[.startAtHome] = startAtHome
//
//        let tabTrayGroups = FlaggableFeature(withID: .tabTrayGroups,
//                                             and: profile,
//                                             enabledFor: [.developer])
//        features[.tabTrayGroups] = tabTrayGroups
//
//        let topsites = FlaggableFeature(withID: .topSites,
//                                        and: profile,
//                                        enabledFor: [.release, .beta, .developer])
//        features[.topSites] = topsites
//
//        let wallpapers = FlaggableFeature(withID: .wallpapers,
//                                          and: profile,
//                                          enabledFor: [.release, .beta, .developer])
//        features[.wallpapers] = wallpapers
}
