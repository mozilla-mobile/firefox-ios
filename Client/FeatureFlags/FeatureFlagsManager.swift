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

class FeatureFlagsManager: HasNimbusFeatureFlags {

    /// This Singleton should only be accessed directly in places where the
    /// `FeatureFlaggable` is not available. Otherwise, access to the feature
    /// flags system should be done through the protocol, giving access to the
    /// `featureFlags` variable.
    static let shared = FeatureFlagsManager()

    // MARK: - Variables
    private var profile: Profile!
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
        let feature = NimbusFlaggableFeature(withID: featureID, and: profile)

        let nimbusSetting = feature.isNimbusEnabled(using: nimbusFlags)
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

    /// Retrieves a custom state for any type of feature that has more than just a
    /// binary state. Further information on return types can be found in
    /// `FlaggableFeatureOptions`
    public func getCustomState<T>(for featureID: NimbusFeatureFlagWithCustomOptionsID) -> T? {

        let feature = NimbusFlaggableFeature(withID: convertCustomIDToStandard(featureID),
                                             and: profile)
        guard let userSetting = feature.getUserPreference(using: nimbusFlags) else { return nil }

        switch featureID {
        case .startAtHome: return StartAtHomeSetting(rawValue: userSetting) as? T
        case .searchBarPosition: return SearchBarPosition(rawValue: userSetting) as? T
        }
    }

    private func convertCustomIDToStandard(_ featureID: NimbusFeatureFlagWithCustomOptionsID) -> NimbusFeatureFlagID {

        switch featureID {
        case .startAtHome: return .startAtHome
        case .searchBarPosition: return .bottomSearchBar
        }
    }

    /// Set a feature that has a binary state to on or off
    public func set(feature featureID: NimbusFeatureFlagID, to desiredState: Bool) {
        // Do nothing if this is a non-binary feature
        let nonbinaryStateFeatures: [NimbusFeatureFlagID] = [.startAtHome]
        if nonbinaryStateFeatures.contains(featureID) { return }

        let feature = NimbusFlaggableFeature(withID: featureID, and: profile)
        feature.setUserPreference(to: desiredState)
    }

    /// Set a feature that has a custom state to that custom state. More information
    /// on custom states can be found in `FlaggableFeatureOptions`
    public func set<T: FlaggableFeatureOptions>(
        feature featureID: NimbusFeatureFlagWithCustomOptionsID,
        to desiredState: T
    ) {

        let feature = NimbusFlaggableFeature(withID: convertCustomIDToStandard(featureID),
                                             and: profile)
        switch featureID {
        case .startAtHome:
            if let option = desiredState as? StartAtHomeSetting {
                feature.setUserPreference(to: option.rawValue)
            }

        case .searchBarPosition:
            if let option = desiredState as? SearchBarPosition {
                feature.setUserPreference(to: option.rawValue)
            }
        }
    }

    /// Sets up features with default channel availablility. For ease of use, please add
    /// new features alphabetically. These features are only core features in the
    /// application. See the relevant documentation on `CoreFlaggableFeature` and
    /// `NimbusFlaggableFeature` for more explanation on the differences.
    ///
    /// This should ONLY be called when instatiating the feature flag system,
    /// and never again.
    public func initializeDeveloperFeatures(with profile: Profile) {
        self.profile = profile

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

        let useStagingContileAPI = CoreFlaggableFeature(withID: .useStagingContileAPI,
                                                        enabledFor: [.beta, .developer])
        coreFeatures[.useStagingContileAPI] = useStagingContileAPI
    }
}
