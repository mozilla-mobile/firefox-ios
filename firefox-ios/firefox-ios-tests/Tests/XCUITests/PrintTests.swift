// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class PrintTests: FeatureFlaggedTestBase {
    // https://mozilla.testrail.io/index.php?/cases/view/3082504
    func testValidatePrintOption() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "toolbar-refactor-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.nowAt(NewTabScreen)
        openUrlAndValidatePrintOptions()
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        openUrlAndValidatePrintOptions()
    }

    private func openUrlAndValidatePrintOptions() {
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        navigator.goto(PrintPage)
        waitForElementsToExist(
            [
                app.navigationBars["Options"],
                app.tables.cells.staticTexts["Printer"],
                app.tables.cells.staticTexts["Copies"],
                app.tables.cells.staticTexts["Paper Size"],
                app.tables.cells.staticTexts["Letter"],
                app.tables.cells.staticTexts["Orientation"],
                app.tables.cells.staticTexts["Portrait"],
                app.tables.cells.staticTexts["Scaling"],
                app.tables.cells.staticTexts["Layout"],
                app.collectionViews.cells["Page 1 of 1"]
            ]
        )
        navigator.goto(BrowserTab)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
    }
}
