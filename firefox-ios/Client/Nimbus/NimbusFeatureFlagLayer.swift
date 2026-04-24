// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NimbusFeatureFlagLayer: Sendable {
    // MARK: - Public methods
    // swiftlint:disable:next function_body_length
    public func checkNimbusConfigFor(
        _ featureID: FeatureFlagID,
        from nimbus: FxNimbus = FxNimbus.shared
    ) -> Bool {
        // For better code readability, please keep in alphabetical order by FeatureFlagID
        switch featureID {
        case .addressAutofillEdit:
            return checkAddressAutofillEditing(from: nimbus)

        case .adsClient:
            return checkAdsClientFeature(from: nimbus)

        case .aiKillSwitch:
            return checkAiKillSwitchFeature(from: nimbus)

        case .appearanceMenu:
            return checkAppearanceMenuFeature(from: nimbus)

        case .appIconSelection:
            return checkAppIconSelectionSetting(from: nimbus)

        case .addressBarMenu:
            return checkAddressBarMenuFeature(from: nimbus)

        case .bookmarksSearchFeature:
            return checkBookmarksSearchFeature(from: nimbus)

        case .deeplinkOptimizationRefactor:
            return checkDeeplinkOptimizationRefactorFeature(from: nimbus)

        case .downloadLiveActivities:
            return checkDownloadLiveActivitiesFeature(from: nimbus)

        case .firefoxJpGuideDefaultSite:
            return checkFirefoxJpGuideDefaultSiteFeature(from: nimbus)

        case .firefoxSuggestFeature:
            return checkFirefoxSuggestFeature(from: nimbus)

        case .hntSponsoredShortcuts:
            return checkHNTSponsoredShortcutsFeature(from: nimbus)

        case .homepageBookmarksSectionDefault:
            return checkHomepageBookmarksSectionDefault(from: nimbus)

        case .homepageJumpBackinSectionDefault:
            return checkHomepageJumpBackInSectionDefault(from: nimbus)

        case .homepageSearchBar:
            return checkHomepageSearchBarFeature(from: nimbus)

        case .homepageStoryCategories:
            return checkHomepageStoriesCaterogiesFeature(from: nimbus)

        case .needsReloadRefactor:
            return checkNeedsReloadRefactorFeature(from: nimbus)

        case .shouldUseBrandRefreshConfiguration:
            return checkShouldUseBrandRefreshConfigurationFeature(from: nimbus)

        case .shouldUseJapanConfiguration:
            return checkShouldUseJapanConfigurationFeature(from: nimbus)

        case .microsurvey:
            return checkMicrosurveyFeature(from: nimbus)

        case .modernOnboardingUI:
            return checkMondernOnboardingUIFeature(from: nimbus)

        case .nativeErrorPage:
            return checkNativeErrorPageFeature(from: nimbus)

        case .noInternetConnectionErrorPage:
            return checkNICErrorPageFeature(from: nimbus)

        case .badCertDomainErrorPage:
            return checkBadCertDomainErrorPageFeature(from: nimbus)

        case .recentSearches:
            return checkRecentSearchesFeature(from: nimbus)

        case .reportSiteIssue:
            return checkGeneralFeature(for: featureID, from: nimbus)

        case .sentFromFirefox:
            return checkSentFromFirefoxFeature(from: nimbus)

        case .sentFromFirefoxTreatmentA:
            return checkSentFromFirefoxFeatureTreatmentA(from: nimbus)

        case .snapkitRemovalRefactor:
            return checkSnapKitRemovalRefactor(from: nimbus)

        case .splashScreen:
            return checkSplashScreenFeature(for: featureID, from: nimbus)

        case .startAtHome:
            return checkStartAtHomeFeature(for: featureID, from: nimbus) != .disabled

        case .hostedSummarizer:
            return checkHostedSummarizerFeature(from: nimbus)

        case .httpsUpgrade:
            return checkHttpsUpgradeFeature(from: nimbus)

        case .improvedAppStoreReviewTriggerFeature:
            return checkImprovedAppStoreReviewTriggerFeature(from: nimbus)

        case .relayIntegration:
            return checkRelayIntegration(from: nimbus)

        case .hostedSummarizerToolbarEntrypoint:
           return checkHostedSummarizerToolbarEntrypoint(from: nimbus)

        case .hostedSummarizerShakeGesture:
           return checkHostedSummarizerShakeGesture(from: nimbus)

        case .summarizerAppAttestAuth:
            return checkSummarizerAppAttestAuthFeature(from: nimbus)

        case .summarizerLanguageExpansion:
            return checkSummarizerLanguageExpansionFeature(from: nimbus)

        case .summarizerPermissiveGuardrails:
            return checkSummarizerPermissiveGuardrailsFeature(from: nimbus)

        case .unifiedSearch:
            return checkUnifiedSearchFeature(from: nimbus)

        case .tabScrollRefactorFeature:
            return checkTabScrollRefactorFeature(from: nimbus)

        case .tabTrayiPadUIExperiments:
            return checkTabTrayiPadUIExperiments(from: nimbus)

        case .tabTrayTranslucency:
            return checkTabTrayTranslucencyFeature(from: nimbus)

        case .tabTrayUIExperiments:
            return checkTabTrayUIExperiments(from: nimbus)

        case .toolbarUpdateHint:
            return checkToolbarUpdateHintFeature(from: nimbus)

        case .tosFeature:
            return checkTosFeature(from: nimbus)

        case .touFeature:
            return checkTouFeature(from: nimbus)

        case .trackingProtectionRefactor:
            return checkTrackingProtectionRefactor(from: nimbus)

        case .translation:
            return checkTranslationFeature(from: nimbus)

        case .translationLanguagePicker:
            return checkTranslationLanguagePickerFeature(from: nimbus)

        case .trendingSearches:
            return checkTrendingSearches(from: nimbus)

        case .videoIntroOnboarding:
            return checkVideoIntroOnboardingFeature(from: nimbus)

        case .quickAnswers:
            return checkQuickAnswersFeature(from: nimbus)

        case .worldCupWidget:
            return checkWorldCupWidgetFeature(from: nimbus)
        }
    }

    // MARK: - Private methods
    private func checkGeneralFeature(for featureID: FeatureFlagID,
                                     from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.generalAppFeatures.value()

        switch featureID {
        case .reportSiteIssue: return config.reportSiteIssue.status
        default: return false
        }
    }

    private func checkSentFromFirefoxFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.sentFromFirefoxFeature.value()
        return config.enabled
    }

    private func checkSentFromFirefoxFeatureTreatmentA(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.sentFromFirefoxFeature.value()
        return config.isTreatmentA
    }

    private func checkHNTSponsoredShortcutsFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.hntSponsoredShortcutsFeature.value().enabled
    }

    private func checkHomepageBookmarksSectionDefault(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homepageRedesignFeature.value().bookmarksSectionDefault
    }

    private func checkHomepageJumpBackInSectionDefault(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homepageRedesignFeature.value().jbiSectionDefault
    }

    private func checkHomepageSearchBarFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homepageRedesignFeature.value().searchBar
    }

    private func checkHomepageStoriesCaterogiesFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homepageRedesignFeature.value().categoriesEnabled
    }

    private func checkSnapKitRemovalRefactor(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.snapkitRemovalRefactor.value()
        return config.enabled
    }

    private func checkTabScrollRefactorFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.tabScrollRefactorFeature.value().enabled
    }

    private func checkTabTrayiPadUIExperiments(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.iPadUpdateEnabled
    }

    private func checkTabTrayTranslucencyFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.translucency
    }

    private func checkTabTrayUIExperiments(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.enabled
    }

    private func checkUnifiedSearchFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.unifiedSearch
    }

    private func checkRelayIntegration(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.relayIntegrationFeature.value().enabled
    }

    private func checkToolbarUpdateHintFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.toolbarUpdateHint
    }

    private func checkTosFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.tosFeature.value()
        return config.status
    }

    private func checkTouFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.touFeature.value().status
    }

    private func checkTrackingProtectionRefactor(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.trackingProtectionRefactor.value()
        return config.enabled
    }

    private func checkTranslationFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.translationsFeature.value().enabled
    }

    private func checkTranslationLanguagePickerFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.translationsFeature.value().languagePickerEnabled
    }

    private func checkTrendingSearches(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.trendingSearchesFeature.value().enabled
    }

    private func checkQuickAnswersFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.quickAnswersFeature.value().enabled
    }

    private func checkSplashScreenFeature(
        for featureID: FeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        return nimbus.features.splashScreen.value().enabled
    }

    private func checkStartAtHomeFeature(for featureID: FeatureFlagID, from nimbus: FxNimbus) -> StartAtHome {
        let config = nimbus.features.startAtHomeFeature.value()
        let nimbusSetting = config.setting

        switch nimbusSetting {
        case .afterFourHours: return .afterFourHours
        case .always: return .always
        case .disabled: return .disabled
        }
    }

    private func checkRecentSearchesFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.recentSearchesFeature.value().enabled
    }

    private func checkAddressAutofillEditing(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.addressAutofillEdit.value()

        return config.status
    }

    private func checkAdsClientFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.adsClient.value()
        return config.status
    }

    private func checkAppearanceMenuFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.appearanceMenuFeature.value()
        return config.status
    }

    private func checkAppIconSelectionSetting(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.appIconSelectionFeature.value()
        return config.funIconsEnabled
    }

    private func checkAddressBarMenuFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.addressBarMenuFeature.value()
        return config.status
    }

    private func checkDeeplinkOptimizationRefactorFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.deeplinkOptimizationRefactorFeature.value()
        return config.enabled
    }

    private func checkDownloadLiveActivitiesFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.downloadLiveActivitiesFeature.value().enabled
    }

    private func checkFirefoxJpGuideDefaultSiteFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.firefoxJpGuideDefaultSite.value().enabled
    }

    private func checkFirefoxSuggestFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.firefoxSuggestFeature.value()

        return config.status
    }

    private func checkMicrosurveyFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.microsurveyFeature.value()

        return config.enabled
    }

    private func checkNativeErrorPageFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().enabled
    }

    private func checkNICErrorPageFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().noInternetConnectionError
    }

    private func checkBadCertDomainErrorPageFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().badCertDomainErrorPage
    }

    private func checkImprovedAppStoreReviewTriggerFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.improvedAppStoreReviewTriggerFeature.value().enabled
    }

    // MARK: - Summarizer Feature

    private func checkHostedSummarizerFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.hostedSummarizerFeature.value()
        return config.enabled
    }

    private func checkHostedSummarizerToolbarEntrypoint(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.hostedSummarizerFeature.value()
        return config.toolbarEntrypoint
    }

    private func checkHostedSummarizerShakeGesture(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.hostedSummarizerFeature.value().shakeGesture
    }

    private func checkHttpsUpgradeFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.httpsUpgradeFeature.value().enabled
    }

    private func checkSummarizerAppAttestAuthFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.summarizerAppAttestAuthFeature.value().enabled
    }

    private func checkSummarizerLanguageExpansionFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.summarizerLanguageExpansionFeature.value().enabled
    }

    private func checkSummarizerPermissiveGuardrailsFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.summarizerPermissiveGuardrailsFeature.value().enabled
    }

    private func checkMondernOnboardingUIFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().enableModernUi
    }

    private func checkShouldUseBrandRefreshConfigurationFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().shouldUseBrandRefreshConfiguration
    }

    private func checkShouldUseJapanConfigurationFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().shouldUseJapanConfiguration
    }

    private func checkVideoIntroOnboardingFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().enableVideoIntro
    }

    private func checkNeedsReloadRefactorFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.needsReloadRefactor.value().enabled
    }

    private func checkAiKillSwitchFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.aiKillSwitchFeature.value().enabled
    }

    private func checkBookmarksSearchFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.bookmarksSearchFeature.value().enabled
    }

    private func checkWorldCupWidgetFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.worldCupWidgetFeature.value().enabled
    }
}
