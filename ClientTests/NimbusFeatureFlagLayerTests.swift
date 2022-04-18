// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// TODO: Reimpelement once FxNimbus is open and able to be mocked properly
//import Foundation
//@testable import Client
//import MozillaAppServices
//import XCTest
//
//class NimbusFeatureFlagLayerTests: XCTestCase {
//
//    override func setUp() {
//        super.setUp()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//    }
//
//    func testInitializationOfDefaultFeatures() {
//        let nimbusLayer = NimbusFeatureFlagLayer()
//
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.jumpBackIn))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.pocket))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.recentlySaved))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.historyHighlights))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.topSites))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.librarySection))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.inactiveTabs))
//    }
//
//    func testInitializedWithTrueValues() {
//        let homescreenSettings = [HomeScreenSection.jumpBackIn: true,
//                                  HomeScreenSection.pocket: true,
//                                  HomeScreenSection.libraryShortcuts: true,
//                                  HomeScreenSection.topSites: true,
//                                  HomeScreenSection.recentExplorations: true,
//                                  HomeScreenSection.recentlySaved: true]
//
//        let tabTraySettings = [TabTraySection.inactiveTabs: true]
//        let features = initializeFeaturesWith(homescreenSettings, and: tabTraySettings)
//
//        let nimbusLayer = NimbusFeatureFlagLayer(with: features)
//        nimbusLayer.updateData()
//
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.jumpBackIn))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.pocket))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.recentlySaved))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.historyHighlights))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.topSites))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.librarySection))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.inactiveTabs))
//    }
//
//    func testUpdatingFeaturesOnRestart() {
//        var homescreenSettings = [HomeScreenSection.jumpBackIn: true,
//                                  HomeScreenSection.pocket: true,
//                                  HomeScreenSection.libraryShortcuts: true,
//                                  HomeScreenSection.topSites: true,
//                                  HomeScreenSection.recentExplorations: true,
//                                  HomeScreenSection.recentlySaved: true]
//
//        var tabTraySettings = [TabTraySection.inactiveTabs: true]
//        let features = initializeFeaturesWith(homescreenSettings, and: tabTraySettings)
//
//        let nimbusLayer = NimbusFeatureFlagLayer(with: features)
//        nimbusLayer.updateData()
//
//        // New Nimbus configuration downloaded simulation
//        homescreenSettings[HomeScreenSection.pocket] = false
//        homescreenSettings[HomeScreenSection.libraryShortcuts] = false
//        homescreenSettings[HomeScreenSection.recentExplorations] = false
//        tabTraySettings[TabTraySection.inactiveTabs] = false
//
//        features.homescreen = {
//            FeatureHolder({ FxNimbus.shared.api }, "homescreen") { (variables) in
//                let homescreen = Homescreen(variables)
//                homescreen.sectionsEnabled = homescreenSettings
//                return homescreen
//            }
//        }()
//
//        features.tabTrayFeature = {
//            FeatureHolder({ FxNimbus.shared.api }, "tabTrayFeature") { (variables) in
//                let tabTrayFeature = TabTrayFeature(variables)
//                tabTrayFeature.sectionsEnabled = tabTraySettings
//                return tabTrayFeature
//            }
//        }()
//
//        nimbusLayer.updateData()
//
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.jumpBackIn))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.pocket))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.recentlySaved))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.historyHighlights))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.topSites))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.librarySection))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.inactiveTabs))
//    }
//
//    func testIncompleteData() {
//        let homescreenSettings = [HomeScreenSection.jumpBackIn: true,
//                                  HomeScreenSection.recentlySaved: true]
//
//        let features = Features()
//        features.homescreen = {
//            FeatureHolder({ FxNimbus.shared.api }, "homescreen") { (variables) in
//                let homescreen = Homescreen(variables)
//                homescreen.sectionsEnabled = homescreenSettings
//                return homescreen
//            }
//        }()
//
//        let nimbusLayer = NimbusFeatureFlagLayer(with: features)
//        nimbusLayer.updateData()
//
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.jumpBackIn))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.pocket))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.recentlySaved))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.historyHighlights))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.topSites))
//        XCTAssertFalse(nimbusLayer.checkNimbusConfigFor(.librarySection))
//        XCTAssertTrue(nimbusLayer.checkNimbusConfigFor(.inactiveTabs))
//    }
//
//    private func initializeFeaturesWith(
//        _ homescreenSettings: [HomeScreenSection: Bool],
//        and tabTraySettings: [TabTraySection: Bool]
//    ) -> Features {
//
//        let features = Features()
//
//        features.homescreen = {
//            FeatureHolder({ FxNimbus.shared.api }, "homescreen") { (variables) in
//                let homescreen = Homescreen(variables)
//                homescreen.sectionsEnabled = homescreenSettings
//                return homescreen
//            }
//        }()
//
//        features.tabTrayFeature = {
//            FeatureHolder({ FxNimbus.shared.api }, "tabTrayFeature") { (variables) in
//                let tabTrayFeature = TabTrayFeature(variables)
//                tabTrayFeature.sectionsEnabled = tabTraySettings
//                return tabTrayFeature
//            }
//        }()
//
//        return features
//    }
//}
