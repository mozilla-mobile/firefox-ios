/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client

class SearchSettingsUITests: KIFTestCase {
    /*
    override func setUp() {
        super.setUp()
        BrowserUtils.dismissFirstRunUI(tester())
    }
    
    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
    
    func testDefaultSearchEngine() {
        SearchUtils.navigateToSearchSettings(tester())
        SearchUtils.selectDefaultSearchEngineName(tester(), engineName: "Yahoo")
        XCTAssertEqual("Yahoo", SearchUtils.getDefaultSearchEngineName(tester()))
        SearchUtils.selectDefaultSearchEngineName(tester(), engineName: "Amazon.com")
        XCTAssertEqual("Amazon.com", SearchUtils.getDefaultSearchEngineName(tester()))
        SearchUtils.selectDefaultSearchEngineName(tester(), engineName: "Yahoo")
        XCTAssertEqual("Yahoo", SearchUtils.getDefaultSearchEngineName(tester()))
        SearchUtils.navigateFromSearchSettings(tester())
    }

    func testCustomSearchEngineIsEditable() {
        navigateToSettings()
        let defaultEngine = SearchUtils.getDefaultEngine()
        let youTubeEngine = SearchUtils.youTubeSearchEngine()
        SearchUtils.addCustomSearchEngine(youTubeEngine)
        tester().tapView(withAccessibilityLabel: "Search, \(defaultEngine?.shortName)")
        tester().waitForView(withAccessibilityLabel: "Edit", traits: UIAccessibilityTraitButton)
        SearchUtils.removeCustomSearchEngine(youTubeEngine)
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testCustomSearchEngineAsDefaultIsNotEditable() {
        navigateToSettings()
        let defaultEngine = SearchUtils.getDefaultEngine()
        let youTubeEngine = SearchUtils.youTubeSearchEngine()
        SearchUtils.addCustomSearchEngine(youTubeEngine)
        tester().tapView(withAccessibilityLabel: "Search, \(defaultEngine?.shortName)")
        tester().waitForView(withAccessibilityLabel: "Edit", traits: UIAccessibilityTraitButton)

        // Change default search to custom
        tester().tapView(withAccessibilityLabel: "Default Search Engine")
        tester().tapView(withAccessibilityLabel: "YouTube")

        // Verify that edit button is not enabled
        tester().waitForView(withAccessibilityLabel: "Edit", traits: UIAccessibilityTraitButton | UIAccessibilityTraitNotEnabled)

        // Reset default search engine
        tester().tapView(withAccessibilityLabel: "Default Search Engine")
        tester().tapView(withAccessibilityLabel: "Yahoo")

        // Exit test
        SearchUtils.removeCustomSearchEngine(youTubeEngine)
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testNavigateToSearchPickerTurnsOffEditing() {
        navigateToSettings()
        let defaultEngine = SearchUtils.getDefaultEngine()
        let youTubeEngine = SearchUtils.youTubeSearchEngine()
        SearchUtils.addCustomSearchEngine(youTubeEngine)
        tester().tapView(withAccessibilityLabel: "Search, \(defaultEngine?.shortName)")

        // Go from edit -> editing and check for done state
        tester().tapView(withAccessibilityLabel: "Edit", traits: UIAccessibilityTraitButton)
        tester().waitForView(withAccessibilityLabel: "Done", traits: UIAccessibilityTraitButton)

        // Navigate to the search engine picker and back
        tester().tapView(withAccessibilityLabel: "Default Search Engine")
        tester().tapView(withAccessibilityLabel: "Cancel")

        // Check to see we're not in editing state
        tester().waitForView(withAccessibilityLabel: "Edit", traits: UIAccessibilityTraitButton)

        // Exit test
        SearchUtils.removeCustomSearchEngine(youTubeEngine)
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testDeletingLastCustomEngineExitsEditing() {
        navigateToSettings()
        let defaultEngine = SearchUtils.getDefaultEngine()
        let youTubeEngine = SearchUtils.youTubeSearchEngine()
        SearchUtils.addCustomSearchEngine(youTubeEngine)
        tester().tapView(withAccessibilityLabel: "Search, \(defaultEngine?.shortName)")

        // Go from edit -> editing and check for done state
        tester().tapView(withAccessibilityLabel: "Edit", traits: UIAccessibilityTraitButton)
        tester().waitForView(withAccessibilityLabel: "Done", traits: UIAccessibilityTraitButton)

        tester().tapView(withAccessibilityLabel: "Delete YouTube")
        tester().tapView(withAccessibilityLabel: "Delete")

        // Check to see we're not in editing state and disabled
        tester().waitForView(withAccessibilityLabel: "Edit", traits: UIAccessibilityTraitButton | UIAccessibilityTraitNotEnabled)

        // Exit test
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    fileprivate func navigateToSettings() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().waitForView(withAccessibilityLabel: "Settings")
    }
    */
}

