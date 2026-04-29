// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

/// An enum describing the featureID of all features found in Nimbus.
/// Please add new features alphabetically.
enum FeatureFlagID: String, CaseIterable {
    case addressAutofillEdit
    case addressBarMenu
    case adsClient
    case aiKillSwitch
    case appearanceMenu
    case appIconSelection
    case badCertDomainErrorPage
    case bookmarksSearchFeature
    case deeplinkOptimizationRefactor
    case downloadLiveActivities
    case firefoxJpGuideDefaultSite
    case firefoxSuggestFeature
    case hntSponsoredShortcuts
    case homepageBookmarksSectionDefault
    case homepageJumpBackinSectionDefault
    case homepageSearchBar
    case homepageStoryCategories
    case hostedSummarizer
    case hostedSummarizerShakeGesture
    case hostedSummarizerToolbarEntrypoint
    case httpsUpgrade
    case improvedAppStoreReviewTriggerFeature
    case microsurvey
    case modernOnboardingUI
    case nativeErrorPage
    case needsReloadRefactor
    case noInternetConnectionErrorPage
    case quickAnswers
    case recentSearches
    case relayIntegration
    case reportSiteIssue
    case sentFromFirefox
    case sentFromFirefoxTreatmentA
    case shouldUseBrandRefreshConfiguration
    case shouldUseJapanConfiguration
    case snapkitRemovalRefactor
    case splashScreen
    case startAtHome
    case summarizerAppAttestAuth
    case summarizerLanguageExpansion
    case summarizerPermissiveGuardrails
    case tabScrollRefactorFeature
    case tabTrayiPadUIExperiments
    case tabTrayTranslucency
    case tabTrayUIExperiments
    case toolbarUpdateHint
    case tosFeature
    case touFeature
    case trackingProtectionRefactor
    case translation
    case translationLanguagePicker
    case trendingSearches
    case unifiedSearch
    case videoIntroOnboarding
    case worldCupWidget

    /// The user preferences key for features that support user-togglable settings.
    /// Returns `nil` for features that are not user-configurable.
    var userPrefsKey: String? {
        typealias FlagKeys = PrefsKeys.FeatureFlags
        typealias HomepageKeys = PrefsKeys.HomepageSettings

        switch self {
        case .aiKillSwitch: return PrefsKeys.Settings.aiKillSwitchFeature
        case .firefoxSuggestFeature: return FlagKeys.FirefoxSuggest
        case .homepageBookmarksSectionDefault: return HomepageKeys.BookmarksSection
        case .homepageJumpBackinSectionDefault: return HomepageKeys.JumpBackInSection
        case .hntSponsoredShortcuts: return FlagKeys.SponsoredShortcuts
        case .sentFromFirefox: return FlagKeys.SentFromFirefox
        case .startAtHome: return FlagKeys.StartAtHome
        default: return nil
        }
    }

    // Add flags here if you want to toggle them in the `FeatureFlagsDebugViewController`.
    // Add in alphabetical order.
    var debugKey: String? {
        switch self {
        case    .addressBarMenu,
                .adsClient,
                .aiKillSwitch,
                .appearanceMenu,
                .appIconSelection,
                .badCertDomainErrorPage,
                .bookmarksSearchFeature,
                .deeplinkOptimizationRefactor,
                .downloadLiveActivities,
                .homepageSearchBar,
                .homepageStoryCategories,
                .hostedSummarizer,
                .httpsUpgrade,
                .improvedAppStoreReviewTriggerFeature,
                .microsurvey,
                .nativeErrorPage,
                .needsReloadRefactor,
                .noInternetConnectionErrorPage,
                .quickAnswers,
                .recentSearches,
                .relayIntegration,
                .sentFromFirefox,
                .snapkitRemovalRefactor,
                .summarizerAppAttestAuth,
                .summarizerLanguageExpansion,
                .summarizerPermissiveGuardrails,
                .tabScrollRefactorFeature,
                .tabTrayUIExperiments,
                .touFeature,
                .trackingProtectionRefactor,
                .translation,
                .translationLanguagePicker,
                .trendingSearches,
                .unifiedSearch,
                .worldCupWidget:
            return rawValue + PrefsKeys.FeatureFlags.DebugSuffixKey
        default:
            return nil
        }
    }
}
