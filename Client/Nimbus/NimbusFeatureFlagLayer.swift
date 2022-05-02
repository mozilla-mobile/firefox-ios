// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

class NimbusFeatureFlagLayer {

//    struct HomescreenFeatures {
//        private let jumpBackIn: Bool
//        private let pocket: Bool
//        private let recentlySaved: Bool
//        private let historyHighlights: Bool
//        private let topSites: Bool
//        private let librarySection: Bool
//
//        init(jumpBackIn: Bool = true,
//             pocket: Bool = true,
//             recentlySaved: Bool = true,
//             historyHighlights: Bool = false,
//             topSites: Bool = true,
//             librarySection: Bool = false) {
//
//            self.jumpBackIn = jumpBackIn
//            self.pocket = pocket
//            self.recentlySaved = recentlySaved
//            self.historyHighlights = historyHighlights
//            self.topSites = topSites
//            self.librarySection = librarySection
//        }
//
//        func getValue(for featureID: NimbusFeatureFlagID) -> Bool {
//            switch featureID {
//            case .jumpBackIn: return jumpBackIn
//            case .pocket: return pocket
//            case .recentlySaved: return recentlySaved
//            case .historyHighlights: return historyHighlights
//            case .topSites: return topSites
//            case .librarySection: return librarySection
//            default: return false
//            }
//        }
//    }
//
//    struct TabTrayFeatures {
//        private let inactiveTabs: Bool
//
//        init(inactiveTabs: Bool = false) {
//            self.inactiveTabs = inactiveTabs
//        }
//
//        func getValue(for featureID: NimbusFeatureFlagID) -> Bool {
//            switch featureID {
//            case .inactiveTabs: return inactiveTabs
//            default: return false
//            }
//        }
//    }
//
//    struct TabTrayFeatures {
//        private let inactiveTabs: Bool
//
//        init(inactiveTabs: Bool = false) {
//            self.inactiveTabs = inactiveTabs
//        }
//
//        func getValue(for featureID: NimbusFeatureFlagID) -> Bool {
//            switch featureID {
//            case .inactiveTabs: return inactiveTabs
//            default: return false
//            }
//        }
//    }
//
//    struct GeneralAppFeatures {
//        private let bottomSearchBar: Bool
//        private let pullToRefresh: Bool
//        private let reportSiteIssue: Bool
//        private let shakeToRestore: Bool
//        private let wallpapers: Bool
//
//        init(bottomSearchBar: Bool = true,
//             pullToRefresh: Bool = true,
//             reportSiteIssue: Bool = true,
//             shakeToRestore: Bool = false,
//             wallpapers: Bool = true) {
//
//            self.bottomSearchBar = bottomSearchBar
//            self.pullToRefresh = pullToRefresh
//            self.reportSiteIssue = reportSiteIssue
//            self.shakeToRestore = shakeToRestore
//            self.wallpapers = wallpapers
//        }
//
//        func getValue(for featureID: NimbusFeatureFlagID) -> Bool {
//            switch featureID {
//            case .bottomSearchBar: return bottomSearchBar
//            case .pullToRefresh: return pullToRefresh
//            case .reportSiteIssue: return reportSiteIssue
//            case .shakeToRestore: return shakeToRestore
//            case .wallpapers: return wallpapers
//            default: return false
//            }
//        }
//    }

    // MARK: - Properties
//    private var general: GeneralAppFeatures
//    private var homescreen: HomescreenFeatures
//    private var tabTray: TabTrayFeatures

    // MARK: - Initializer
    init() {
//        self.general = GeneralAppFeatures()
//        self.homescreen = HomescreenFeatures()
//        self.tabTray = TabTrayFeatures()
    }

    // MARK: - Public methods
//    public func updateData(from nimbus: FxNimbus = FxNimbus.shared) {
//        fetchGeneralFeatures(from: nimbus)
//        fetchHomescreenFeatures(from: nimbus)
//        fetchTabTrayFeatures(from: nimbus)
//    }

    public func checkNimbusConfigFor(_ featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus = FxNimbus.shared
    ) -> Bool {
        switch featureID {
        case .bottomSearchBar,
                .pullToRefresh,
                .reportSiteIssue,
                .shakeToRestore,
                .wallpapers:
//            return general.getValue(for: featureID)
            return checkGeneralFeature(for: featureID, from: nimbus)

        case .jumpBackIn,
                .pocket,
                .recentlySaved,
                .historyHighlights,
                .topSites,
                .librarySection:
//            return homescreen.getValue(for: featureID)
            return checkHomescreenFeature(for: featureID, from: nimbus)

        case .inactiveTabs:
//            return tabTray.getValue(for: featureID)
            return checkTabTrayFeature(for: featureID, from: nimbus)

        case .historyGroups,
                .tabTrayGroups:
            return checkGroupingFeature(for: featureID, from: nimbus)

        case .sponsoredTiles:
            return checkSponsoredTilesFeature(from: nimbus)

        case .startAtHome:
            return false
        }

    }

