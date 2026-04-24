// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit

struct NimbusFlaggableFeature {
    // MARK: - Variables
    private let profile: Profile
    private var featureID: FeatureFlagID

    private var featureKey: String? {
        typealias FlagKeys = PrefsKeys.FeatureFlags

        switch featureID {
        case .aiKillSwitch:
            return PrefsKeys.Settings.aiKillSwitchFeature
        case .firefoxSuggestFeature:
            return FlagKeys.FirefoxSuggest
        case .homepageBookmarksSectionDefault:
            return PrefsKeys.HomepageSettings.BookmarksSection
        case .homepageJumpBackinSectionDefault:
            return PrefsKeys.HomepageSettings.JumpBackInSection
        case .hntSponsoredShortcuts:
            return FlagKeys.SponsoredShortcuts
        case .sentFromFirefox:
            return FlagKeys.SentFromFirefox
        case .startAtHome:
            return FlagKeys.StartAtHome
        // Cases where users do not have the option to manipulate a setting. Please add in alphabetical order.
        case .appearanceMenu,
                .appIconSelection,
                .addressAutofillEdit,
                .addressBarMenu,
                .adsClient,
                .bookmarksSearchFeature,
                .deeplinkOptimizationRefactor,
                .downloadLiveActivities,
                .firefoxJpGuideDefaultSite,
                .homepageSearchBar,
                .homepageStoryCategories,
                .improvedAppStoreReviewTriggerFeature,
                .shouldUseBrandRefreshConfiguration,
                .shouldUseJapanConfiguration,
                .microsurvey,
                .modernOnboardingUI,
                .nativeErrorPage,
                .needsReloadRefactor,
                .noInternetConnectionErrorPage,
                .badCertDomainErrorPage,
                .recentSearches,
                .reportSiteIssue,
                .sentFromFirefoxTreatmentA,
                .snapkitRemovalRefactor,
                .splashScreen,
                .hostedSummarizer,
                .hostedSummarizerToolbarEntrypoint,
                .hostedSummarizerShakeGesture,
                .httpsUpgrade,
                .quickAnswers,
                .relayIntegration,
                .summarizerAppAttestAuth,
                .summarizerLanguageExpansion,
                .summarizerPermissiveGuardrails,
                .tabScrollRefactorFeature,
                .tabTrayiPadUIExperiments,
                .tabTrayUIExperiments,
                .tabTrayTranslucency,
                .toolbarUpdateHint,
                .tosFeature,
                .touFeature,
                .trackingProtectionRefactor,
                .translation,
                .translationLanguagePicker,
                .trendingSearches,
                .unifiedSearch,
                .videoIntroOnboarding,
                .worldCupWidget:
            return nil
        }
    }

    // MARK: - Initializers
    init(withID featureID: FeatureFlagID, and profile: Profile) {
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
        case .splashScreen:
            return SearchBarPosition.bottom.rawValue
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
        guard !option.isEmpty else { return }
        // TODO: to be removed with 15192
        // no-op for now
    }
}
