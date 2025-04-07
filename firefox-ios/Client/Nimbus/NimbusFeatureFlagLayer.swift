// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NimbusFeatureFlagLayer {
    // MARK: - Public methods
    public func checkNimbusConfigFor(_ featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus = FxNimbus.shared
    ) -> Bool {
        switch featureID {
        case .accountSettingsRedux:
            return checkAccountSettingsRedux(from: nimbus)

        case .addressAutofillEdit:
            return checkAddressAutofillEditing(from: nimbus)

        case .appIconSelection:
            return checkAppIconSelectionSetting(from: nimbus)

        case .appearanceMenu:
            return checkAppearanceMenuFeature(from: nimbus)

        case .bookmarksRefactor:
            return checkBookmarksRefactor(from: nimbus)

        case .bottomSearchBar,
                .searchHighlights,
                .isToolbarCFREnabled:
            return checkAwesomeBarFeature(for: featureID, from: nimbus)

        case .cleanupHistoryReenabled:
            return checkCleanupHistoryReenabled(from: nimbus)

        case .contextualHintForToolbar:
            return checkNimbusForContextualHintsFeature(for: featureID, from: nimbus)

        case .deeplinkOptimizationRefactor:
            return checkDeeplinkOptimizationRefactorFeature(from: nimbus)

        case .downloadLiveActivities:
            return checkDownloadLiveActivitiesFeature(from: nimbus)

        case .creditCardAutofillStatus:
            return checkNimbusForCreditCardAutofill(for: featureID, from: nimbus)

        case .jumpBackIn,
                .historyHighlights:
            return checkHomescreenSectionsFeature(for: featureID, from: nimbus)

        case .fakespotFeature:
            return checkFakespotFeature(from: nimbus)

        case .fakespotProductAds:
            return checkFakespotProductAds(from: nimbus)

        case .firefoxSuggestFeature:
            return checkFirefoxSuggestFeature(from: nimbus)

        case .feltPrivacySimplifiedUI, .feltPrivacyFeltDeletion:
            return checkFeltPrivacyFeature(for: featureID, from: nimbus)

        case .fakespotBackInStock:
            return checkProductBackInStockFakespotFeature(from: nimbus)

        case .homepageRebuild:
            return checkHomepageFeature(from: nimbus)

        case .inactiveTabs:
            return checkTabTrayFeature(for: featureID, from: nimbus)

        case .loginAutofill:
            return checkNimbusForLoginAutofill(for: featureID, from: nimbus)

        case .menuRefactor:
            return checkMenuRefactor(from: nimbus)

        case .menuRefactorHint:
            return checkMenuRefactorHint(from: nimbus)

        case .microsurvey:
            return checkMicrosurveyFeature(from: nimbus)

        case .nativeErrorPage:
            return checkNativeErrorPageFeature(from: nimbus)

        case .noInternetConnectionErrorPage:
            return checkNICErrorPageFeature(from: nimbus)

        case .nightMode:
            return checkNightModeFeature(from: nimbus)

        case .pdfRefactor:
            return checkPdfRefactorFeature(from: nimbus)

        case .preferSwitchToOpenTabOverDuplicate:
            return checkPreferSwitchToOpenTabOverDuplicate(from: nimbus)

        case .ratingPromptFeature:
            return checkRatingPromptFeature(from: nimbus)

        case .reduxSearchSettings:
            return checkReduxSearchSettingsFeature(from: nimbus)

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

        case .toolbarNavigationHint:
            return checkToolbarNavigationHintFeature(from: nimbus)

        case .tosFeature:
            return checkTosFeature(from: nimbus)

        case .trackingProtectionRefactor:
            return checkTrackingProtectionRefactor(from: nimbus)

        case .useRustKeychain:
            return checkUseRustKeychainFeature(from: nimbus)

        case .zoomFeature:
            return checkZoomFeature(from: nimbus)
        }
    }

    // MARK: - Private methods
    private func checkAccountSettingsRedux(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.accountSettingsReduxFeature.value().enabled
    }

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
        case .searchHighlights: return config.searchHighlights
        case .isToolbarCFREnabled: return config.position.isToolbarCfrOn
        default: return false
        }
    }

    private func checkHomescreenSectionsFeature(for featureID: NimbusFeatureFlagID,
                                                from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.homescreenFeature.value()
        var nimbusID: HomeScreenSection

        switch featureID {
        case .jumpBackIn: nimbusID = HomeScreenSection.jumpBackIn
        case .historyHighlights: nimbusID = HomeScreenSection.recentExplorations
        default: return false
        }

        guard let status = config.sectionsEnabled[nimbusID] else { return false }

        return status
    }

    private func checkHomepageFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.homepageRebuildFeature.value()
        return config.enabled
    }

    private func checkNimbusForContextualHintsFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.contextualHintFeature.value()
        var nimbusID: ContextualHint

        switch featureID {
        case .contextualHintForToolbar: nimbusID = ContextualHint.toolbarHint
        default: return false
        }

        guard let status = config.featuresEnabled[nimbusID] else { return false }
        return status
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

    private func checkToolbarNavigationHintFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.toolbarRefactorFeature.value()
        return config.navigationHint
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

    public func checkNimbusForCreditCardAutofill(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus) -> Bool {
            let config = nimbus.features.creditCardAutofill.value()

            switch featureID {
            case .creditCardAutofillStatus: return config.creditCardAutofillStatus
            default: return false
            }
    }

    public func checkNimbusForLoginAutofill(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus) -> Bool {
            let config = nimbus.features.loginAutofill.value()
            switch featureID {
            case .loginAutofill: return config.loginAutofillStatus
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

    private func checkFakespotFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.shopping2023.value()

        return config.status
    }

    private func checkFakespotProductAds(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.shopping2023.value()

        return config.productAds
    }

    private func checkPdfRefactorFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.pdfRefactorFeature.value().enabled
    }

    private func checkProductBackInStockFakespotFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.shopping2023.value()

        return config.backInStockReporting
    }

    private func checkPreferSwitchToOpenTabOverDuplicate(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.homescreenFeature.value().preferSwitchToOpenTab
    }

    private func checkRatingPromptFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.ratingPromptFeature.value().enabled
    }

    private func checkAddressAutofillEditing(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.addressAutofillEdit.value()

        return config.status
    }

    private func checkAppIconSelectionSetting(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.appIconSelectionFeature.value()
        return config.enabled
    }

    private func checkAppearanceMenuFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.appearanceMenuFeature.value()
        return config.status
    }

    private func checkDeeplinkOptimizationRefactorFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.deeplinkOptimizationRefactorFeature.value()
        return config.enabled
    }

    private func checkDownloadLiveActivitiesFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.downloadLiveActivitiesFeature.value().enabled
    }

    private func checkZoomFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.zoomFeature.value()

        return config.status
    }

    private func checkFirefoxSuggestFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.firefoxSuggestFeature.value()

        return config.status
    }

    private func checkReduxSearchSettingsFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.reduxSearchSettingsFeature.value()
        return config.enabled
    }

    private func checkMenuRefactor(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.menuRefactorFeature.value().enabled
    }

    private func checkMenuRefactorHint(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.menuRefactorFeature.value()
        return config.menuHint
    }

    private func checkMicrosurveyFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.microsurveyFeature.value()

        return config.enabled
    }

    private func checkNightModeFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.nightModeFeature.value()

        return config.enabled
    }

    private func checkNativeErrorPageFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().enabled
    }

    private func checkNICErrorPageFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.nativeErrorPageFeature.value().noInternetConnectionError
    }

    private func checkUseRustKeychainFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.rustKeychainRefactor.value().rustKeychainEnabled
    }
}
