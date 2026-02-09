// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NimbusFeatureFlagLayer: Sendable {
    // MARK: - Public methods
    // swiftlint:disable:next function_body_length
    public func checkNimbusConfigFor(
        _ featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus = FxNimbus.shared
    ) -> Bool {
        // For better code readability, please keep in alphabetical order by NimbusFeatureFlagID
        switch featureID {
        case .addressAutofillEdit:
            return checkAddressAutofillEditing(from: nimbus)

        case .appearanceMenu:
            return checkAppearanceMenuFeature(from: nimbus)

        case .appIconSelection:
            return checkAppIconSelectionSetting(from: nimbus)

        case .addressBarMenu:
            return checkAddressBarMenuFeature(from: nimbus)

        case .bottomSearchBar:
            return checkAwesomeBarFeature(for: featureID, from: nimbus)

        case .deeplinkOptimizationRefactor:
            return checkDeeplinkOptimizationRefactorFeature(from: nimbus)

        case .defaultZoomFeature:
            return checkDefaultZoomFeature(from: nimbus)

        case .downloadLiveActivities:
            return checkDownloadLiveActivitiesFeature(from: nimbus)

        case .firefoxJpGuideDefaultSite:
            return checkFirefoxJpGuideDefaultSiteFeature(from: nimbus)

        case .firefoxSuggestFeature:
            return checkFirefoxSuggestFeature(from: nimbus)

        case .feltPrivacySimplifiedUI, .feltPrivacyFeltDeletion:
            return checkFeltPrivacyFeature(for: featureID, from: nimbus)

        case .hntSponsoredShortcuts:
            return checkHNTSponsoredShortcutsFeature(from: nimbus)

        case .homepageBookmarksSectionDefault:
            return checkHomepageBookmarksSectionDefault(from: nimbus)

        case .homepageJumpBackinSectionDefault:
            return checkHomepageJumpBackInSectionDefault(from: nimbus)

        case .homepageSearchBar:
            return checkHomepageSearchBarFeature(from: nimbus)

        case .homepageStoriesScrollDirection:
            return checkHomepageStoriesScrollDirectionFeature(from: nimbus) != .baseline

        case .shouldUseBrandRefreshConfiguration:
            return checkShouldUseBrandRefreshConfigurationFeature(from: nimbus)

        case .shouldUseJapanConfiguration:
            return checkShouldUseJapanConfigurationFeature(from: nimbus)

        case .menuDefaultBrowserBanner:
            return checkMenuDefaultBrowserBanner(from: nimbus)

        case .menuRefactor:
            return checkMenuRefactor(from: nimbus)

        case .menuRedesignHint:
            return checkMenuRedesignHint(from: nimbus)

        case .microsurvey:
            return checkMicrosurveyFeature(from: nimbus)

        case .modernOnboardingUI:
            return checkMondernOnboardingUIFeature(from: nimbus)

        case .nativeErrorPage:
            return checkNativeErrorPageFeature(from: nimbus)

        case .noInternetConnectionErrorPage:
            return checkNICErrorPageFeature(from: nimbus)

        case .otherErrorPages:
            return checkOtherErrorPagesFeature(from: nimbus)

        case .privacyNotice:
            return checkPrivacyNoticeFeature(from: nimbus)

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

        case .appleSummarizer:
           return checkAppleSummarizerFeature(from: nimbus)

        case .appleSummarizerToolbarEntrypoint:
           return checkAppleSummarizerToolbarEntrypoint(from: nimbus)

        case .appleSummarizerShakeGesture:
           return checkAppleSummarizerShakeGesture(from: nimbus)

        case .hostedSummarizer:
            return checkHostedSummarizerFeature(from: nimbus)

        case .relayIntegration:
            return checkRelayIntegration(from: nimbus)

        case .hostedSummarizerToolbarEntrypoint:
           return checkHostedSummarizerToolbarEntrypoint(from: nimbus)

        case .hostedSummarizerShakeGesture:
           return checkHostedSummarizerShakeGesture(from: nimbus)

        case .toolbarRefactor:
            return checkToolbarRefactorFeature(from: nimbus)

        case .unifiedSearch:
            return checkUnifiedSearchFeature(from: nimbus)

        case .tabTrayTranslucency:
            return checkTabTrayTranslucencyFeature(from: nimbus)

        case .tabScrollRefactorFeature:
            return checkTabScrollRefactorFeature(from: nimbus)

        case .tabTrayUIExperiments:
            return checkTabTrayUIExperiments(from: nimbus)

        case .toolbarOneTapNewTab:
            return checkToolbarOneTapNewTabFeature(from: nimbus)

        case .toolbarSwipingTabs:
            return checkToolbarSwipingTabsFeature(from: nimbus)

        case .toolbarTranslucency:
            return checkToolbarTranslucencyFeature(from: nimbus)

        case .toolbarTranslucencyRefactor:
            return checkToolbarTranslucencyRefactorFeature(from: nimbus)

        case .toolbarMinimalAddressBar:
            return checkToolbarMinimalAddressBarFeature(from: nimbus)

        case .toolbarMiddleButtonCustomization:
            return checkToolbarMiddleButtonCustomizationFeature(from: nimbus)

        case .toolbarNavigationHint:
            return checkToolbarNavigationHintFeature(from: nimbus)

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

        case .trendingSearches:
            return checkTrendingSearches(from: nimbus)

        case .voiceSearch:
            return checkVoiceSearchFeature(from: nimbus)

        case .webEngineIntegrationRefactor:
            return checkWebEngineIntegrationRefactor(from: nimbus)
        }
    }

    // MARK: - Private methods
    private func checkGeneralFeature(for featureID: NimbusFeatureFlagID,
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

    private func checkAwesomeBarFeature(for featureID: NimbusFeatureFlagID,
                                        from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.search.value().awesomeBar

        switch featureID {
        case .bottomSearchBar: return config.position.isPositionFeatureEnabled
        default: return false
        }
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

    private func checkHomepageStoriesScrollDirectionFeature(from nimbus: FxNimbus) -> ScrollDirection {
        return nimbus.features.homepageRedesignFeature.value().storiesScrollDirection
    }

    private func checkSnapKitRemovalRefactor(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.snapkitRemovalRefactor.value()
        return config.enabled
    }

    private func checkTabTrayTranslucencyFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.translucency
    }

    private func checkTabScrollRefactorFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.tabScrollRefactorFeature.value().enabled
    }

    private func checkTabTrayUIExperiments(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.enabled
    }

    private func checkToolbarRefactorFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.enabled
    }

    private func checkUnifiedSearchFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.unifiedSearch
    }

    private func checkToolbarOneTapNewTabFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.oneTapNewTab
    }

    private func checkToolbarSwipingTabsFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.swipingTabs
    }

    private func checkToolbarTranslucencyFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.translucency
    }

    private func checkToolbarTranslucencyRefactorFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.translucencyRefactor
    }

    private func checkToolbarMinimalAddressBarFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.minimalAddressBar
    }

    private func checkToolbarMiddleButtonCustomizationFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.middleButtonCustomization
    }

    private func checkToolbarNavigationHintFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.navigationHint
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

    private func checkTrendingSearches(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.trendingSearchesFeature.value().enabled
    }

    private func checkVoiceSearchFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.voiceSearchFeature.value().enabled
    }

    private func checkFeltPrivacyFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.feltPrivacyFeature.value()

        switch featureID {
        case .feltPrivacySimplifiedUI: return config.simplifiedUiEnabled
        case .feltPrivacyFeltDeletion: return config.feltDeletionEnabled && config.simplifiedUiEnabled
        default: return false
        }
    }

    private func checkSplashScreenFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        return nimbus.features.splashScreen.value().enabled
    }

    private func checkStartAtHomeFeature(for featureID: NimbusFeatureFlagID, from nimbus: FxNimbus) -> StartAtHome {
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

    private func checkDefaultZoomFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.defaultZoomFeature.value().enabled
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

    private func checkMenuDefaultBrowserBanner(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.menuRefactorFeature.value()
        return config.menuDefaultBrowserBanner
    }

    private func checkMenuRefactor(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.menuRefactorFeature.value().enabled
    }

    private func checkMenuRedesignHint(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.menuRefactorFeature.value()
        return config.menuRedesignHint
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

    private func checkOtherErrorPagesFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().otherErrorPages
    }

    private func checkPrivacyNoticeFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.privacyNoticeFeature.value().enabled
    }

    // MARK: - Summarizer Feature
    private func checkAppleSummarizerFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.appleSummarizerFeature.value()
        return config.enabled
    }

    private func checkAppleSummarizerToolbarEntrypoint(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.appleSummarizerFeature.value()
        return config.toolbarEntrypoint
    }

    private func checkAppleSummarizerShakeGesture(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.appleSummarizerFeature.value().shakeGesture
    }

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

    private func checkMondernOnboardingUIFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().enableModernUi
    }

    private func checkWebEngineIntegrationRefactor(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.webEngineIntegrationRefactor.value().enabled
    }

    private func checkShouldUseBrandRefreshConfigurationFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().shouldUseBrandRefreshConfiguration
    }

    private func checkShouldUseJapanConfigurationFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().shouldUseJapanConfiguration
    }
}
