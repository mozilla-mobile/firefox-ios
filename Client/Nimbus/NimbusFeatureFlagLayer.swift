// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

final class NimbusFeatureFlagLayer {
    // MARK: - Public methods
    public func checkNimbusConfigFor(_ featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus = FxNimbus.shared
    ) -> Bool {
        switch featureID {
        case .addressAutofill:
            return checkAddressAutofill(from: nimbus)

        case .bottomSearchBar,
                .searchHighlights,
                .isToolbarCFREnabled:
            return checkAwesomeBarFeature(for: featureID, from: nimbus)

        case .contextualHintForToolbar:
            return checkNimbusForContextualHintsFeature(for: featureID, from: nimbus)

        case .creditCardAutofillStatus:
            return checkNimbusForCreditCardAutofill(for: featureID, from: nimbus)

        case .jumpBackIn,
                .historyHighlights:
            return checkHomescreenSectionsFeature(for: featureID, from: nimbus)

        case .inactiveTabs:
            return checkTabTrayFeature(for: featureID, from: nimbus)

        case .fakespotFeature:
            return checkFakespotFeature(from: nimbus)

        case .fakespotProductAds:
            return checkFakespotProductAds(from: nimbus)

        case .firefoxSuggestFeature:
            return checkFirefoxSuggestFeature(from: nimbus)

        case .historyGroups:
            return checkGroupingFeature(for: featureID, from: nimbus)

        case .feltPrivacyUI:
            return checkFeltPrivacyUIFeature(from: nimbus)

        case .fakespotBackInStock:
            return checkProductBackInStockFakespotFeature(from: nimbus)

        case .qrCodeCoordinatorRefactor:
            return checkQRCodeCoordinatorRefactorFeature(from: nimbus)

        case .reduxIntegration:
            return checkReduxIntegrationFeature(from: nimbus)

        case .reportSiteIssue:
            return checkGeneralFeature(for: featureID, from: nimbus)

        case .shareSheetChanges,
                .shareToolbarChanges:
            return checkNimbusForShareSheet(for: featureID, from: nimbus)

        case .tabTrayRefactor:
            return checkTabTrayRefactorFeature(from: nimbus)

        case .wallpapers,
                .wallpaperVersion:
            return checkNimbusForWallpapersFeature(using: nimbus)

        case .wallpaperOnboardingSheet:
            return checkNimbusForWallpaperOnboarding(using: nimbus)

        case .zoomFeature:
            return checkZoomFeature(from: nimbus)
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

    private func checkNimbusForWallpapersFeature(using nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.wallpaperFeature.value()

        return config.configuration.status
    }

    private func checkNimbusForWallpaperOnboarding(using nimbus: FxNimbus) -> Bool {
        return nimbus.features.wallpaperFeature.value().onboardingSheet
    }

    public func checkNimbusForWallpapersVersion(using nimbus: FxNimbus = FxNimbus.shared) -> String {
        let config = nimbus.features.wallpaperFeature.value()

        return config.configuration.version.rawValue
    }

    private func checkReduxIntegrationFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.reduxIntegrationFeature.value()
        return config.enabled
    }

    private func checkQRCodeCoordinatorRefactorFeature(from nimbus: FxNimbus) -> Bool {
        return nimbus.features.qrCodeCoordinatorRefactor.value().enabled
    }

    private func checkTabTrayRefactorFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.tabTrayRefactorFeature.value()
        return config.enabled
    }

    private func checkFeltPrivacyUIFeature(from nimbus: FxNimbus ) -> Bool {
        let config = nimbus.features.privateBrowsing.value()
        return config.feltPrivacyEnabled
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

    public func checkNimbusForShareSheet(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus) -> Bool {
            let config = nimbus.features.shareSheet.value()

            switch featureID {
            case .shareSheetChanges: return config.moveActions
            case .shareToolbarChanges: return config.toolbarChanges
            default: return false
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

    private func checkGroupingFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.searchTermGroupsFeature.value()
        var nimbusID: SearchTermGroups

        switch featureID {
        case .historyGroups: nimbusID = SearchTermGroups.historyGroups
        default: return false
        }

        guard let status = config.groupingEnabled[nimbusID] else { return false }

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

    private func checkProductBackInStockFakespotFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.shopping2023.value()

        return config.backInStockReporting
    }

    private func checkAddressAutofill(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.addressAutofillFeature.value()

        return config.status
    }

    private func checkZoomFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.zoomFeature.value()

        return config.status
    }

    private func checkFirefoxSuggestFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.firefoxSuggestFeature.value()

        return config.status
    }
}
