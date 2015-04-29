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
        tester().tapViewWithAccessibilityLabel("Search")
        tester().waitForViewWithAccessibilityLabel("Search")
    }

    private func navigateFromSearchSettings() {
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("about:home")
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
        var view: UIView!

        // There appears to be a KIF bug where waitForViewWithAccessibilityLabel returns the parent
        // UITableView instead of the UITableViewCell with the given label.
        // As a workaround, retry until KIF gives us a cell.
        // Open issue: https://github.com/kif-framework/KIF/issues/336
        tester().runBlock { _ in
            view = self.tester().waitForViewWithAccessibilityLabel("Default Search Engine", traits: UIAccessibilityTraitButton)
            let cell = view as? UITableViewCell
            return (cell == nil) ? KIFTestStepResult.Wait : KIFTestStepResult.Success
        }

        return view.accessibilityValue
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
