/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client

class SearchSettingsUITests: KIFTestCase {
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
        tester().tapViewWithAccessibilityLabel("Search, \(defaultEngine.shortName)")
        tester().waitForViewWithAccessibilityLabel("Edit", traits: UIAccessibilityTraitButton)
        SearchUtils.removeCustomSearchEngine(youTubeEngine)
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testCustomSearchEngineAsDefaultIsNotEditable() {
        navigateToSettings()
        let defaultEngine = SearchUtils.getDefaultEngine()
        let youTubeEngine = SearchUtils.youTubeSearchEngine()
        SearchUtils.addCustomSearchEngine(youTubeEngine)
        tester().tapViewWithAccessibilityLabel("Search, \(defaultEngine.shortName)")
        tester().waitForViewWithAccessibilityLabel("Edit", traits: UIAccessibilityTraitButton)

        // Change default search to custom
        tester().tapViewWithAccessibilityLabel("Default Search Engine")
        tester().tapViewWithAccessibilityLabel("YouTube")

        // Verify that edit button is not enabled
        tester().waitForViewWithAccessibilityLabel("Edit", traits: UIAccessibilityTraitButton | UIAccessibilityTraitNotEnabled)

        // Reset default search engine
        tester().tapViewWithAccessibilityLabel("Default Search Engine")
        tester().tapViewWithAccessibilityLabel("Yahoo")

        // Exit test
        SearchUtils.removeCustomSearchEngine(youTubeEngine)
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testNavigateToSearchPickerTurnsOffEditing() {
        navigateToSettings()
        let defaultEngine = SearchUtils.getDefaultEngine()
        let youTubeEngine = SearchUtils.youTubeSearchEngine()
        SearchUtils.addCustomSearchEngine(youTubeEngine)
        tester().tapViewWithAccessibilityLabel("Search, \(defaultEngine.shortName)")

        // Go from edit -> editing and check for done state
        tester().tapViewWithAccessibilityLabel("Edit", traits: UIAccessibilityTraitButton)
        tester().waitForViewWithAccessibilityLabel("Done", traits: UIAccessibilityTraitButton)

        // Navigate to the search engine picker and back
        tester().tapViewWithAccessibilityLabel("Default Search Engine")
        tester().tapViewWithAccessibilityLabel("Cancel")

        // Check to see we're not in editing state
        tester().waitForViewWithAccessibilityLabel("Edit", traits: UIAccessibilityTraitButton)

        // Exit test
        SearchUtils.removeCustomSearchEngine(youTubeEngine)
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testDeletingLastCustomEngineExitsEditing() {
        navigateToSettings()
        let defaultEngine = SearchUtils.getDefaultEngine()
        let youTubeEngine = SearchUtils.youTubeSearchEngine()
        SearchUtils.addCustomSearchEngine(youTubeEngine)
        tester().tapViewWithAccessibilityLabel("Search, \(defaultEngine.shortName)")

        // Go from edit -> editing and check for done state
        tester().tapViewWithAccessibilityLabel("Edit", traits: UIAccessibilityTraitButton)
        tester().waitForViewWithAccessibilityLabel("Done", traits: UIAccessibilityTraitButton)

        tester().tapViewWithAccessibilityLabel("Delete YouTube")
        tester().tapViewWithAccessibilityLabel("Delete")

        // Check to see we're not in editing state and disabled
        tester().waitForViewWithAccessibilityLabel("Edit", traits: UIAccessibilityTraitButton | UIAccessibilityTraitNotEnabled)

        // Exit test
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    private func navigateToSettings() {
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().waitForViewWithAccessibilityLabel("Settings")
    }
}

