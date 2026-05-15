// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol NimbusFeatureFlagLayerProviding: Sendable {
    func checkNimbusConfigFor(_ featureID: FeatureFlagID) -> Bool
    func checkStartAtHomeConfiguration() -> StartAtHome
}

final class NimbusFeatureFlagLayer: NimbusFeatureFlagLayerProviding, Sendable {
    private let nimbus: FxNimbus

    init(nimbus: FxNimbus = FxNimbus.shared) {
        self.nimbus = nimbus
    }

    // MARK: - Public methods
    // swiftlint:disable:next function_body_length
    public func checkNimbusConfigFor(_ featureID: FeatureFlagID) -> Bool {
        // For better code readability, please keep in alphabetical order by FeatureFlagID
        switch featureID {
        case .addressAutofillEdit:
            return checkAddressAutofillEditing()

        case .addressBarMenu:
            return checkAddressBarMenuFeature()

        case .adsClient:
            return checkAdsClientFeature()

        case .aiKillSwitch:
            return checkAiKillSwitchFeature()

        case .appearanceMenu:
            return checkAppearanceMenuFeature()

        case .badCertDomainErrorPage:
            return checkBadCertDomainErrorPageFeature()

        case .bookmarksSearchFeature:
            return checkBookmarksSearchFeature()


        case .customReaderModeScheme:
            return checkCustomReaderModeSchemeFeature()
        case .deeplinkOptimizationRefactor:
            return checkDeeplinkOptimizationRefactorFeature()

        case .downloadLiveActivities:
            return checkDownloadLiveActivitiesFeature()

        case .firefoxJpGuideDefaultSite:
            return checkFirefoxJpGuideDefaultSiteFeature()

        case .firefoxSuggestFeature:
            return checkFirefoxSuggestFeature()

        case .hntSponsoredShortcuts:
            return checkHNTSponsoredShortcutsFeature()

        case .homepageBookmarksSectionDefault:
            return checkHomepageBookmarksSectionDefault()

        case .homepageJumpBackinSectionDefault:
            return checkHomepageJumpBackInSectionDefault()

        case .homepagePinnedHeader:
            return checkHomepagePinnedHeaderFeature()

        case .homepageSearchBar:
            return checkHomepageSearchBarFeature()

        case .homepageStoryCategories:
            return checkHomepageStoriesCaterogiesFeature()

        case .hostedSummarizer:
            return checkHostedSummarizerFeature()

        case .hostedSummarizerShakeGesture:
           return checkHostedSummarizerShakeGesture()

        case .hostedSummarizerToolbarEntrypoint:
           return checkHostedSummarizerToolbarEntrypoint()

        case .httpsUpgrade:
            return checkHttpsUpgradeFeature()

        case .improvedAppStoreReviewTriggerFeature:
            return checkImprovedAppStoreReviewTriggerFeature()

        case .microsurvey:
            return checkMicrosurveyFeature()

        case .modernOnboardingUI:
            return checkMondernOnboardingUIFeature()

        case .nativeErrorPage:
            return checkNativeErrorPageFeature()

        case .needsReloadRefactor:
            return checkNeedsReloadRefactorFeature()

        case .noInternetConnectionErrorPage:
            return checkNICErrorPageFeature()

        case .quickAnswers:
            return checkQuickAnswersFeature()

        case .recentSearches:
            return checkRecentSearchesFeature()

        case .relayIntegration:
            return checkRelayIntegration()

        case .reportSiteIssue:
            return checkGeneralFeature(for: featureID)

        case .sentFromFirefox:
            return checkSentFromFirefoxFeature()

        case .sentFromFirefoxTreatmentA:
            return checkSentFromFirefoxFeatureTreatmentA()

        case .shouldUseBrandRefreshConfiguration:
            return checkShouldUseBrandRefreshConfigurationFeature()

        case .shouldUseJapanConfiguration:
            return checkShouldUseJapanConfigurationFeature()

        case .snapkitRemovalRefactor:
            return checkSnapKitRemovalRefactor()

        case .splashScreen:
            return checkSplashScreenFeature(for: featureID)

        case .startAtHome:
            return checkStartAtHomeFeature(for: featureID) != .disabled

        case .summarizerAppAttestAuth:
            return checkSummarizerAppAttestAuthFeature()

        case .summarizerLanguageExpansion:
            return checkSummarizerLanguageExpansionFeature()

        case .summarizerPermissiveGuardrails:
            return checkSummarizerPermissiveGuardrailsFeature()

        case .tabScrollRefactorFeature:
            return checkTabScrollRefactorFeature()

        case .tabTrayiPadUIExperiments:
            return checkTabTrayiPadUIExperiments()

        case .tabTrayTranslucency:
            return checkTabTrayTranslucencyFeature()

        case .tabTrayUIExperiments:
            return checkTabTrayUIExperiments()

        case .tosFeature:
            return checkTosFeature()

        case .touFeature:
            return checkTouFeature()

        case .trackingProtectionRefactor:
            return checkTrackingProtectionRefactor()

        case .translation:
            return checkTranslationFeature()

        case .translationLanguagePicker:
            return checkTranslationLanguagePickerFeature()

        case .trendingSearches:
            return checkTrendingSearches()

        case .unifiedSearch:
            return checkUnifiedSearchFeature()

        case .videoIntroOnboarding:
            return checkVideoIntroOnboardingFeature()

        case .worldCupWidget:
            return checkWorldCupWidgetFeature()
        }
    }

