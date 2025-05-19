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

        case .bookmarksRefactor:
            return checkBookmarksRefactor(from: nimbus)

        case .bottomSearchBar:
            return checkAwesomeBarFeature(for: featureID, from: nimbus)

        case .cleanupHistoryReenabled:
            return checkCleanupHistoryReenabled(from: nimbus)

        case .deeplinkOptimizationRefactor:
            return checkDeeplinkOptimizationRefactorFeature(from: nimbus)

        case .downloadLiveActivities:
            return checkDownloadLiveActivitiesFeature(from: nimbus)

        case .firefoxSuggestFeature:
            return checkFirefoxSuggestFeature(from: nimbus)

        case .feltPrivacySimplifiedUI, .feltPrivacyFeltDeletion:
            return checkFeltPrivacyFeature(for: featureID, from: nimbus)

        case .hntContentFeedRefresh:
            return checkHNTContentFeedRefreshFeature(from: nimbus)

        case .hntTopSitesVisualRefresh:
            return checkHntTopSitesVisualRefreshFeature(from: nimbus)

        case .homepageRebuild:
            return checkHomepageFeature(from: nimbus)

        case .inactiveTabs:
            return checkTabTrayFeature(for: featureID, from: nimbus)

        case .menuRefactor:
            return checkMenuRefactor(from: nimbus)

        case .menuRefactorHint:
            return checkMenuRefactorHint(from: nimbus)

        case .menuRedesign:
            return checkMenuRedesign(from: nimbus)

        case .microsurvey:
            return checkMicrosurveyFeature(from: nimbus)

        case .loginsVerificationEnabled:
            return checkLoginsVerificationFeature(from: nimbus)

        case .nativeErrorPage:
            return checkNativeErrorPageFeature(from: nimbus)

        case .noInternetConnectionErrorPage:
            return checkNICErrorPageFeature(from: nimbus)

        case .pdfRefactor:
            return checkPdfRefactorFeature(from: nimbus)

        case .ratingPromptFeature:
            return checkRatingPromptFeature(from: nimbus)

        case .reportSiteIssue:
            return checkGeneralFeature(for: featureID, from: nimbus)

        case .searchEngineConsolidation:
            return checkSearchEngineConsolidationFeature(from: nimbus)

        case .sentFromFirefox:
            return checkSentFromFirefoxFeature(from: nimbus)

        case .sentFromFirefoxTreatmentA:
            return checkSentFromFirefoxFeatureTreatmentA(from: nimbus)

        case .splashScreen:
            return checkSplashScreenFeature(for: featureID, from: nimbus)

        case .startAtHome:
            return checkStartAtHomeFeature(for: featureID, from: nimbus) != .disabled

        case .toolbarRefactor:
            return checkToolbarRefactorFeature(from: nimbus)

        case .unifiedAds:
            return checkUnifiedAdsFeature(from: nimbus)

        case .unifiedSearch:
            return checkUnifiedSearchFeature(from: nimbus)

        case .tabAnimation:
            return checkTabAnimationFeature(from: nimbus)

        case .tabTrayUIExperiments:
            return checkTabTrayUIExperiments(from: nimbus)

        case .toolbarOneTapNewTab:
            return checkToolbarOneTapNewTabFeature(from: nimbus)

        case .toolbarSwipingTabs:
            return checkToolbarSwipingTabsFeature(from: nimbus)

        case .toolbarTranslucency:
            return checkToolbarTranslucencyFeature(from: nimbus)

        case .toolbarNavigationHint:
            return checkToolbarNavigationHintFeature(from: nimbus)

        case .toolbarUpdateHint:
            return checkToolbarUpdateHintFeature(from: nimbus)

        case .tosFeature:
            return checkTosFeature(from: nimbus)

        case .trackingProtectionRefactor:
            return checkTrackingProtectionRefactor(from: nimbus)

        case .revertUnsafeContinuationsRefactor:
            return checkRevertUnsafeContinuationsRefactor(from: nimbus)

        case .useRustKeychain:
            return checkUseRustKeychainFeature(from: nimbus)

        case .updatedPasswordManager:
            return checkUpdatedPasswordManagerFeature(from: nimbus)
        }
    }

    // MARK: - Private methods
    private func checkBookmarksRefactor(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.bookmarkRefactorFeature.value().enabled
    }

    private func checkCleanupHistoryReenabled(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.cleanupHistoryReenabled.value()
        return config.enabled
    }

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

    public func checkHNTContentFeedRefreshFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.hntContentFeedCleanupFeature.value().enabled
    }

    public func checkHntTopSitesVisualRefreshFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.hntTopSitesVisualRefreshFeature.value().enabled
    }

    private func checkHomepageFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.homepageRebuildFeature.value()
        return config.enabled
    }

    private func checkTabAnimationFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.tabTrayUiExperiments.value()
        return config.animationFeature
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

    private func checkRatingPromptFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.ratingPromptFeature.value().enabled
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

    private func checkDownloadLiveActivitiesFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.downloadLiveActivitiesFeature.value().enabled
    }

    private func checkFirefoxSuggestFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.firefoxSuggestFeature.value()

        return config.status
    }

    private func checkMenuRefactor(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.menuRefactorFeature.value().enabled
    }

    private func checkMenuRefactorHint(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.menuRefactorFeature.value()
        return config.menuHint
    }

    private func checkMenuRedesign(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.menuRefactorFeature.value()
        return config.menuRedesign
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

    private func checkUseRustKeychainFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.rustKeychainRefactor.value().rustKeychainEnabled
    }

    private func checkUpdatedPasswordManagerFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.updatedPasswordManagerFeature.value()
        return config.status
    }
}
