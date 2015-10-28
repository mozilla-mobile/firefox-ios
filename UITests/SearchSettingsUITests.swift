/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchSettingsUITests: KIFTestCase {
    private func navigateToSearchSettings() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().waitForViewWithAccessibilityLabel("Tabs Tray")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().waitForViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Search, Yahoo")
        tester().waitForViewWithAccessibilityIdentifier("Search")
    }

    private func navigateFromSearchSettings() {
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }

    // Given that we're at the Search Settings sheet, select the named search engine as the default.
    // Afterwards, we're still at the Search Settings sheet.
    private func selectDefaultSearchEngineName(engineName: String) {
        tester().tapViewWithAccessibilityLabel("Default Search Engine", traits: UIAccessibilityTraitButton)
        tester().waitForViewWithAccessibilityLabel("Default Search Engine")
        tester().tapViewWithAccessibilityLabel(engineName)
        tester().waitForViewWithAccessibilityLabel("Search")
    }

    // Given that we're at the Search Settings sheet, return the default search engine's name.
    private func getDefaultSearchEngineName() -> String {
        let view = tester().waitForCellWithAccessibilityLabel("Default Search Engine")
        return view.accessibilityValue!
    }

    func testDefaultSearchEngine() {
        navigateToSearchSettings()
        selectDefaultSearchEngineName("Yahoo")
        XCTAssertEqual("Yahoo", getDefaultSearchEngineName())
        selectDefaultSearchEngineName("Amazon.com")
        XCTAssertEqual("Amazon.com", getDefaultSearchEngineName())
        selectDefaultSearchEngineName("Yahoo")
        XCTAssertEqual("Yahoo", getDefaultSearchEngineName())
        navigateFromSearchSettings()
    }
}
