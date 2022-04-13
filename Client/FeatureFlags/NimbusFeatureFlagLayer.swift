// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class NimbusFeatureFlagLayer {

    struct HomescreenFeatures {
        private let jumpBackIn: Bool

        init(jumpBackIn: Bool = false) {
            self.jumpBackIn = jumpBackIn
        }

        func getValue(for: FeatureFlagName) -> Bool {
            switch FeatureFlagName {
            case .jumpBackIn: return jumpBackIn
            default: return false
            }
        }
    }

    struct TabTrayFeatures {
        private let inactiveTabs: Bool

        init(inactiveTabs: Bool = false) {
            self.inactiveTabs = inactiveTabs
        }

        func getValue(for: FeatureFlagName) -> Bool {
            switch FeatureFlagName {
            case .inactiveTabs: return inactiveTabs
            default: return false
            }
        }
    }

    // MARK: - Properties
    var homescreen: HomescreenFeatures
    var tabTray: TabTrayFeatures
    private var nimbus: FxNimbus

    // MARK: - Initializer
    init(with nimbus: FxNimbus = FxNimbus.shared) {
        self.nimbus = nimbus
        self.homescreen = HomescreenFeatures()
        self.tabTray = TabTrayFeatures()
    }

    // MARK: - Public methods
    public func updateData() {
        fetchHomescreenFeatures()
        fetchTabTrayFeatures()
    }

    // MARK: - Public methods
    private func fetchHomescreenFeatures() {
        let nimbusHomescreenConfig = nimbus.features.homescreen.value()

        guard let jumpBackIn = nimbusHomescreenConfig.sectionsEnabled[HomeScreenSection.jumpBackIn]
        else {
            homescreen = HomescreenFeatures()
            return
        }

        let homescreenfeatures = HomescreenFeatures(jumpBackIn: jumpBackIn)
        homescreen = homescreenfeatures
    }

    private func fetchTabTrayFeatures() {
        let nimbusHomescreenConfig = nimbus.features.tabTrayFeature.value()

        guard let inactiveTabs = nimbusHomescreenConfig.sectionsEnabled[TabTraySection.inactiveTabs]
        else {
            tabTray = TabTrayFeatures()
            return
        }

        let tabTrayFeatures = TabTrayFeatures(inactiveTabs: inactiveTabs)
        tabTray = tabTrayFeatures
    }
}
