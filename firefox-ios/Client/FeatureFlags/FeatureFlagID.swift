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
    case needsReloadRefactor
    case shouldUseBrandRefreshConfiguration
    case shouldUseJapanConfiguration
    case microsurvey
    case modernOnboardingUI
    case nativeErrorPage
    case noInternetConnectionErrorPage
    case recentSearches
    case reportSiteIssue
    case relayIntegration
    case sentFromFirefox
    case sentFromFirefoxTreatmentA
    case snapkitRemovalRefactor
    case splashScreen
    case startAtHome
    case hostedSummarizer
    case hostedSummarizerToolbarEntrypoint
    case hostedSummarizerShakeGesture
    case httpsUpgrade
    case improvedAppStoreReviewTriggerFeature
    case summarizerAppAttestAuth
    case summarizerLanguageExpansion
    case summarizerPermissiveGuardrails
    case tabScrollRefactorFeature
    case tabTrayiPadUIExperiments
    case tabTrayUIExperiments
    case tabTrayTranslucency
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
    case quickAnswers

    // Add flags here if you want to toggle them in the `FeatureFlagsDebugViewController`. Add in alphabetical order.
    var debugKey: String? {
        switch self {
        case    .aiKillSwitch,
                .appearanceMenu,
                .appIconSelection,
                .addressBarMenu,
                .adsClient,
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

/// This enum is a constraint for any feature flag options that have more than
/// just an ON or OFF setting. These option must also be added to `FeatureFlagID`
enum FeatureFlagIDWithCustomOptions {
    case startAtHome
}
