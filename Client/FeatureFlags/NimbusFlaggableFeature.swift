// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import MozillaAppServices
import UIKit

/// An enum describing the featureID of all features found in Nimbus.
/// Please add new features alphabetically.
enum NimbusFeatureFlagID: String, CaseIterable {
    case bottomSearchBar
    case historyHighlights
    case historyGroups
    case inactiveTabs
    case jumpBackIn
    case librarySection
    case pocket
    case pullToRefresh
    case recentlySaved
    case reportSiteIssue
    case shakeToRestore
    case sponsoredTiles
    case startAtHome
    case tabTrayGroups
    case topSites
    case wallpapers
}

struct NimbusFlaggableFeature {

    // MARK: - Variables
    private let profile: Profile
    private var featureID: NimbusFeatureFlagID

    private var featureKey: String? {
        typealias FlagKeys = PrefsKeys.FeatureFlags

        switch featureID {
        case .bottomSearchBar:
            return nil
        case .historyHighlights:
            return FlagKeys.HistoryHighlightsSection
        case .historyGroups:
            return FlagKeys.HistoryGroups
        case .inactiveTabs:
            return FlagKeys.InactiveTabs
        case .jumpBackIn:
            return FlagKeys.JumpBackInSection
        case .librarySection:
            return nil
        case .pocket:
            return FlagKeys.ASPocketStories
        case .pullToRefresh:
            return FlagKeys.PullToRefresh
        case .recentlySaved:
            return FlagKeys.RecentlySavedSection
        case .shakeToRestore:
            return nil
        case .sponsoredTiles:
            return FlagKeys.SponsoredShortcuts
        case .startAtHome:
            return FlagKeys.StartAtHome
        case .reportSiteIssue:
            return nil
        case .tabTrayGroups:
            return FlagKeys.TabTrayGroups
        case .topSites:
            return FlagKeys.TopSiteSection
        case .wallpapers:
            return FlagKeys.CustomWallpaper
        }
    }

    public var featureOptionsKey: String? {
        guard let baseKey = featureKey else { return nil }
        return baseKey + "UserPreferences"
    }

    // MARK: - Initializers

    init(withID featureID: NimbusFeatureFlagID, and profile: Profile) {
        self.featureID = featureID
        self.profile = profile
    }

    // MARK: - Public methods
    public func isNimbusEnabled(using nimbusLayer: NimbusFeatureFlagLayer) -> Bool {
        return nimbusLayer.checkNimbusConfigFor(featureID)
    }

    /// Returns whether or not the feature is enabled. If a specific setting is required
    /// (ie. startAtHome which has multiple types of setting) then we should be using
    /// `getPreferenceFor`
    public func isUserEnabled(using nimbusLayer: NimbusFeatureFlagLayer) -> Bool {
        guard let optionsKey = featureOptionsKey,
              let existingOption = profile.prefs.stringForKey(optionsKey)
        else { return isNimbusEnabled(using: nimbusLayer) }

        switch featureID {
        case .startAtHome:
            return (existingOption == StartAtHomeSetting.afterFourHours.rawValue)
            || (existingOption == StartAtHomeSetting.always.rawValue)
        default:
            return existingOption == UserFeaturePreference.enabled.rawValue
        }

//        // Feature option defaults
//        switch featureID {
//        case .startAtHome, .wallpapers:
//            return true
//
//        // Nimbus default options
//        case .jumpBackIn, .pocket, .recentlySaved, .historyHighlights:
//            return checkNimbusHomepageFeatures(from: nimbusLayer) == UserFeaturePreference.enabled
//        case .inactiveTabs:
//            return checkNimbusTabTrayFeatures(from: nimbusLayer) == UserFeaturePreference.enabled
//        default:
//            return false
//        }
    }

    /// Returns the feature option represented as an Int. The `FeatureFlagManager` will
    /// convert it to the appropriate type.
    public func getUserPreference(using nimbusLayer: NimbusFeatureFlagLayer) -> String? {
        if let optionsKey = featureOptionsKey,
            let existingOption = profile.prefs.stringForKey(optionsKey) {
            return existingOption
        }

        // Feature option defaults
        switch featureID {
        case .startAtHome:
            return StartAtHomeSetting.afterFourHours.rawValue
        case .wallpapers, .topSites:
            // Features that are on by default
            return UserFeaturePreference.enabled.rawValue

        // Nimbus default options
        case .jumpBackIn, .pocket, .recentlySaved, .historyHighlights:
            return checkNimbusHomepageFeatures(from: nimbusLayer).rawValue
        case .inactiveTabs:
            return checkNimbusTabTrayFeatures(from: nimbusLayer).rawValue
        default:
            return nil
        }
    }

    /// Allows fine grain control over a feature, by allowing to directly set the state to ON
    /// or OFF, and also set the features option as an Int
    public func setUserPreferenceFor(_ option: String) {
        guard !option.isEmpty,
              let optionsKey = featureOptionsKey
        else { return }

        profile.prefs.setString(option, forKey: optionsKey)
    }

    /// Toggles a feature On or Off, and saves the status to UserDefaults.
    ///
    /// Not all features are user togglable. If there exists no feature key - as defined
    /// in the `featureKey()` function - with which to write to UserDefaults, then the
    /// feature cannot be turned on/off and its state can only be set when initialized,
    /// based on build channel. Furthermore, this controls build availability, and
    /// does not reflect user preferences.
    public func toggleBuildFeature(using nimbusLayer: NimbusFeatureFlagLayer) {
        guard let featureKey = featureKey else { return }
        let currentFeatureState = isUserEnabled(using: nimbusLayer)
        profile.prefs.setBool(!currentFeatureState, forKey: featureKey)
    }
}

// MARK: - Nimbus related methods
extension NimbusFlaggableFeature {
    private func checkNimbusTabTrayFeatures(
        from nimbusLayer: NimbusFeatureFlagLayer
    ) -> UserFeaturePreference {

        if nimbusLayer.checkNimbusConfigFor(featureID) {
            return UserFeaturePreference.enabled
        }

        return UserFeaturePreference.disabled
    }

    private func checkNimbusHomepageFeatures(
        from nimbusLayer: NimbusFeatureFlagLayer
    ) -> UserFeaturePreference {

        if nimbusLayer.checkNimbusConfigFor(featureID) {
            // For pocket's default value, we also need to check the locale being supported.
            // Here, we want to make sure the section is enabled && locale is supported before
            // we would return that pocket is enabled
            if featureID == .pocket && !Pocket.IslocaleSupported(Locale.current.identifier) {
                return UserFeaturePreference.disabled
            }
            return UserFeaturePreference.enabled
        }

        return UserFeaturePreference.disabled
    }
}
