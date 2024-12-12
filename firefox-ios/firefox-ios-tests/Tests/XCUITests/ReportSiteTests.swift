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

    // https://mozilla.testrail.io/index.php?/cases/view/2831278
    func testReportSiteIssueOn() {
        launchAndGoToMenu()
        app.images[StandardImageIdentifiers.Large.tool].tap()
        mozWaitForElementToExist(app.otherElements.images[StandardImageIdentifiers.Large.lightbulb])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2831279
    func testReportSiteIssueOff() {
        var launchArgs = app.launchArguments + ["\(LaunchArguments.LoadExperiment)reportSiteIssueOff"]
        launchArgs = launchArgs + ["\(LaunchArguments.ExperimentFeatureName)general-app-features"]
        app.launchArguments = launchArgs

        launchAndGoToMenu()
        app.images[StandardImageIdentifiers.Large.tool].tap()
        mozWaitForElementToNotExist(app.otherElements.images[StandardImageIdentifiers.Large.lightbulb])
    }

    // MARK: Helper
    func launchAndGoToMenu() {
        app.launch()

        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.images[StandardImageIdentifiers.Large.avatarCircle])
    }
}
