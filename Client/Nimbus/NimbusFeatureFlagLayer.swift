// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

class NimbusFeatureFlagLayer {

    struct HomescreenFeatures {
        private let jumpBackIn: Bool
        private let pocket: Bool
        private let recentlySaved: Bool
        private let historyHighlights: Bool
        private let topSites: Bool
        private let librarySection: Bool

        init(jumpBackIn: Bool = true,
             pocket: Bool = true,
             recentlySaved: Bool = true,
             historyHighlights: Bool = false,
             topSites: Bool = true,
             librarySection: Bool = false) {

            self.jumpBackIn = jumpBackIn
            self.pocket = pocket
            self.recentlySaved = recentlySaved
            self.historyHighlights = historyHighlights
            self.topSites = topSites
            self.librarySection = librarySection
        }

        func getValue(for featureID: FeatureFlagName) -> Bool {
            switch featureID {
            case .jumpBackIn: return jumpBackIn
            case .pocket: return pocket
            case .recentlySaved: return recentlySaved
            case .historyHighlights: return historyHighlights
            case .topSites: return topSites
            case .librarySection: return librarySection
            default: return false
            }
        }
    }

    struct TabTrayFeatures {
        private let inactiveTabs: Bool

        init(inactiveTabs: Bool = false) {
            self.inactiveTabs = inactiveTabs
        }

        func getValue(for featureID: FeatureFlagName) -> Bool {
            switch featureID {
            case .inactiveTabs: return inactiveTabs
            default: return false
            }
        }
    }

    // MARK: - Properties
    private var homescreen: HomescreenFeatures
    private var tabTray: TabTrayFeatures

    // MARK: - Initializer
    init() {
        self.homescreen = HomescreenFeatures()
        self.tabTray = TabTrayFeatures()
    }

    // MARK: - Public methods
    public func updateData(from nimbus: FxNimbus = FxNimbus.shared) {
        fetchHomescreenFeatures(from: nimbus)
        fetchTabTrayFeatures(from: nimbus)
    }

    public func checkNimbusConfigFor(_ featureID: FeatureFlagName) -> Bool {
        switch featureID {
        case .jumpBackIn,
                .pocket,
                .recentlySaved,
                .historyHighlights,
                .topSites,
                .librarySection:
            return homescreen.getValue(for: featureID)

        case .inactiveTabs:
            return tabTray.getValue(for: featureID)

        default: return false
        }
    }

    // MARK: - Public methods
    private func fetchHomescreenFeatures(from nimbus: FxNimbus) {
        let config = nimbus.features.homescreenFeature.value()

        guard let jumpBackIn = config.sectionsEnabled[HomeScreenSection.jumpBackIn],
              let pocket = config.sectionsEnabled[HomeScreenSection.pocket],
              let recentlySaved = config.sectionsEnabled[HomeScreenSection.recentlySaved],
              let historyHighlights = config.sectionsEnabled[HomeScreenSection.recentExplorations],
              let topSites = config.sectionsEnabled[HomeScreenSection.topSites],
              let librarySection = config.sectionsEnabled[HomeScreenSection.libraryShortcuts]
        else {
            homescreen = HomescreenFeatures()
            return
        }

        let homescreenfeatures = HomescreenFeatures(jumpBackIn: jumpBackIn,
                                                    pocket: pocket,
                                                    recentlySaved: recentlySaved,
                                                    historyHighlights: historyHighlights,
                                                    topSites: topSites,
                                                    librarySection: librarySection)
        homescreen = homescreenfeatures
    }

    private func fetchTabTrayFeatures(from nimbus: FxNimbus) {
        let config = nimbus.features.tabTrayFeature.value()

        guard let inactiveTabs = config.sectionsEnabled[TabTraySection.inactiveTabs]
        else {
            tabTray = TabTrayFeatures()
            return
        }

        let tabTrayFeatures = TabTrayFeatures(inactiveTabs: inactiveTabs)
        tabTray = tabTrayFeatures
    }
}
