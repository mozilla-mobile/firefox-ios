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
                .searchHighlights:
            return checkAwesomeBarFeature(for: featureID, from: nimbus)

        case .jumpBackIn,
                .pocket,
                .recentlySaved,
                .historyHighlights,
                .topSites:
            return checkHomescreenSectionsFeature(for: featureID, from: nimbus)

        case .jumpBackInSyncedTab:
            return checkNimbusForJumpBackInSyncedTabFeature(using: nimbus)

        case .contextualHintForJumpBackIn,
                .contextualHintForJumpBackInSyncedTab,
                .contextualHintForToolbar:
            return checkNimbusForContextualHintsFeature(for: featureID, from: nimbus)

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
        }
    }

    public func checkNimbusConfigForStartAtHome(using nimbus: FxNimbus = FxNimbus.shared) -> StartAtHomeSetting {
        /* Ecosia: never start at home
        let config = nimbus.features.startAtHomeFeature.value()
        let nimbusSetting = config.setting

        switch nimbusSetting {
        case .disabled: return .disabled
        case .afterFourHours: return .afterFourHours
        case .always: return .always
        }
         */
        return .disabled
    }

    // MARK: - Private methods
    private func checkGeneralFeature(for featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus
    ) -> Bool {
        /* Ecosia: hard code flags
        let config = nimbus.features.generalAppFeatures.value()
        */
        switch featureID {
        case .pullToRefresh: return true // Ecosia // config.pullToRefresh.status
        case .reportSiteIssue: return false // Ecosia // config.reportSiteIssue.status
        case .shakeToRestore: return false // Ecosia // config.shakeToRestore.status
        default: return false
        }
    }

    private func checkAwesomeBarFeature(for featureID: NimbusFeatureFlagID,
                                        from nimbus: FxNimbus
    ) -> Bool {
        /* Ecosia: hard code flags
        let config = nimbus.features.search.value().awesomeBar
         */
        switch featureID {
        case .bottomSearchBar: return true // Ecosia // config.position.isPositionFeatureEnabled
        case .searchHighlights: return true // Ecosia // config.searchHighlights
        default: return false
        }
    }

    private func checkHomescreenSectionsFeature(for featureID: NimbusFeatureFlagID,
                                                from nimbus: FxNimbus
    ) -> Bool {
        /* Ecosia: hard code flags
        let config = nimbus.features.homescreenFeature.value()
        var nimbusID: HomeScreenSection
         */

        switch featureID {
        case .topSites: return true // Ecosia // nimbusID = HomeScreenSection.topSites
        case .jumpBackIn: return false // Ecosia //  nimbusID = HomeScreenSection.jumpBackIn
        case .recentlySaved: return false // Ecosia //nimbusID = HomeScreenSection.recentlySaved
        case .historyHighlights: return false // Ecosia //nimbusID = HomeScreenSection.recentExplorations
        case .pocket: return false // Ecosia //nimbusID = HomeScreenSection.pocket
        default: return false
        }

        /* Ecosia
        guard let status = config.sectionsEnabled[nimbusID] else { return false }

        return status
         */
    }

    private func checkNimbusForJumpBackInSyncedTabFeature(using nimbus: FxNimbus) -> Bool {
        /* Ecosia: deactivate JBI
        return nimbus.features.homescreenFeature.value().jumpBackInSyncedTab
         */
        false
    }

    private func checkNimbusForContextualHintsFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        /* Ecosia: hard code flags
        let config = nimbus.features.contextualHintFeature.value()
        var nimbusID: ContextualHint
         */
        switch featureID {
        case .contextualHintForToolbar: return true // Ecosia // nimbusID = ContextualHint.toolbarContextualHint
        case .contextualHintForJumpBackIn:  return false // Ecosia //nimbusID = ContextualHint.jumpBackInContextualHint
        case .contextualHintForJumpBackInSyncedTab:  return false // Ecosia //nimbusID = ContextualHint.jumpBackInSyncedTabContextualHint
        default: return false
        }

        /* Ecosia
        guard let status = config.featuresEnabled[nimbusID] else { return false }
        return status
         */
    }

    private func checkNimbusForWallpapersFeature(using nimbus: FxNimbus) -> Bool {
        /* Ecosia
        let config = nimbus.features.wallpaperFeature.value()

        return config.configuration.status
         */
        false
    }

    private func checkNimbusForWallpaperOnboarding(using nimbus: FxNimbus) -> Bool {
        /* Ecosia
        return nimbus.features.wallpaperFeature.value().onboardingSheet
         */
        false
    }

    /* Ecosia
    public func checkNimbusForWallpapersVersion(using nimbus: FxNimbus = FxNimbus.shared) -> String {
        let config = nimbus.features.wallpaperFeature.value()

        return config.configuration.version.rawValue
    }
     */

    private func checkNimbusForPocketSponsoredStoriesFeature(using nimbus: FxNimbus) -> Bool {
        /* Ecosia
        return nimbus.features.homescreenFeature.value().pocketSponsoredStories
         */
        false
    }

    private func checkSponsoredTilesFeature(from nimbus: FxNimbus) -> Bool {
        /* Ecosia
        let config = nimbus.features.homescreenFeature.value()
        return config.sponsoredTiles.status
         */
        false
    }

    private func checkNimbusForOnboardingFeature(
        for featureID: NimbusFeatureFlagID,
        from nimbus: FxNimbus
    ) -> Bool {
        /* Ecosia: no FF onboarding
        let config = nimbus.features.onboardingFeature.value()

        switch featureID {
        case .onboardingUpgrade: return config.upgradeFlow
        case .onboardingFreshInstall: return config.firstRunFlow
        default: return false
        }
         */
        false
    }

    private func checkTabTrayFeature(for featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus
    ) -> Bool {
        /* Ecosia
        let config = nimbus.features.tabTrayFeature.value()
        var nimbusID: TabTraySection
         */

        switch featureID {
        case .inactiveTabs: return true // Ecosia // nimbusID = TabTraySection.inactiveTabs
        default: return false
        }
        /* Ecosia
        guard let status = config.sectionsEnabled[nimbusID] else { return false }

        return status
         */
    }

    private func checkGroupingFeature(for featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus
    ) -> Bool {
        /* Ecosia: disable grouping
        let config = nimbus.features.searchTermGroupsFeature.value()
        var nimbusID: SearchTermGroups

        switch featureID {
        case .historyGroups: nimbusID = SearchTermGroups.historyGroups
        case .tabTrayGroups: nimbusID = SearchTermGroups.tabTrayGroups
        default: return false
        }

        guard let status = config.groupingEnabled[nimbusID] else { return false }

        return status
         */
        false
    }
}
