// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

/// An enum describing the featureID of all features found in Nimbus.
/// Please add new features alphabetically.
enum FeatureFlagID: String, CaseIterable {
    case adBlocker
    case addressAutofillEdit
    case addressBarGestureToOpenTabTrayInteractive
    case addressBarGestureToOpenTabTraySwipe
    case adsClient
    case aiKillSwitch
    case appearanceMenu
    case badCertDomainErrorPage
    case bookmarksSearchFeature
    case customReaderModeScheme
    case deeplinkOptimizationRefactor
    case deeplinkOverlay
    case downloadLiveActivities
    case firefoxJpGuideDefaultSite
    case firefoxSuggestFeature
    case googleLens
    case hntSponsoredShortcuts
    case homepageAddShortcutTile
    case homepageBookmarksSectionDefault
    case homepageJumpBackinSectionDefault
    case homepagePinnedHeader
    case homepageSearchBar
    case homepageStoryCategories
    case homepageTrackerBlockerModule
    case hostedSummarizer
    case hostedSummarizerShakeGesture
    case hostedSummarizerToolbarEntrypoint
    case httpsUpgrade
    case improvedAppStoreReviewTriggerFeature
    case microsurvey
    case modernOnboardingUI
    case nativeErrorPage
    case needsReloadRefactor
    case newBookmarkFolderTree
    case novaDesign
    case noInternetConnectionErrorPage
    case quickAnswers
    case recentSearches
    case relayIntegration
    case reportBrokenSite
    case sentFromFirefox
    case sentFromFirefoxTreatmentA
    case shouldUseBrandRefreshConfiguration
    case shouldUseJapanConfiguration
    case snapkitRemovalRefactor
    case startAtHome
    case summarizerAppAttestAuth
    case summarizerLanguageExpansion
    case summarizerPermissiveGuardrails
    case tabScrollRefactorFeature
    case tabTrayiPadUIExperiments
    case tabTrayTranslucency
    case tabTrayUIExperiments
    case tosFeature
    case touFeature
    case translation
    case translationLanguagePicker
    case trendingSearches
    case unifiedSearch
    case videoIntroOnboarding
    case waybackMachine
    case worldCupWidget

    /// The user preferences key for features that support user-togglable settings.
    /// Returns `nil` for features that are not user-configurable.
    var userPrefsKey: String? {
        typealias FlagKeys = PrefsKeys.FeatureFlags
        typealias HomepageKeys = PrefsKeys.HomepageSettings

        switch self {
        case .aiKillSwitch: return PrefsKeys.Settings.aiKillSwitchFeature
        case .firefoxSuggestFeature: return FlagKeys.FirefoxSuggest
        case .hntSponsoredShortcuts: return FlagKeys.SponsoredShortcuts
        case .homepageBookmarksSectionDefault: return HomepageKeys.BookmarksSection
        case .homepageJumpBackinSectionDefault: return HomepageKeys.JumpBackInSection
        case .homepageTrackerBlockerModule: return HomepageKeys.TrackerBlockerSection
        case .sentFromFirefox: return FlagKeys.SentFromFirefox
        case .startAtHome: return FlagKeys.StartAtHome
        case .quickAnswers: return PrefsKeys.Settings.quickAnswersFeature
        default: return nil
        }
    }

    // Add flags here if you want to toggle them in the `FeatureFlagsDebugViewController`.
    // Add in alphabetical order.
    var debugKey: String? {
        switch self {
        case    .adBlocker,
                .addressBarGestureToOpenTabTrayInteractive,
                .addressBarGestureToOpenTabTraySwipe,
                .adsClient,
                .aiKillSwitch,
                .appearanceMenu,
                .badCertDomainErrorPage,
                .bookmarksSearchFeature,
                .customReaderModeScheme,
                .deeplinkOptimizationRefactor,
                .deeplinkOverlay,
                .downloadLiveActivities,
                .googleLens,
                .homepageAddShortcutTile,
                .homepagePinnedHeader,
                .homepageSearchBar,
                .homepageStoryCategories,
                .homepageTrackerBlockerModule,
                .hostedSummarizer,
                .httpsUpgrade,
                .improvedAppStoreReviewTriggerFeature,
                .microsurvey,
                .nativeErrorPage,
                .needsReloadRefactor,
                .newBookmarkFolderTree,
                .novaDesign,
                .noInternetConnectionErrorPage,
                .quickAnswers,
                .recentSearches,
                .relayIntegration,
                .reportBrokenSite,
                .sentFromFirefox,
                .snapkitRemovalRefactor,
                .summarizerAppAttestAuth,
                .summarizerLanguageExpansion,
                .summarizerPermissiveGuardrails,
                .tabScrollRefactorFeature,
                .tabTrayUIExperiments,
                .touFeature,
                .translation,
                .translationLanguagePicker,
                .trendingSearches,
                .unifiedSearch,
                .waybackMachine,
                .worldCupWidget:
            return rawValue + PrefsKeys.FeatureFlags.DebugSuffixKey
        default:
            return nil
        }
    }
}