    // MARK: - Private methods
    private func checkGeneralFeature(for featureID: NimbusFeatureFlagID,
                                     from nimbus: FxNimbus
    ) -> Bool {

        let config = nimbus.features.generalAppFeatures.value()
        var nimbusID: GeneralAppFeatureId

        switch featureID {
        case .bottomSearchBar: nimbusID = GeneralAppFeatureId.bottomSearchBar
        case .pullToRefresh: nimbusID = GeneralAppFeatureId.pullToRefresh
        case .reportSiteIssue: nimbusID = GeneralAppFeatureId.reportSiteIssue
        case .shakeToRestore: nimbusID = GeneralAppFeatureId.shakeToRestore
        case .wallpapers: nimbusID = GeneralAppFeatureId.wallpapers
        default: return false
        }

        guard let status = config.featureStatus[nimbusID] else { return false }

        return status
    }

    private func checkHomescreenFeature(for featureID: NimbusFeatureFlagID,
                                        from nimbus: FxNimbus
    ) -> Bool {

        let config = nimbus.features.homescreenFeature.value()
        var nimbusID: HomeScreenSection

        switch featureID {
        case .topSites: nimbusID = HomeScreenSection.topSites
        case .librarySection: nimbusID = HomeScreenSection.libraryShortcuts
        case .jumpBackIn: nimbusID = HomeScreenSection.jumpBackIn
        case .recentlySaved: nimbusID = HomeScreenSection.recentlySaved
        case .historyHighlights: nimbusID = HomeScreenSection.recentExplorations
        case .pocket: nimbusID = HomeScreenSection.pocket
        default: return false
        }

        guard let status = config.sectionsEnabled[nimbusID] else { return false }

        return status
    }

    private func checkSponsoredTilesFeature(from nimbus: FxNimbus) -> Bool {

        let config = nimbus.features.homescreenFeature.value()

        return config.sponsoredTiles.status
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

    private func checkGroupingFeature(for featureID: NimbusFeatureFlagID,
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

    private func checkStartAtHomeFeature(for featureID: NimbusFeatureFlagID,
                                         from nimbus: FxNimbus
    ) -> StartAtHomeSetting {

        // ROUX
        let config = nimbus.features.startAtHomeFeature.value()

        return StartAtHomeSetting.afterFourHours
    }

//    private func fetchGeneralFeatures(from nimbus: FxNimbus) {
//        let config = nimbus.features.generalAppFeatures.value()
//
//        guard let bottomSearchBar = config.featureStatus[GeneralAppFeatureId.bottomSearchBar],
//              let pullToRefresh = config.featureStatus[GeneralAppFeatureId.pullToRefresh],
//              let reportSiteIssue = config.featureStatus[GeneralAppFeatureId.reportSiteIssue],
//              let shakeToRestore = config.featureStatus[GeneralAppFeatureId.shakeToRestore],
//              let wallpapers = config.featureStatus[GeneralAppFeatureId.wallpapers]
//        else {
//            general = GeneralAppFeatures()
//            return
//        }
//        let generalFeatures = GeneralAppFeatures(bottomSearchBar: bottomSearchBar,
//                                                 pullToRefresh: pullToRefresh,
//                                                 reportSiteIssue: reportSiteIssue,
//                                                 shakeToRestore: shakeToRestore,
//                                                 wallpapers: wallpapers)
//        general = generalFeatures
//    }
//
//    private func fetchHomescreenFeatures(from nimbus: FxNimbus) {
//        let config = nimbus.features.homescreenFeature.value()
//
//        guard let jumpBackIn = config.sectionsEnabled[HomeScreenSection.jumpBackIn],
//              let pocket = config.sectionsEnabled[HomeScreenSection.pocket],
//              let recentlySaved = config.sectionsEnabled[HomeScreenSection.recentlySaved],
//              let historyHighlights = config.sectionsEnabled[HomeScreenSection.recentExplorations],
//              let topSites = config.sectionsEnabled[HomeScreenSection.topSites],
//              let librarySection = config.sectionsEnabled[HomeScreenSection.libraryShortcuts]
//        else {
//            homescreen = HomescreenFeatures()
//            return
//        }
//
//        let homescreenfeatures = HomescreenFeatures(jumpBackIn: jumpBackIn,
//                                                    pocket: pocket,
//                                                    recentlySaved: recentlySaved,
//                                                    historyHighlights: historyHighlights,
//                                                    topSites: topSites,
//                                                    librarySection: librarySection)
//        homescreen = homescreenfeatures
//    }
//
//    private func fetchTabTrayFeatures(from nimbus: FxNimbus) {
//        let config = nimbus.features.tabTrayFeature.value()
//
//        guard let inactiveTabs = config.sectionsEnabled[TabTraySection.inactiveTabs]
//        else {
//            tabTray = TabTrayFeatures()
//            return
//        }
//
//        let tabTrayFeatures = TabTrayFeatures(inactiveTabs: inactiveTabs)
//        tabTray = tabTrayFeatures
//    }
}