    // MARK: - Private methods
    private func checkGeneralFeature(for featureID: FeatureFlagID) -> Bool {
        let config = nimbus.features.generalAppFeatures.value()

        switch featureID {
        case .reportSiteIssue: return config.reportSiteIssue.status
        default: return false
        }
    }

    private func checkSentFromFirefoxFeature() -> Bool {
        let config = nimbus.features.sentFromFirefoxFeature.value()
        return config.enabled
    }

    private func checkSentFromFirefoxFeatureTreatmentA() -> Bool {
        let config = nimbus.features.sentFromFirefoxFeature.value()
        return config.isTreatmentA
    }

    private func checkHNTSponsoredShortcutsFeature() -> Bool {
        return nimbus.features.hntSponsoredShortcutsFeature.value().enabled
    }

    private func checkHomepageBookmarksSectionDefault() -> Bool {
        return nimbus.features.homepageRedesignFeature.value().bookmarksSectionDefault
    }

    private func checkHomepageJumpBackInSectionDefault() -> Bool {
        return nimbus.features.homepageRedesignFeature.value().jbiSectionDefault
    }

    private func checkHomepagePinnedHeaderFeature() -> Bool {
        return nimbus.features.homepageRedesignFeature.value().pinnedHeaderEnabled
    }

    private func checkHomepageSearchBarFeature() -> Bool {
        return nimbus.features.homepageRedesignFeature.value().searchBar
    }

    private func checkHomepageStoriesCaterogiesFeature() -> Bool {
        return nimbus.features.homepageRedesignFeature.value().categoriesEnabled
    }

    private func checkSnapKitRemovalRefactor() -> Bool {
        let config = nimbus.features.snapkitRemovalRefactor.value()
        return config.enabled
    }

    private func checkTabScrollRefactorFeature() -> Bool {
        return nimbus.features.tabScrollRefactorFeature.value().enabled
    }

