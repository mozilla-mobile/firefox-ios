// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared

class ReportSiteTests: BaseTestCase {
    override func setUpApp() {
        setUpLaunchArguments()
    }

    func testReportSiteIssueOn() {
        launchAndGoToMenu()

        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.lightbulb])
    }

    func testReportSiteIssueOff() {
        var launchArgs = app.launchArguments + ["\(LaunchArguments.LoadExperiment)reportSiteIssueOff"]
        launchArgs = launchArgs + ["\(LaunchArguments.ExperimentFeatureName)general-app-features"]
        app.launchArguments = launchArgs

        launchAndGoToMenu()

        mozWaitForElementToNotExist(app.tables.otherElements[StandardImageIdentifiers.Large.lightbulb])
    }

    // MARK: Helper
    func launchAndGoToMenu() {
        app.launch()

        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.tables["Context Menu"])
    }
}
