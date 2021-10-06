/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

struct FlaggableFeature {

    // MARK: - Variables
    private let profile: Profile
    private let buildChannels: [AppBuildChannel]

    var featureID: FeatureFlagName

    /// Returns whether or not the feature is active for the build.
    ///
    /// This variable returns a `Bool` based on a priority queue.
    ///
    /// 1. It will check whether or not there exists a value for
    /// the feature written on disk. Users generally set these states
    /// from the debug menu and, if they have set something manually,
    /// we will respect that and return the respective value.
    ///
    /// 2. If there is no setting written to the disk, then every feature
    /// has an underlying default state for each build channel (Release,
    /// Beta, Developer) and that value will be returned.
    var isActiveForBuild: Bool {
        if let key = featureKey(), let existingPref = profile.prefs.boolForKey(key) {
            return existingPref

        } else {
            #if MOZ_CHANNEL_RELEASE
            return buildChannels.contains(.release)
            #elseif MOZ_CHANNEL_BETA
            return buildChannels.contains(.beta)
            #elseif MOZ_CHANNEL_FENNEC
            return buildChannels.contains(.developer)
            #else
            return buildChannels.contains(.other)
            #endif
        }
    }

    /// Returns the feature option represented as an Int. The `FeatureFlagManager` will
    /// convert it to the appropriate type.
    var userPreferenceSetTo: String? {
        if let optionsKey = featureOptionsKey, let existingOption = profile.prefs.stringForKey(optionsKey) {
            return existingOption
        }

        // Feature option defaults
        switch featureID {
        case .startAtHome:
            return StartAtHomeSetting.afterFourHours.rawValue
        case .jumpBackIn, .libraryShortcuts, .pocket, .recentlySaved, .topSites:
            return checkNimbusHomepageFeatures()?.rawValue ?? UserFeaturePreference.disabled.rawValue
        default:
            return UserFeaturePreference.disabled.rawValue
        }
    }

    private func checkNimbusHomepageFeatures() -> UserFeaturePreference? {
        var homePageExperiments = Experiments.shared.withVariables(featureId: .homescreen,
                                                                   sendExposureEvent: false) {
            Homescreen(variables: $0)
        }

        var sectionID: Homescreen.SectionId? = nil

        switch featureID {
        case .jumpBackIn:
            sectionID = .jumpBackIn
        case .libraryShortcuts:
            sectionID = .libraryShortcuts
        case .recentlySaved:
            sectionID = .recentlySaved
        case .pocket:
            sectionID = .pocket
        case .topSites:
            sectionID = .topSites
        default: break
        }

        if let sectionID = sectionID,
           let homePageFeature = homePageExperiments.sectionsEnabled[sectionID] {
            
            switch homePageFeature {
            case true:
                return UserFeaturePreference.enabled
            case false:
                return UserFeaturePreference.disabled
            }
        }

        return nil
    }

    private var featureOptionsKey: String? {
        guard let baseKey = featureKey() else { return nil }
        return baseKey + "UserPreferences"
    }

    // MARK: - Initializers
    init(withID featureID: FeatureFlagName, and profile: Profile, enabledFor channels: [AppBuildChannel]) {
        self.featureID = featureID
        self.profile = profile
        self.buildChannels = channels
    }

    // MARK: - Functions
    
    /// Allows fine grain control over a feature, by allowing to directly set the state to ON
    /// or OFF, and also set the features option as an Int
    public func setUserPrefsForFeatureTo(_ option: String) {
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
    public func toggleBuildFeature() {
        guard let featureKey = featureKey() else { return }
        profile.prefs.setBool(!isActiveForBuild, forKey: featureKey)
    }

    public func featureKey() -> String? {
        switch featureID {
        case .chronologicalTabs:
            return PrefsKeys.ChronTabsPrefKey
        case .inactiveTabs:
            return PrefsKeys.KeyEnableInactiveTabs
        case .groupedTabs:
            return PrefsKeys.KeyEnableGroupedTabs
        case .jumpBackIn:
            return PrefsKeys.JumpBackInSectionEnabled
        case .libraryShortcuts:
            return PrefsKeys.LibraryShortcutsEnabled
        case .pocket:
            return PrefsKeys.ASPocketStoriesVisible
        case .pullToRefresh:
            return PrefsKeys.PullToRefresh
        case .recentlySaved:
            return PrefsKeys.RecentlySavedSectionEnabled
        case .startAtHome:
            return PrefsKeys.StartAtHome
        case .topSites:
            return PrefsKeys.TopSitesSectionEnabled
        default: return nil
        }
    }
}