    private func checkTabTrayiPadUIExperiments() -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.iPadUpdateEnabled
    }

    private func checkTabTrayTranslucencyFeature() -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.translucency
    }

    private func checkTabTrayUIExperiments() -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.enabled
    }

    private func checkUnifiedSearchFeature() -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.unifiedSearch
    }

    private func checkRelayIntegration() -> Bool {
        return nimbus.features.relayIntegrationFeature.value().enabled
    }

    private func checkTosFeature() -> Bool {
        let config = nimbus.features.tosFeature.value()
        return config.status
    }

    private func checkTouFeature() -> Bool {
        return nimbus.features.touFeature.value().status
    }

    private func checkTrackingProtectionRefactor() -> Bool {
        let config = nimbus.features.trackingProtectionRefactor.value()
        return config.enabled
    }

    private func checkTranslationFeature() -> Bool {
        return nimbus.features.translationsFeature.value().enabled
    }

    private func checkTranslationLanguagePickerFeature() -> Bool {
        return nimbus.features.translationsFeature.value().languagePickerEnabled
    }

    private func checkTrendingSearches() -> Bool {
        return nimbus.features.trendingSearchesFeature.value().enabled
    }

    private func checkQuickAnswersFeature() -> Bool {
        return nimbus.features.quickAnswersFeature.value().enabled
    }

    private func checkSplashScreenFeature(for featureID: FeatureFlagID) -> Bool {
        return nimbus.features.splashScreen.value().enabled
    }

    private func checkStartAtHomeFeature(for featureID: FeatureFlagID) -> StartAtHome {
        let config = nimbus.features.startAtHomeFeature.value()
        let nimbusSetting = config.setting

        switch nimbusSetting {
        case .afterFourHours: return .afterFourHours
        case .always: return .always
        case .disabled: return .disabled
        }
    }

    private func checkRecentSearchesFeature() -> Bool {
        return nimbus.features.recentSearchesFeature.value().enabled
    }

    private func checkAddressAutofillEditing() -> Bool {
        let config = nimbus.features.addressAutofillEdit.value()

        return config.status
    }

    private func checkAdsClientFeature() -> Bool {
        let config = nimbus.features.adsClient.value()
        return config.status
    }

    private func checkAppearanceMenuFeature() -> Bool {
        let config = nimbus.features.appearanceMenuFeature.value()
        return config.status
    }

    private func checkAddressBarMenuFeature() -> Bool {
        let config = nimbus.features.addressBarMenuFeature.value()
        return config.status
    }

    private func checkDeeplinkOptimizationRefactorFeature() -> Bool {
        let config = nimbus.features.deeplinkOptimizationRefactorFeature.value()
        return config.enabled
    }

    private func checkDownloadLiveActivitiesFeature() -> Bool {
        return nimbus.features.downloadLiveActivitiesFeature.value().enabled
    }

    private func checkFirefoxJpGuideDefaultSiteFeature() -> Bool {
        return nimbus.features.firefoxJpGuideDefaultSite.value().enabled
    }

    private func checkFirefoxSuggestFeature() -> Bool {
        let config = nimbus.features.firefoxSuggestFeature.value()

        return config.status
    }

    private func checkMicrosurveyFeature() -> Bool {
        let config = nimbus.features.microsurveyFeature.value()

        return config.enabled
    }

    private func checkNativeErrorPageFeature() -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().enabled
    }

    private func checkNICErrorPageFeature() -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().noInternetConnectionError
    }

    private func checkBadCertDomainErrorPageFeature() -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().badCertDomainErrorPage
    }

    private func checkImprovedAppStoreReviewTriggerFeature() -> Bool {
        return nimbus.features.improvedAppStoreReviewTriggerFeature.value().enabled
    }

    // MARK: - Summarizer Feature

    private func checkHostedSummarizerFeature() -> Bool {
        let config = nimbus.features.hostedSummarizerFeature.value()
        return config.enabled
    }

    private func checkHostedSummarizerToolbarEntrypoint() -> Bool {
        let config = nimbus.features.hostedSummarizerFeature.value()
        return config.toolbarEntrypoint
    }

    private func checkHostedSummarizerShakeGesture() -> Bool {
        return nimbus.features.hostedSummarizerFeature.value().shakeGesture
    }

    private func checkHttpsUpgradeFeature() -> Bool {
        return nimbus.features.httpsUpgradeFeature.value().enabled
    }

    private func checkSummarizerAppAttestAuthFeature() -> Bool {
        return nimbus.features.summarizerAppAttestAuthFeature.value().enabled
    }

    private func checkSummarizerLanguageExpansionFeature() -> Bool {
        return nimbus.features.summarizerLanguageExpansionFeature.value().enabled
    }

    private func checkSummarizerPermissiveGuardrailsFeature() -> Bool {
        return nimbus.features.summarizerPermissiveGuardrailsFeature.value().enabled
    }

    private func checkMondernOnboardingUIFeature() -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().enableModernUi
    }

    private func checkShouldUseBrandRefreshConfigurationFeature() -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().shouldUseBrandRefreshConfiguration
    }

    private func checkShouldUseJapanConfigurationFeature() -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().shouldUseJapanConfiguration
    }

    private func checkVideoIntroOnboardingFeature() -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().enableVideoIntro
    }

    private func checkNeedsReloadRefactorFeature() -> Bool {
        return nimbus.features.needsReloadRefactor.value().enabled
    }

    private func checkAiKillSwitchFeature() -> Bool {
        return nimbus.features.aiKillSwitchFeature.value().enabled
    }

    private func checkBookmarksSearchFeature() -> Bool {
        return nimbus.features.bookmarksSearchFeature.value().enabled
    }

    private func checkWorldCupWidgetFeature() -> Bool {
        return nimbus.features.worldCupWidgetFeature.value().enabled
    }

    func checkStartAtHomeConfiguration() -> StartAtHome {
        return nimbus.features.startAtHomeFeature.value().setting
    }

    private func checkCustomReaderModeSchemeFeature() -> Bool {
        return nimbus.features.customReaderModeSchemeFeature.value().enabled
    }
}
