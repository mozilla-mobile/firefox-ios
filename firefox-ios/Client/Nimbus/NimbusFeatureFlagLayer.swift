// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NimbusFeatureFlagLayer {
    // MARK: - Public methods
    public func checkNimbusConfigFor(_ featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus = FxNimbus.shared
    ) -> Bool {
        // For better code readability, please keep in alphabetical order by NimbusFeatureFlagID
        switch featureID {
        case .addressAutofillEdit:
            return checkAddressAutofillEditing(from: nimbus)

        case .appearanceMenu:
            return checkAppearanceMenuFeature(from: nimbus)

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

        case .firefoxSuggestFeature:
            return checkFirefoxSuggestFeature(from: nimbus)

        case .feltPrivacySimplifiedUI, .feltPrivacyFeltDeletion:
            return checkFeltPrivacyFeature(for: featureID, from: nimbus)

        case .hntSponsoredShortcuts:
            return checkHNTSponsoredShortcutsFeature(from: nimbus)

        case .hntTopSitesVisualRefresh:
            return checkHntTopSitesVisualRefreshFeature(from: nimbus)

        case .homepageRedesign:
            return checkHomepageRedesignFeature(from: nimbus)

        case .homepageSearchBar:
            return checkHomepageSearchBarFeature(from: nimbus)

        case .homepageShortcutsLibrary:
            return checkHomepageShortcutsLibraryFeature(from: nimbus)

        case .homepageStoriesRedesign:
            return checkHomepageStoriesRedesignFeature(from: nimbus)

        case .homepageDiscoverMoreButton, .homepageDiscoverMoreExperience:
            return checkHomepageDiscoverMoreFeature(for: featureID, from: nimbus)

        case .homepageRebuild:
            return checkHomepageFeature(from: nimbus)

        case .inactiveTabs:
            return checkTabTrayFeature(for: featureID, from: nimbus)

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

        case .loginsVerificationEnabled:
            return checkLoginsVerificationFeature(from: nimbus)

        case .nativeErrorPage:
            return checkNativeErrorPageFeature(from: nimbus)

        case .noInternetConnectionErrorPage:
            return checkNICErrorPageFeature(from: nimbus)

        case .pdfRefactor:
            return checkPdfRefactorFeature(from: nimbus)

        case .reportSiteIssue:
            return checkGeneralFeature(for: featureID, from: nimbus)

        case .searchEngineConsolidation:
            return checkSearchEngineConsolidationFeature(from: nimbus)

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

        case .hostedSummarizerToolbarEntrypoint:
           return checkHostedSummarizerToolbarEntrypoint(from: nimbus)

        case .hostedSummarizerShakeGesture:
           return checkHostedSummarizerShakeGesture(from: nimbus)

        case .toolbarRefactor:
            return checkToolbarRefactorFeature(from: nimbus)

        case .unifiedAds:
            return checkUnifiedAdsFeature(from: nimbus)

        case .unifiedSearch:
            return checkUnifiedSearchFeature(from: nimbus)

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

        case .toolbarMinimalAddressBar:
            return checkToolbarMinimalAddressBarFeature(from: nimbus)

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

        case .revertUnsafeContinuationsRefactor:
            return checkRevertUnsafeContinuationsRefactor(from: nimbus)

        case .updatedPasswordManager:
            return checkUpdatedPasswordManagerFeature(from: nimbus)

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

    private func checkHntTopSitesVisualRefreshFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.hntTopSitesVisualRefreshFeature.value().enabled
    }

    private func checkHomepageRedesignFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homepageRedesignFeature.value().enabled
    }

    private func checkHomepageSearchBarFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homepageRedesignFeature.value().searchBar
    }

    private func checkHomepageShortcutsLibraryFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homepageRedesignFeature.value().shortcutsLibrary
    }

    private func checkHomepageStoriesRedesignFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homepageRedesignFeature.value().storiesRedesign
    }

    private func checkHomepageDiscoverMoreFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        let feature = nimbus.features.homepageRedesignFeature.value().discoverMoreFeatureConfiguration

        switch featureID {
        case .homepageDiscoverMoreButton:
            return feature.showDiscoverMoreButton
        case .homepageDiscoverMoreExperience:
            return feature.discoverMoreV1Experience
        default:
            return false
        }
    }

    private func checkHomepageFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.homepageRebuildFeature.value()
        return config.enabled
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

    private func checkUnifiedAdsFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.unifiedAds.value()
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

    private func checkToolbarMinimalAddressBarFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.minimalAddressBar
    }

    private func checkToolbarNavigationHintFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.navigationHint
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

    private func checkSearchEngineConsolidationFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.searchEngineConsolidationFeature.value()
        return config.enabled
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

    private func checkTabTrayFeature(for featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.tabTrayFeature.value()
        var nimbusID: TabTraySection

        switch featureID {
        case .inactiveTabs: nimbusID = TabTraySection.inactiveTabs
        default: return false
        }

        guard let status = config.sectionsEnabled[nimbusID] else { return false }

        return status
    }

    private func checkPdfRefactorFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.pdfRefactorFeature.value().enabled
    }

    private func checkAddressAutofillEditing(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.addressAutofillEdit.value()

        return config.status
    }

    private func checkAppearanceMenuFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.appearanceMenuFeature.value()
        return config.status
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

    private func checkLoginsVerificationFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.loginsVerification.value().loginsVerificationEnabled
    }

    private func checkNativeErrorPageFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().enabled
    }

    private func checkNICErrorPageFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().noInternetConnectionError
    }

    private func checkRevertUnsafeContinuationsRefactor(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.revertUnsafeContinuationsRefactor.value()
        return config.enabled
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

    private func checkUpdatedPasswordManagerFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.updatedPasswordManagerFeature.value()
        return config.status
    }

    private func checkMondernOnboardingUIFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.onboardingFrameworkFeature.value().enableModernUi
    }

    private func checkWebEngineIntegrationRefactor(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.webEngineIntegrationRefactor.value().enabled
    }
}
