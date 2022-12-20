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
        case .pullToRefresh,
                .reportSiteIssue,
                .shakeToRestore:
            return checkGeneralFeature(for: featureID, from: nimbus)

        case .bottomSearchBar,
                .searchHighlights,
            // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-5362
            // This is a temporary workaround for the toolbar experiment hack
                .contextualHintForToolbar:
            return checkAwesomeBarFeature(for: featureID, from: nimbus)

        case .jumpBackIn,
                .pocket,
                .recentlySaved,
                .historyHighlights,
                .topSites:
            return checkHomescreenSectionsFeature(for: featureID, from: nimbus)

//        case .contextualHintForToolbar:
        case .contextualHintForJumpBackInSyncedTab:
            return checkNimbusForContextualHintsFeature(for: featureID, from: nimbus)

        case .jumpBackInSyncedTab:
            return checkNimbusForJumpBackInSyncedTabFeature(using: nimbus)

        case .sponsoredPocket:
            return checkNimbusForPocketSponsoredStoriesFeature(using: nimbus)

        case .inactiveTabs:
            return checkTabTrayFeature(for: featureID, from: nimbus)

        case .historyGroups,
                .tabTrayGroups:
            return checkGroupingFeature(for: featureID, from: nimbus)

        case .onboardingUpgrade,
                .onboardingFreshInstall:
            return checkNimbusForOnboardingFeature(for: featureID, from: nimbus)

        case .sponsoredTiles:
            return checkSponsoredTilesFeature(from: nimbus)

        case .startAtHome:
            return checkNimbusConfigForStartAtHome(using: nimbus) != .disabled

        case .wallpapers,
                .wallpaperVersion:
            return checkNimbusForWallpapersFeature(using: nimbus)

        case .wallpaperOnboardingSheet:
            return checkNimbusForWallpaperOnboarding(using: nimbus)

        case .shareSheetChanges,
                .shareToolbarChanges:
            return checkNimbusForShareSheet(for: featureID, from: nimbus)
        case .creditCardAutofillStatus:
            return checkNimbusForCreditCardAutofill(for: featureID, from: nimbus)
        }
    }

    public func checkNimbusConfigForStartAtHome(using nimbus: FxNimbus = FxNimbus.shared) -> StartAtHomeSetting {
        let config = nimbus.features.startAtHomeFeature.value()
        let nimbusSetting = config.setting

        switch nimbusSetting {
        case .disabled: return .disabled
        case .afterFourHours: return .afterFourHours
        case .always: return .always
        }
    }

    // MARK: - Private methods
    private func checkGeneralFeature(for featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.generalAppFeatures.value()

        switch featureID {
        case .pullToRefresh: return config.pullToRefresh.status
        case .reportSiteIssue: return config.reportSiteIssue.status
        case .shakeToRestore: return config.shakeToRestore.status
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
        case .contextualHintForToolbar: return config.position.isToolbarCfrOn
        default: return false
        }
    }

    private func checkHomescreenSectionsFeature(for featureID: NimbusFeatureFlagID,
                                                from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.homescreenFeature.value()
        var nimbusID: HomeScreenSection

        switch featureID {
        case .topSites: nimbusID = HomeScreenSection.topSites
        case .jumpBackIn: nimbusID = HomeScreenSection.jumpBackIn
        case .recentlySaved: nimbusID = HomeScreenSection.recentlySaved
        case .historyHighlights: nimbusID = HomeScreenSection.recentExplorations
        case .pocket: nimbusID = HomeScreenSection.pocket
        default: return false
        }

        guard let status = config.sectionsEnabled[nimbusID] else { return false }

        return status
    }

    private func checkNimbusForJumpBackInSyncedTabFeature(using nimbus: FxNimbus) -> Bool {
        return nimbus.features.homescreenFeature.value().jumpBackInSyncedTab
    }

    private func checkNimbusForContextualHintsFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.contextualHintFeature.value()
        var nimbusID: ContextualHint

        switch featureID {
        case .contextualHintForJumpBackInSyncedTab: nimbusID = ContextualHint.jumpBackInSyncedTabContextualHint
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

    private func checkNimbusForPocketSponsoredStoriesFeature(using nimbus: FxNimbus) -> Bool {
        return nimbus.features.homescreenFeature.value().pocketSponsoredStories
    }

    private func checkSponsoredTilesFeature(from nimbus: FxNimbus) -> Bool {
        let config = nimbus.features.homescreenFeature.value()
        return config.sponsoredTiles.status
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

    private func checkNimbusForOnboardingFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        let config = nimbus.features.onboardingFeature.value()

        switch featureID {
        case .onboardingUpgrade: return config.upgradeFlow
        case .onboardingFreshInstall: return config.firstRunFlow
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
        case .tabTrayGroups: nimbusID = SearchTermGroups.tabTrayGroups
        default: return false
        }

        guard let status = config.groupingEnabled[nimbusID] else { return false }

        return status
    }
}
