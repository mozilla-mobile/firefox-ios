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
    case jumpBackInSyncedTab
    case pocket
    case pullToRefresh
    case recentlySaved
    case reportSiteIssue
    case searchHighlights
    case shakeToRestore
    case sponsoredPocket
    case sponsoredTiles
    case startAtHome
    case tabTrayGroups
    case topSites
    case wallpapers
}

/// This enum is a constraint for any feature flag options that have more than
/// just an ON or OFF setting. These option must also be added to `NimbusFeatureFlagID`
enum NimbusFeatureFlagWithCustomOptionsID {
    case startAtHome
    case searchBarPosition
}

struct NimbusFlaggableFeature: HasNimbusSearchBar {

    // MARK: - Variables
    private let profile: Profile
    private var featureID: NimbusFeatureFlagID

    private var featureKey: String? {
        typealias FlagKeys = PrefsKeys.FeatureFlags

        switch featureID {
        case .bottomSearchBar:
            return FlagKeys.SearchBarPosition
        case .historyHighlights:
            return FlagKeys.HistoryHighlightsSection
        case .historyGroups:
            return FlagKeys.HistoryGroups
        case .inactiveTabs:
            return FlagKeys.InactiveTabs
        case .jumpBackIn:
            return FlagKeys.JumpBackInSection
        case .pocket:
            return FlagKeys.ASPocketStories
        case .pullToRefresh:
            return FlagKeys.PullToRefresh
        case .recentlySaved:
            return FlagKeys.RecentlySavedSection
        case .sponsoredPocket:
            return FlagKeys.ASSponsoredPocketStories
        case .sponsoredTiles:
            return FlagKeys.SponsoredShortcuts
        case .startAtHome:
            return FlagKeys.StartAtHome
        case .tabTrayGroups:
            return FlagKeys.TabTrayGroups
        case .topSites:
            return FlagKeys.TopSiteSection
        case .wallpapers:
            return FlagKeys.CustomWallpaper

        // Cases where users do not have the option to manipulate a setting.
        case .reportSiteIssue,
                .shakeToRestore,
                .searchHighlights,
                .jumpBackInSyncedTab:
            return nil
        }
    }

    // MARK: - Initializers
    init(withID featureID: NimbusFeatureFlagID, and profile: Profile) {
        self.featureID = featureID
        self.profile = profile
    }

    // MARK: - Public methods
    public func isNimbusEnabled(using nimbusLayer: NimbusFeatureFlagLayer) -> Bool {
        let nimbusValue = nimbusLayer.checkNimbusConfigFor(featureID)

        switch featureID {
        case .pocket, .sponsoredPocket:
            return nimbusValue && Pocket.IslocaleSupported(Locale.current.identifier)
        default:
            return nimbusValue
        }
    }

    /// Returns whether or not the feature's state was changed by the user. If no
    /// preference exists, then the underlying Nimbus default is used. If a specific
    /// setting is required (ie. startAtHome, which has multiple types of setting),
    /// then we should be using `getUserPreference`
    public func isUserEnabled(using nimbusLayer: NimbusFeatureFlagLayer) -> Bool {
        if featureID == .startAtHome {
            guard let pref = getUserPreference(using: nimbusLayer) else {
                return isNimbusEnabled(using: nimbusLayer)
            }

            return pref == StartAtHomeSetting.afterFourHours.rawValue || pref == StartAtHomeSetting.always.rawValue
        }

        guard let optionsKey = featureKey,
              let option = profile.prefs.boolForKey(optionsKey)
        else { return isNimbusEnabled(using: nimbusLayer) }

        return option
    }

    /// Returns the feature option represented as a String. The `FeatureFlagManager` will
    /// convert it to the appropriate type.
    public func getUserPreference(using nimbusLayer: NimbusFeatureFlagLayer) -> String? {
        if let optionsKey = featureKey,
           let existingOption = profile.prefs.stringForKey(optionsKey) {
            return existingOption
        }

        switch featureID {
        case .startAtHome:
            return nimbusLayer.checkNimbusConfigForStartAtHome().rawValue

        case .bottomSearchBar:
            return nimbusSearchBar.getDefaultPosition().rawValue

        default:
            return nil
        }
    }

    /// Set a user preference that is of type on/off, to that respective state.
    ///
    /// Not all features are user togglable. If there exists no feature key - as defined
    /// in the `featureKey()` function - with which to write to UserDefaults, then the
    /// feature cannot be turned on/off.
    public func setUserPreference(to state: Bool) {
        guard let key = featureKey else { return }

        profile.prefs.setBool(state, forKey: key)
    }

    /// Allows to directly set the state of a feature using a string to allow for
    /// states beyond on and off.
    ///
    /// Not all features are user togglable. If there exists no feature key - as defined
    /// in the `featureKey()` function - with which to write to UserDefaults, then the
    /// feature cannot be turned on/off.
    public func setUserPreference(to option: String) {
        guard !option.isEmpty,
              let optionsKey = featureKey
        else { return }

        switch featureID {
        case .startAtHome:
            profile.prefs.setString(option, forKey: optionsKey)

        case .bottomSearchBar:
            profile.prefs.setString(option, forKey: optionsKey)

        default: break
        }
    }
}
