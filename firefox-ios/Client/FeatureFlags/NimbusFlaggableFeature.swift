// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit

/// An enum describing the featureID of all features found in Nimbus.
/// Please add new features alphabetically.
enum NimbusFeatureFlagID: String, CaseIterable {
    case addressAutofillEdit
    case appearanceMenu
    case addressBarMenu
    case bookmarksRefactor
    case bottomSearchBar
    case cleanupHistoryReenabled
    case deeplinkOptimizationRefactor
    case feltPrivacySimplifiedUI
    case feltPrivacyFeltDeletion
    case firefoxSuggestFeature
    case homepageRebuild
    case inactiveTabs
    case menuRefactor
    case menuRefactorHint
    case microsurvey
    case loginsVerificationEnabled
    case nativeErrorPage
    case noInternetConnectionErrorPage
    case pdfRefactor
    case downloadLiveActivities
    case ratingPromptFeature
    case reportSiteIssue
    case searchEngineConsolidation
    case sentFromFirefox
    case sentFromFirefoxTreatmentA
    case splashScreen
    case startAtHome
    case unifiedAds
    case unifiedSearch
    case tabAnimation
    case tabTrayUIExperiments
    case toolbarRefactor
    case toolbarOneTapNewTab
    case toolbarSwipingTabs
    case toolbarNavigationHint
    case tosFeature
    case trackingProtectionRefactor
    case revertUnsafeContinuationsRefactor
    case useRustKeychain
    case updatedPasswordManager

    // Add flags here if you want to toggle them in the `FeatureFlagsDebugViewController`. Add in alphabetical order.
    var debugKey: String? {
        switch self {
        case    .appearanceMenu,
                .addressBarMenu,
                .bookmarksRefactor,
                .deeplinkOptimizationRefactor,
                .homepageRebuild,
                .feltPrivacyFeltDeletion,
                .feltPrivacySimplifiedUI,
                .menuRefactor,
                .microsurvey,
                .loginsVerificationEnabled,
                .nativeErrorPage,
                .noInternetConnectionErrorPage,
                .sentFromFirefox,
                .tabAnimation,
                .tabTrayUIExperiments,
                .toolbarRefactor,
                .trackingProtectionRefactor,
                .pdfRefactor,
                .downloadLiveActivities,
                .unifiedAds,
                .unifiedSearch,
                .useRustKeychain,
                .updatedPasswordManager:
            return rawValue + PrefsKeys.FeatureFlags.DebugSuffixKey
        default:
            return nil
        }
    }
}

/// This enum is a constraint for any feature flag options that have more than
/// just an ON or OFF setting. These option must also be added to `NimbusFeatureFlagID`
enum NimbusFeatureFlagWithCustomOptionsID {
    case searchBarPosition
    case startAtHome
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
        case .firefoxSuggestFeature:
            return FlagKeys.FirefoxSuggest
        case .inactiveTabs:
            return FlagKeys.InactiveTabs
        case .sentFromFirefox:
            return FlagKeys.SentFromFirefox
        case .startAtHome:
            return FlagKeys.StartAtHome
        // Cases where users do not have the option to manipulate a setting.
        case .appearanceMenu,
                .addressBarMenu,
                .bookmarksRefactor,
                .addressAutofillEdit,
                .cleanupHistoryReenabled,
                .deeplinkOptimizationRefactor,
                .homepageRebuild,
                .microsurvey,
                .menuRefactor,
                .menuRefactorHint,
                .loginsVerificationEnabled,
                .nativeErrorPage,
                .noInternetConnectionErrorPage,
                .pdfRefactor,
                .downloadLiveActivities,
                .ratingPromptFeature,
                .reportSiteIssue,
                .feltPrivacySimplifiedUI,
                .feltPrivacyFeltDeletion,
                .searchEngineConsolidation,
                .sentFromFirefoxTreatmentA,
                .splashScreen,
                .unifiedAds,
                .unifiedSearch,
                .tabAnimation,
                .tabTrayUIExperiments,
                .toolbarRefactor,
                .toolbarOneTapNewTab,
                .toolbarSwipingTabs,
                .toolbarNavigationHint,
                .tosFeature,
                .trackingProtectionRefactor,
                .revertUnsafeContinuationsRefactor,
                .useRustKeychain,
                .updatedPasswordManager:
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
        return nimbusLayer.checkNimbusConfigFor(featureID)
    }

    /// Returns whether or not the feature's state was changed by the user. If no
    /// preference exists, then the underlying Nimbus default is used. If a specific
    /// setting is required (ie. startAtHome, which has multiple types of setting),
    /// then we should be using `getUserPreference`
    public func isUserEnabled(using nimbusLayer: NimbusFeatureFlagLayer) -> Bool {
        guard let optionsKey = featureKey,
              let option = profile.prefs.boolForKey(optionsKey)
        else {
            // In unit tests only, we provide a way to return an override value to simulate a user's preference for a feature
            if AppConstants.isRunningUnitTest,
               UserDefaults.standard.valueExists(forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride) {
                return UserDefaults.standard.bool(forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
            }

            return isNimbusEnabled(using: nimbusLayer)
        }

        return option
    }

    /// Returns whether or not the feature's state was changed by using our Feature Flags debug setting.
    /// If no preference exists, then the underlying Nimbus default is used. If a specific
    /// setting is used, then we should check for the debug key used.
    public func isDebugEnabled(using nimbusLayer: NimbusFeatureFlagLayer) -> Bool {
        guard let optionsKey = featureID.debugKey,
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
        case .bottomSearchBar:
            return nimbusSearchBar.getDefaultPosition().rawValue
        case .splashScreen:
            return nimbusSearchBar.getDefaultPosition().rawValue
        case .startAtHome:
            return FxNimbus.shared.features.startAtHomeFeature.value().setting.rawValue
        default: return nil
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

    public func setDebugPreference(to state: Bool) {
        guard let key = featureID.debugKey else { return }

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
        case .bottomSearchBar:
            profile.prefs.setString(option, forKey: optionsKey)

        default: break
        }
    }
}
