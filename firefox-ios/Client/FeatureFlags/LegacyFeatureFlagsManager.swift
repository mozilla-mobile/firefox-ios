// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

// MARK: - Protocol
protocol FeatureFlaggable {}

extension FeatureFlaggable {
    var featureFlags: LegacyFeatureFlagsManager {
        return LegacyFeatureFlagsManager.shared
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

class LegacyFeatureFlagsManager: HasNimbusFeatureFlags {
    /// This Singleton should only be accessed directly in places where the
    /// `FeatureFlaggable` is not available. Otherwise, access to the feature
    /// flags system should be done through the protocol, giving access to the
    /// `featureFlags` variable.
    static let shared = LegacyFeatureFlagsManager()

    // MARK: - Variables
    private var profile: Profile?
    private var coreFeatures: [CoreFeatureFlagID: CoreFlaggableFeature] = [:]

    // MARK: - Public methods
    /// Used to find out whether a core feature is active or not.
    public func isCoreFeatureEnabled(_ featureID: CoreFeatureFlagID) -> Bool {
        guard let feature = coreFeatures[featureID] else { return false }
        return feature.isActiveForBuild()
    }

    /// Used as the main way to find out whether a feature is active or not, checking
    /// either just for the build, the build and user preferences, or just user
    /// preferences (supported by Nimbus defaults).
    public func isFeatureEnabled(_ featureID: NimbusFeatureFlagID,
                                 checking channelsToCheck: FlaggableFeatureCheckOptions
    ) -> Bool {
        guard let profile else {
            return false
        }

        let feature = NimbusFlaggableFeature(withID: featureID, and: profile)
        let nimbusSetting = getNimbusOrDebugSetting(with: feature)
        let userSetting = feature.isUserEnabled(using: nimbusFlags)

        switch channelsToCheck {
        case .buildOnly:
            return nimbusSetting
        case .buildAndUser:
            return nimbusSetting && userSetting
        case .userOnly:
            return userSetting
        }
    }

    /// Allows us to override nimbus feature flags for a specific build using the debug menu
    private func getNimbusOrDebugSetting(with feature: NimbusFlaggableFeature) -> Bool {
        #if MOZ_CHANNEL_BETA || MOZ_CHANNEL_FENNEC
        return feature.isDebugEnabled(using: nimbusFlags)
        #else
        return feature.isNimbusEnabled(using: nimbusFlags)
        #endif
    }

    /// Retrieves a custom state for any type of feature that has more than just a
    /// binary state. Further information on return types can be found in
    /// `FlaggableFeatureOptions`
    public func getCustomState<T>(for featureID: NimbusFeatureFlagWithCustomOptionsID) -> T? {
        guard let profile else {
            return nil
        }

        let feature = NimbusFlaggableFeature(withID: convertCustomIDToStandard(featureID),
                                             and: profile)
        guard let userSetting = feature.getUserPreference(using: nimbusFlags) else { return nil }

        switch featureID {
        case .searchBarPosition: return SearchBarPosition(rawValue: userSetting) as? T
        }
    }

    private func convertCustomIDToStandard(_ featureID: NimbusFeatureFlagWithCustomOptionsID) -> NimbusFeatureFlagID {
        switch featureID {
        case .searchBarPosition: return .bottomSearchBar
        }
    }

    /// Set different app build channels to a core feature
    public func set(feature featureID: CoreFeatureFlagID, toChannels desiredChannels: [AppBuildChannel]) {
        let desiredFeature = CoreFlaggableFeature(withID: featureID, enabledFor: desiredChannels)
        coreFeatures[featureID] = desiredFeature
    }

    /// Set a feature that has a binary state to on or off
    public func set(feature featureID: NimbusFeatureFlagID, to desiredState: Bool, isDebug: Bool = false) {
        guard let profile else {
            return
        }

        let feature = NimbusFlaggableFeature(withID: featureID, and: profile)
        #if MOZ_CHANNEL_BETA || MOZ_CHANNEL_FENNEC
        if isDebug {
            feature.setDebugPreference(to: desiredState)
        } else {
            feature.setUserPreference(to: desiredState)
        }
        #else
        feature.setUserPreference(to: desiredState)
        #endif
    }

    /// Set a feature that has a custom state to that custom state. More information
    /// on custom states can be found in `FlaggableFeatureOptions`
    public func set<T: FlaggableFeatureOptions>(
        feature featureID: NimbusFeatureFlagWithCustomOptionsID,
        to desiredState: T
    ) {
        guard let profile else {
            return
        }

        let feature = NimbusFlaggableFeature(withID: convertCustomIDToStandard(featureID),
                                             and: profile)
        switch featureID {
        case .searchBarPosition:
            if let option = desiredState as? SearchBarPosition {
                feature.setUserPreference(to: option.rawValue)
            }
        }
    }

    /// Sets up features with default channel availability. For ease of use, please add
    /// new features alphabetically. These features are only core features in the
    /// application. See the relevant documentation on `CoreFlaggableFeature` and
    /// `NimbusFlaggableFeature` for more explanation on the differences.
    ///
    /// This should ONLY be called when instantiating the feature flag system,
    /// and never again.
    public func initializeDeveloperFeatures(with profile: Profile) {
        self.profile = profile

        coreFeatures.removeAll()

        let adjustEnvironmentProd = CoreFlaggableFeature(withID: .adjustEnvironmentProd,
                                                         enabledFor: [.release, .beta])
        coreFeatures[.adjustEnvironmentProd] = adjustEnvironmentProd

        let useMockData = CoreFlaggableFeature(withID: .useMockData,
                                               enabledFor: [.developer])
        coreFeatures[.useMockData] = useMockData

        let useStagingContileAPI = CoreFlaggableFeature(withID: .useStagingContileAPI,
                                                        enabledFor: [.beta, .developer])
        let useStagingSponsoredPocketStoriesAPI = CoreFlaggableFeature(withID: .useStagingSponsoredPocketStoriesAPI,
                                                                       enabledFor: [.beta, .developer])

        let useStagingFakespotAPI = CoreFlaggableFeature(withID: .useStagingFakespotAPI,
                                                         enabledFor: [])

        coreFeatures[.useStagingContileAPI] = useStagingContileAPI
        coreFeatures[.useStagingSponsoredPocketStoriesAPI] = useStagingSponsoredPocketStoriesAPI
        coreFeatures[.useStagingFakespotAPI] = useStagingFakespotAPI
    }
}
